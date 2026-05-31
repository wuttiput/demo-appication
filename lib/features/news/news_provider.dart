import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'package:intl/intl.dart';
import '../../core/database/database_helper.dart';
import '../../core/security/secure_storage_helper.dart';
import '../settings/keys_provider.dart';
import 'news_model.dart';

class NewsState {
  final List<NewsModel> newsList;
  final bool isUpdating;
  final String? lastUpdated;
  final String? statusMessage;

  NewsState({
    this.newsList = const [],
    this.isUpdating = false,
    this.lastUpdated,
    this.statusMessage,
  });

  NewsState copyWith({
    List<NewsModel>? newsList,
    bool? isUpdating,
    String? lastUpdated,
    String? statusMessage,
  }) {
    return NewsState(
      newsList: newsList ?? this.newsList,
      isUpdating: isUpdating ?? this.isUpdating,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class NewsNotifier extends StateNotifier<NewsState> {
  final Ref ref;
  
  NewsNotifier(this.ref) : super(NewsState()) {
    loadCachedNews();
  }

  static const Map<String, String> rssFeeds = {
    'TechCrunch': 'https://techcrunch.com/feed/',
    'Wired': 'https://www.wired.com/feed/rss',
    'The Verge': 'https://www.theverge.com/rss/index.xml',
  };

  Future<void> loadCachedNews() async {
    final cached = await DatabaseHelper.instance.queryAllNews();
    final list = cached.map((c) => NewsModel.fromMap(c)).toList();
    final lastUpdatedTime = await DatabaseHelper.instance.queryNewsMetadata('last_updated_time');
    state = state.copyWith(newsList: list, lastUpdated: lastUpdatedTime);
  }

  // Fallback Rule-Based relevance checker
  Map<String, dynamic>? _ruleBasedCheck(String title, String desc) {
    final keywords = [
      'ai', 'artificial intelligence', 'machine learning', 'tech', 'software', 
      'hardware', 'chip', 'nvidia', 'intel', 'amd', 'apple', 'google', 
      'microsoft', 'openai', 'claude', 'gemini', 'chatgpt', 'robot', 
      'semiconductor', 'quantum', 'cybersecurity', 'mobile', 'app', 'startup'
    ];
    final text = '$title $desc'.toLowerCase();
    for (var kw in keywords) {
      if (text.contains(kw)) {
        final isAi = ['ai', 'artificial intelligence', 'openai', 'claude', 'gemini', 'chatgpt', 'llm', 'neural'].any((term) => text.contains(term));
        return {
          'category': isAi ? 'AI' : 'Tech',
          'summary': desc.length > 150 ? '${desc.substring(0, 150)}...' : desc,
        };
      }
    }
    return null;
  }

  // Query Gemini for translation & summarization
  Future<Map<String, dynamic>?> _askGeminiToSummarize(String apiKey, String title, String desc) async {
    try {
      final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
      final prompt = '''
Analyze the following news item:
Title: $title
Description: $desc

Rules:
1. Is this news relevant to Artificial Intelligence (AI) or general Technology? 
   - If NO, reply with only the word "SKIP".
   - If YES:
     a) Translate and summarize the news into a single, very short Thai sentence (maximum 20 words). Keep it highly concise and simple.
     b) Categorize it as "AI" or "Tech".
     c) Format the output EXACTLY as:
        RELEVANT: Yes
        CATEGORY: [AI/Tech]
        SUMMARY: [Your short Thai summary]

Do not add any markdown formatting, thoughts, or extra characters.
''';
      
      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);
      final textResp = response.text?.trim() ?? '';
      
      if (textResp.contains('SKIP') || textResp.contains('RELEVANT: No')) {
        return null;
      }
      
      final lines = textResp.split('\n');
      String category = 'Tech';
      String summary = '';
      
      for (var line in lines) {
        if (line.startsWith('CATEGORY:')) {
          category = line.replaceAll('CATEGORY:', '').trim();
        } else if (line.startsWith('SUMMARY:')) {
          summary = line.replaceAll('SUMMARY:', '').trim();
        }
      }
      
      if (summary.isNotEmpty) {
        return {'category': category, 'summary': summary};
      }
      return null;
    } catch (e) {
      print('Gemini API Error in News Agent: $e');
      return null;
    }
  }

  // XML tag helper
  String _getValue(xml.XmlElement parent, String tagName) {
    try {
      return parent.findElements(tagName).first.innerText.trim();
    } catch (_) {
      return '';
    }
  }

  String _cleanHtml(String text) {
    final clean = RegExp(r'<.*?>');
    var cleaned = text.replaceAll(clean, '');
    cleaned = cleaned
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
    return cleaned.trim();
  }

  Future<void> updateNews() async {
    if (state.isUpdating) return;
    
    state = state.copyWith(isUpdating: true, statusMessage: 'กำลังเชื่อมต่อ RSS Feeds...');
    
    // Read Gemini Key from settings keys provider state
    final keysState = ref.read(keysProvider);
    final geminiKey = keysState.gemini;
    final hasGemini = geminiKey.isNotEmpty && !geminiKey.startsWith('your_');
    
    int newArticlesCount = 0;
    
    try {
      for (var entry in rssFeeds.entries) {
        final source = entry.key;
        final url = entry.value;
        
        state = state.copyWith(statusMessage: 'กำลังดึงข่าวจาก $source...');
        
        final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
        if (response.statusCode != 200) continue;
        
        final document = xml.XmlDocument.parse(response.body);
        
        // Supports both RSS (<item>) and Atom (<entry>)
        var items = document.findAllElements('item');
        if (items.isEmpty) {
          items = document.findAllElements('entry');
        }
        
        // Process top 2 articles per feed
        final articlesToProcess = items.take(2);
        
        for (var item in articlesToProcess) {
          final title = _getValue(item, 'title');
          var link = _getValue(item, 'link');
          if (link.isEmpty) {
            // Check href attribute if Atom format
            try {
              link = item.findElements('link').first.getAttribute('href') ?? '';
            } catch (_) {}
          }
          
          var desc = _cleanHtml(_getValue(item, 'description'));
          if (desc.isEmpty) {
            desc = _cleanHtml(_getValue(item, 'summary'));
          }
          
          var pubDate = _getValue(item, 'pubDate');
          if (pubDate.isEmpty) {
            pubDate = _getValue(item, 'published');
          }
          
          if (link.isEmpty || title.isEmpty) continue;
          
          // Verify if already in DB
          final db = await DatabaseHelper.instance.database;
          final existing = await db.query('news', where: 'url = ?', whereArgs: [link]);
          if (existing.isNotEmpty) continue;
          
          Map<String, dynamic>? result;
          if (hasGemini) {
            state = state.copyWith(statusMessage: 'กำลังแปลสรุปด้วย AI: ${title.substring(0, title.length > 30 ? 30 : title.length)}...');
            result = await _askGeminiToSummarize(geminiKey, title, desc);
            // Throttle 12 seconds to respect Gemini Free RPM limit
            await Future.delayed(const Duration(seconds: 12));
          }
          
          // Fallback to local rule based filter
          result ??= _ruleBasedCheck(title, desc);
          
          if (result != null) {
            final news = NewsModel(
              title: title,
              summary: result['summary'],
              url: link,
              publishedDate: pubDate,
              source: source,
              category: result['category'],
            );
            await DatabaseHelper.instance.insertNews(news.toMap());
            newArticlesCount++;
          }
        }
      }
      
      // Update last updated metadata
      final currentFormatted = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
      await DatabaseHelper.instance.updateNewsMetadata('last_updated_time', currentFormatted);
      
      state = state.copyWith(
        isUpdating: false,
        statusMessage: 'อัปเดตสำเร็จ! เพิ่มข่าวใหม่ $newArticlesCount รายการ',
      );
      
      // Reload cache
      await loadCachedNews();
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        statusMessage: 'เกิดข้อผิดพลาดในการอัปเดต: $e',
      );
      await loadCachedNews();
    }
  }
}

final newsProvider = StateNotifierProvider<NewsNotifier, NewsState>((ref) {
  return NewsNotifier(ref);
});

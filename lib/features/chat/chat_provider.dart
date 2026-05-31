import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import '../../core/database/database_helper.dart';
import '../settings/keys_provider.dart';
import 'chat_model.dart';

class ChatState {
  final List<ChatSessionModel> sessions;
  final List<ChatMessageModel> activeMessages;
  final String? activeSessionId;
  final String selectedModel; // 'gemini', 'deepseek', 'qwen'
  final bool isGenerating;
  final String? errorMessage;

  ChatState({
    this.sessions = const [],
    this.activeMessages = const [],
    this.activeSessionId,
    this.selectedModel = 'gemini',
    this.isGenerating = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatSessionModel>? sessions,
    List<ChatMessageModel>? activeMessages,
    String? activeSessionId,
    String? selectedModel,
    bool? isGenerating,
    String? errorMessage,
  }) {
    return ChatState(
      sessions: sessions ?? this.sessions,
      activeMessages: activeMessages ?? this.activeMessages,
      activeSessionId: activeSessionId ?? this.activeSessionId,
      selectedModel: selectedModel ?? this.selectedModel,
      isGenerating: isGenerating ?? this.isGenerating,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final Ref ref;

  ChatNotifier(this.ref) : super(ChatState()) {
    loadSessions();
  }

  Future<void> loadSessions() async {
    final rows = await DatabaseHelper.instance.queryChatSessions();
    final list = rows.map((r) => ChatSessionModel.fromMap(r)).toList();
    
    state = state.copyWith(sessions: list);
    
    // Automatically select the most recent session if none selected
    if (state.activeSessionId == null && list.isNotEmpty) {
      selectSession(list.first.id);
    }
  }

  Future<void> selectSession(String sessionId) async {
    final rows = await DatabaseHelper.instance.queryChatMessages(sessionId);
    final messages = rows.map((r) => ChatMessageModel.fromMap(r)).toList();
    state = state.copyWith(activeSessionId: sessionId, activeMessages: messages, errorMessage: null);
  }

  Future<void> createNewSession() async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    final session = ChatSessionModel(
      id: sessionId,
      title: 'บทสนทนาใหม่',
    );
    await DatabaseHelper.instance.insertChatSession(session.toMap());
    await loadSessions();
    await selectSession(sessionId);
  }

  Future<void> deleteSession(String sessionId) async {
    await DatabaseHelper.instance.deleteChatSession(sessionId);
    if (state.activeSessionId == sessionId) {
      state = state.copyWith(activeSessionId: null, activeMessages: const []);
    }
    await loadSessions();
  }

  Future<void> selectModel(String model) async {
    state = state.copyWith(selectedModel: model);
  }

  // AI API Direct Integration
  Future<String> _callGemini(String apiKey, String userMessage, List<ChatMessageModel> history) async {
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: apiKey);
    
    // Convert history format
    final contents = <Content>[];
    for (var msg in history) {
      final role = msg.sender == 'user' ? 'user' : 'model';
      contents.add(Content(role, [TextPart(msg.message)]));
    }
    contents.add(Content('user', [TextPart(userMessage)]));

    final response = await model.generateContent(contents);
    return response.text?.trim() ?? 'ไม่มีการตอบสนองจาก Gemini';
  }

  Future<String> _callDeepseekOfficial(String apiKey, String userMessage, List<ChatMessageModel> history) async {
    final url = Uri.parse('https://api.deepseek.com/chat/completions');
    
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': 'You are a helpful and intelligent personal assistant. Answer the user clearly and friendly in the language they use (defaulting to Thai).'
      }
    ];

    for (var msg in history) {
      messages.add({
        'role': msg.sender == 'user' ? 'user' : 'assistant',
        'content': msg.message,
      });
    }
    messages.add({'role': 'user', 'content': userMessage});

    final payload = {
      'model': 'deepseek-chat',
      'messages': messages,
      'temperature': 0.7,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'].toString().trim();
    } else {
      return 'DeepSeek API Error (Status ${response.statusCode}): ${response.body}';
    }
  }

  Future<String> _callOpenRouter(String apiKey, String modelId, String userMessage, List<ChatMessageModel> history) async {
    final url = Uri.parse('https://openrouter.ai/api/v1/chat/completions');
    
    final modelName = modelId == 'qwen'
        ? 'qwen/qwen3-next-80b-a3b-instruct:free'
        : 'deepseek/deepseek-v4-flash:free';

    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': 'You are a helpful and intelligent personal assistant. Answer the user clearly and friendly in the language they use (defaulting to Thai).'
      }
    ];

    for (var msg in history) {
      messages.add({
        'role': msg.sender == 'user' ? 'user' : 'assistant',
        'content': msg.message,
      });
    }
    messages.add({'role': 'user', 'content': userMessage});

    final payload = {
      'model': modelName,
      'messages': messages,
    };

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'http://localhost',
        'X-Title': 'Personal Hub App',
      },
      body: jsonEncode(payload),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return body['choices'][0]['message']['content'].toString().trim();
    } else {
      return 'OpenRouter API Error (Status ${response.statusCode}): ${response.body}';
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    if (state.activeSessionId == null) {
      await createNewSession();
    }

    final sessionId = state.activeSessionId!;
    final userMessageText = text.trim();

    // 1. Insert User Message
    final userMsg = ChatMessageModel(
      sessionId: sessionId,
      sender: 'user',
      message: userMessageText,
    );
    await DatabaseHelper.instance.insertChatMessage(userMsg.toMap());
    
    // Save state copy with user message added
    final updatedMessages = List<ChatMessageModel>.from(state.activeMessages)..add(userMsg);
    state = state.copyWith(activeMessages: updatedMessages, isGenerating: true, errorMessage: null);

    // 2. Dynamic Session Title Rename if it's the first message
    final currentSession = state.sessions.firstWhere((s) => s.id == sessionId);
    if (currentSession.title == 'บทสนทนาใหม่') {
      final newTitle = userMessageText.length > 20 ? '${userMessageText.substring(0, 20)}...' : userMessageText;
      await DatabaseHelper.instance.updateChatSessionTitle(sessionId, newTitle);
      await loadSessions();
    }

    // 3. AI Service Fetch
    final keysState = ref.read(keysProvider);
    String aiResponse = '';
    
    try {
      if (state.selectedModel == 'gemini') {
        final key = keysState.gemini;
        if (key.isEmpty || key.startsWith('your_')) {
          throw 'กรุณากรอกคีย์ Google Gemini API ที่หน้าตั้งค่าก่อนใช้งาน';
        }
        // Send history up to last 10 messages to keep context sized appropriately
        final historyContext = state.activeMessages.take(state.activeMessages.length).toList();
        aiResponse = await _callGemini(key, userMessageText, historyContext);
      } 
      else if (state.selectedModel == 'deepseek') {
        final directKey = keysState.deepseek;
        final routerKey = keysState.openrouter;
        
        if (directKey.isNotEmpty && !directKey.startsWith('your_')) {
          aiResponse = await _callDeepseekOfficial(directKey, userMessageText, state.activeMessages);
        } else if (routerKey.isNotEmpty && !routerKey.startsWith('your_')) {
          aiResponse = await _callOpenRouter(routerKey, 'deepseek', userMessageText, state.activeMessages);
        } else {
          throw 'กรุณากรอกคีย์ DeepSeek Official หรือคีย์ OpenRouter ที่หน้าตั้งค่าก่อนใช้งาน';
        }
      } 
      else if (state.selectedModel == 'qwen') {
        final routerKey = keysState.openrouter;
        if (routerKey.isEmpty || routerKey.startsWith('your_')) {
          throw 'กรุณากรอกคีย์ OpenRouter API (สำหรับ Qwen รุ่นฟรี) ที่หน้าตั้งค่าก่อนใช้งาน';
        }
        aiResponse = await _callOpenRouter(routerKey, 'qwen', userMessageText, state.activeMessages);
      }
      
      // 4. Insert Assistant Response
      final assistantMsg = ChatMessageModel(
        sessionId: sessionId,
        sender: 'assistant',
        modelUsed: state.selectedModel,
        message: aiResponse,
      );
      await DatabaseHelper.instance.insertChatMessage(assistantMsg.toMap());
      
      // Reload final state
      await selectSession(sessionId);
    } catch (e) {
      state = state.copyWith(
        isGenerating: false,
        errorMessage: 'เกิดข้อผิดพลาด: $e',
      );
    } finally {
      state = state.copyWith(isGenerating: false);
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  return ChatNotifier(ref);
});

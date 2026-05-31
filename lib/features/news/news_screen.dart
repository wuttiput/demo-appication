import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import 'news_provider.dart';

class NewsScreen extends ConsumerWidget {
  const NewsScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ไม่สามารถเปิดลิงก์ข่าวได้: $e'),
            backgroundColor: AppTheme.rose400,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsState = ref.watch(newsProvider);
    final newsNotifier = ref.read(newsProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.indigo600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.indigo500.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.newspaper, color: AppTheme.indigo500, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ข่าวสาร AI & Tech',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.slate100),
                          ),
                          Text(
                            newsState.lastUpdated != null
                                ? 'อัปเดตล่าสุด: ${newsState.lastUpdated}'
                                : 'ยังไม่ได้อัปเดตข้อมูล',
                            style: const TextStyle(fontSize: 11, color: AppTheme.slate400),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Sync Button
                  IconButton(
                    onPressed: newsState.isUpdating ? null : () => newsNotifier.updateNews(),
                    icon: newsState.isUpdating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.indigo500),
                          )
                        : const Icon(Icons.sync, color: AppTheme.indigo500),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Status Message (Banner)
              if (newsState.statusMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.slate900.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: newsState.statusMessage!.contains('ข้อผิดพลาด')
                          ? AppTheme.rose400.withOpacity(0.3)
                          : AppTheme.indigo500.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        newsState.statusMessage!.contains('ข้อผิดพลาด')
                            ? Icons.error_outline
                            : Icons.info_outline,
                        color: newsState.statusMessage!.contains('ข้อผิดพลาด')
                            ? AppTheme.rose400
                            : AppTheme.indigo500,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          newsState.statusMessage!,
                          style: TextStyle(
                            fontSize: 11,
                            color: newsState.statusMessage!.contains('ข้อผิดพลาด')
                                ? AppTheme.rose400
                                : AppTheme.slate300,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Feed list
              Expanded(
                child: newsState.newsList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.feed_outlined, color: AppTheme.slate700, size: 54),
                            const SizedBox(height: 12),
                            const Text(
                              'ยังไม่มีบทความข่าวสารระบบ',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'กดปุ่มซิงค์มุมขวาบนเพื่อดาวน์โหลดและแปลข่าวสารล่าสุด',
                              style: TextStyle(fontSize: 11, color: AppTheme.slate700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: newsState.isUpdating ? null : () => newsNotifier.updateNews(),
                              icon: const Icon(Icons.sync, size: 16),
                              label: const Text('ดึงข้อมูลข่าวสาร'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.indigo600,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => newsNotifier.updateNews(),
                        color: AppTheme.indigo500,
                        backgroundColor: AppTheme.slate900,
                        child: ListView.builder(
                          itemCount: newsState.newsList.length,
                          itemBuilder: (context, index) {
                            final article = newsState.newsList[index];
                            final isAi = article.category == 'AI';
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 14),
                              child: InkWell(
                                onTap: () => _launchUrl(context, article.url),
                                borderRadius: BorderRadius.circular(16),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Meta (Source & Category Badges)
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          // Source
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppTheme.slate950,
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(color: AppTheme.slate800),
                                            ),
                                            child: Text(
                                              article.source ?? 'ไม่ระบุแหล่งข่าว',
                                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.slate400),
                                            ),
                                          ),
                                          
                                          // Category
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isAi
                                                  ? AppTheme.indigo600.withOpacity(0.15)
                                                  : AppTheme.purple600.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isAi
                                                    ? AppTheme.indigo500.withOpacity(0.3)
                                                    : AppTheme.purple600.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              article.category ?? 'ทั่วไป',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                                color: isAi ? AppTheme.indigo500 : AppTheme.purple600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Summary in Thai
                                      Text(
                                        article.summary,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.slate100,
                                          height: 1.5,
                                        ),
                                      ),
                                      const SizedBox(height: 8),

                                      // Original Title (English)
                                      Text(
                                        article.title,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.slate400,
                                          height: 1.4,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      
                                      // Divider
                                      const Divider(height: 1),
                                      const SizedBox(height: 10),

                                      // Footer "Read More" trigger
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            article.publishedDate ?? '',
                                            style: const TextStyle(fontSize: 9, color: AppTheme.slate700),
                                          ),
                                          Row(
                                            children: const [
                                              Text(
                                                'อ่านบทความฉบับเต็ม',
                                                style: TextStyle(fontSize: 10, color: AppTheme.indigo500, fontWeight: FontWeight.bold),
                                              ),
                                              SizedBox(width: 4),
                                              Icon(Icons.open_in_new, color: AppTheme.indigo500, size: 11),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

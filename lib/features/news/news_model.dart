class NewsModel {
  final int? id;
  final String title;
  final String summary; // Short Thai summary/translation
  final String url;
  final String? publishedDate;
  final String? source;
  final String? category; // 'AI' or 'Tech'

  NewsModel({
    this.id,
    required this.title,
    required this.summary,
    required this.url,
    this.publishedDate,
    this.source,
    this.category,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'summary': summary,
      'url': url,
      'published_date': publishedDate,
      'source': source,
      'category': category,
    };
  }

  factory NewsModel.fromMap(Map<String, dynamic> map) {
    return NewsModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      summary: map['summary'] as String,
      url: map['url'] as String,
      publishedDate: map['published_date'] as String?,
      source: map['source'] as String?,
      category: map['category'] as String?,
    );
  }
}

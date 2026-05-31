class TodoModel {
  final int? id;
  final int userId;
  final String title;
  final int isDone; // 0 = active, 1 = completed
  final String date; // YYYY-MM-DD

  TodoModel({
    this.id,
    this.userId = 1,
    required this.title,
    this.isDone = 0,
    required this.date,
  });

  bool get completed => isDone == 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'is_done': isDone,
      'date': date,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      isDone: map['is_done'] as int,
      date: map['date'] as String,
    );
  }
}

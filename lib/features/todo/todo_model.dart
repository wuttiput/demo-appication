class TodoModel {
  final int? id;
  final int userId;
  final String title;
  final int isDone; // 0 = active, 1 = completed
  final String date; // YYYY-MM-DD
  final int orderIndex;

  TodoModel({
    this.id,
    this.userId = 1,
    required this.title,
    this.isDone = 0,
    required this.date,
    this.orderIndex = 0,
  });

  bool get completed => isDone == 1;

  TodoModel copyWith({
    int? id,
    int? userId,
    String? title,
    int? isDone,
    String? date,
    int? orderIndex,
  }) {
    return TodoModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      date: date ?? this.date,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'is_done': isDone,
      'date': date,
      'order_index': orderIndex,
    };
  }

  factory TodoModel.fromMap(Map<String, dynamic> map) {
    return TodoModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      isDone: map['is_done'] as int,
      date: map['date'] as String,
      orderIndex: (map['order_index'] as int?) ?? 0,
    );
  }
}

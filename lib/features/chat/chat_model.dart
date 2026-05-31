class ChatSessionModel {
  final String id;
  final int userId;
  final String title;
  final String? createdAt;

  ChatSessionModel({
    required this.id,
    this.userId = 1,
    required this.title,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'created_at': createdAt,
    };
  }

  factory ChatSessionModel.fromMap(Map<String, dynamic> map) {
    return ChatSessionModel(
      id: map['id'] as String,
      userId: map['user_id'] as int,
      title: map['title'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}

class ChatMessageModel {
  final int? id;
  final String sessionId;
  final String sender; // 'user' or 'assistant'
  final String? modelUsed;
  final String message;
  final String? createdAt;

  ChatMessageModel({
    this.id,
    required this.sessionId,
    required this.sender,
    this.modelUsed,
    required this.message,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'sender': sender,
      'model_used': modelUsed,
      'message': message,
      'created_at': createdAt,
    };
  }

  factory ChatMessageModel.fromMap(Map<String, dynamic> map) {
    return ChatMessageModel(
      id: map['id'] as int?,
      sessionId: map['session_id'] as String,
      sender: map['sender'] as String,
      modelUsed: map['model_used'] as String?,
      message: map['message'] as String,
      createdAt: map['created_at'] as String?,
    );
  }
}

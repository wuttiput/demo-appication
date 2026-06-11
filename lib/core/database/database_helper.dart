import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('finance.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
      onConfigure: _onConfigure,
    );
  }

  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      try {
        await db.execute('ALTER TABLE todos ADD COLUMN order_index INTEGER NOT NULL DEFAULT 0');
      } catch (e) {
        print("Database migration error: $e");
      }
    }
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullable = 'TEXT';
    const realType = 'REAL NOT NULL';

    // 1. Users Table (To support user references, we default to user_id = 1)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');

    // Insert a default user so user_id = 1 is valid
    await db.execute('''
      INSERT INTO users (id, username, password_hash)
      VALUES (1, 'me', 'hashing_not_needed_for_local_only')
    ''');

    // 2. Transactions Table
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        user_id INTEGER NOT NULL,
        type TEXT NOT NULL CHECK(type IN ('income', 'expense')),
        amount $realType,
        description $textNullable,
        date TEXT NOT NULL DEFAULT (date('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 3. Todos Table
    await db.execute('''
      CREATE TABLE todos (
        id $idType,
        user_id INTEGER NOT NULL,
        title $textType,
        is_done INTEGER NOT NULL DEFAULT 0,
        date TEXT NOT NULL DEFAULT (date('now')),
        order_index INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 4. News Table (Cache)
    await db.execute('''
      CREATE TABLE news (
        id $idType,
        title $textType,
        summary $textType,
        url TEXT UNIQUE NOT NULL,
        published_date $textNullable,
        source $textNullable,
        category $textNullable,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // 5. News Metadata Table
    await db.execute('''
      CREATE TABLE news_metadata (
        key TEXT PRIMARY KEY,
        value $textNullable
      )
    ''');

    // 6. Chat Sessions Table
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL DEFAULT 'บทสนทนาใหม่',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    ''');

    // 7. Chat Messages Table
    await db.execute('''
      CREATE TABLE chat_messages (
        id $idType,
        session_id TEXT NOT NULL,
        sender TEXT NOT NULL CHECK(sender IN ('user', 'assistant')),
        model_used $textNullable,
        message $textType,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      )
    ''');
  }

  // --- Core CRUD operations ---

  // Finance Transactions
  Future<int> insertTransaction(Map<String, dynamic> row) async {
    final db = await instance.database;
    final Map<String, dynamic> data = Map.of(row);
    data['user_id'] = 1; // Default personal user
    return await db.insert('transactions', data);
  }

  Future<List<Map<String, dynamic>>> queryTransactionsByDate(String date) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'id DESC',
    );
  }

  Future<List<Map<String, dynamic>>> queryTransactionsByMonth(String yyyyMm) async {
    final db = await instance.database;
    return await db.query(
      'transactions',
      where: 'date LIKE ?',
      whereArgs: ['$yyyyMm%'],
      orderBy: 'date DESC, id DESC',
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await instance.database;
    return await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Todos
  Future<int> insertTodo(Map<String, dynamic> row) async {
    final db = await instance.database;
    final Map<String, dynamic> data = Map.of(row);
    data['user_id'] = 1; // Default personal user
    return await db.insert('todos', data);
  }

  Future<List<Map<String, dynamic>>> queryTodosByDate(String date) async {
    final db = await instance.database;
    return await db.query(
      'todos',
      where: 'date = ?',
      whereArgs: [date],
      orderBy: 'order_index ASC, id DESC',
    );
  }

  Future<int> updateTodoStatus(int id, int isDone) async {
    final db = await instance.database;
    return await db.update(
      'todos',
      {'is_done': isDone},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateTodoOrder(int id, int orderIndex) async {
    final db = await instance.database;
    return await db.update(
      'todos',
      {'order_index': orderIndex},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteTodo(int id) async {
    final db = await instance.database;
    return await db.delete(
      'todos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getFlameScore() async {
    final val = await queryNewsMetadata('todo_flame_score');
    if (val == null) return 0;
    return int.tryParse(val) ?? 0;
  }

  Future<void> updateFlameScore(int score) async {
    await updateNewsMetadata('todo_flame_score', score.toString());
  }

  // News (Cache)
  Future<int> insertNews(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(
      'news',
      row,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> queryAllNews() async {
    final db = await instance.database;
    return await db.query('news', orderBy: 'id DESC');
  }

  Future<String?> queryNewsMetadata(String key) async {
    final db = await instance.database;
    final results = await db.query(
      'news_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  Future<void> updateNewsMetadata(String key, String value) async {
    final db = await instance.database;
    await db.insert(
      'news_metadata',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Chat Sessions
  Future<int> insertChatSession(Map<String, dynamic> row) async {
    final db = await instance.database;
    final Map<String, dynamic> data = Map.of(row);
    data['user_id'] = 1;
    return await db.insert('chat_sessions', data, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, dynamic>>> queryChatSessions() async {
    final db = await instance.database;
    return await db.query('chat_sessions', orderBy: 'created_at DESC');
  }

  Future<int> updateChatSessionTitle(String id, String title) async {
    final db = await instance.database;
    return await db.update(
      'chat_sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChatSession(String id) async {
    final db = await instance.database;
    return await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Chat Messages
  Future<int> insertChatMessage(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('chat_messages', row);
  }

  Future<List<Map<String, dynamic>>> queryChatMessages(String sessionId) async {
    final db = await instance.database;
    return await db.query(
      'chat_messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'id ASC',
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}

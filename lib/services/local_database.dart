import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// Local SQLite database for CCWS Vision.
///
/// Schema (relational):
///   users           — one row per ITS user seen on this device
///   check_ins       — log of every presence toggle (FK → users)
///   local_comments  — local copy of comments (FK → users)
///
/// Relationships:
///   users (1) ──< check_ins   (many)   via users.id = check_ins.user_id
///   users (1) ──< local_comments (many) via users.id = local_comments.user_id
///
/// This gives a full relational CRUD layer that complements Firestore
/// (Firestore = real-time sync; SQLite = local history & offline access).

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._();
  factory LocalDatabase() => _instance;
  LocalDatabase._();

  static Database? _db;

  Future<Database> get database async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ccws_vision.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        // Enable foreign key enforcement
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // ── Table: users ──────────────────────────────────────────────────────
    await db.execute('''
      CREATE TABLE users (
        id          TEXT PRIMARY KEY,
        email       TEXT NOT NULL UNIQUE,
        display_name TEXT NOT NULL,
        photo_url   TEXT,
        created_at  INTEGER NOT NULL
      )
    ''');

    // ── Table: check_ins ─────────────────────────────────────────────────
    // Records every time a user toggles their presence.
    await db.execute('''
      CREATE TABLE check_ins (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id     TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        status      TEXT NOT NULL CHECK(status IN ('inCCWS', 'notInCCWS')),
        checked_at  INTEGER NOT NULL
      )
    ''');

    // ── Table: local_comments ─────────────────────────────────────────────
    // Local mirror of Firestore comments (synced on load).
    await db.execute('''
      CREATE TABLE local_comments (
        firestore_id  TEXT PRIMARY KEY,
        user_id       TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        text          TEXT NOT NULL,
        presence_at_post TEXT,
        created_at    INTEGER NOT NULL,
        updated_at    INTEGER,
        synced        INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // ── Indexes ───────────────────────────────────────────────────────────
    await db.execute(
        'CREATE INDEX idx_checkins_user ON check_ins(user_id)');
    await db.execute(
        'CREATE INDEX idx_checkins_time ON check_ins(checked_at DESC)');
    await db.execute(
        'CREATE INDEX idx_comments_user ON local_comments(user_id)');
    await db.execute(
        'CREATE INDEX idx_comments_time ON local_comments(created_at DESC)');
  }

  // ══════════════════════════════════════════════════════════════════════════
  // USERS
  // ══════════════════════════════════════════════════════════════════════════

  /// Insert or update a user record.
/// Insert or update a user record safely without triggering ON DELETE CASCADE
  Future<void> upsertUser({
    required String id,
    required String email,
    required String displayName,
    required String photoUrl,
  }) async {
    final db = await database;
    
    // Check if user exists first to avoid the REPLACE cascade wipe
    final existingUser = await getUserById(id);
    
    final userData = {
      'id': id,
      'email': email,
      'display_name': displayName,
      'photo_url': photoUrl,
      'created_at': DateTime.now().millisecondsSinceEpoch,
    };

    if (existingUser == null) {
      // User doesn't exist, safe to insert
      await db.insert('users', userData);
    } else {
      // User exists, just update their info so we don't delete their comments!
      // (We remove 'id' and 'created_at' from the update map to preserve the originals)
      userData.remove('id');
      userData.remove('created_at');
      await db.update(
        'users', 
        userData, 
        where: 'id = ?', 
        whereArgs: [id]
      );
    }
  }

  /// Fetch all users. (Read)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    return db.query('users', orderBy: 'display_name ASC');
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    final db = await database;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : rows.first;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // CHECK-INS  (Create / Read)
  // ══════════════════════════════════════════════════════════════════════════

  /// Log a check-in event. (Create)
  Future<int> logCheckIn({
    required String userId,
    required String status, // 'inCCWS' | 'notInCCWS'
  }) async {
    final db = await database;
    return db.insert('check_ins', {
      'user_id': userId,
      'status': status,
      'checked_at': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Get full check-in history for a user, joined with user data. (Read)
  Future<List<Map<String, dynamic>>> getCheckInHistory(String userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        ci.id,
        ci.status,
        ci.checked_at,
        u.display_name,
        u.email,
        u.photo_url
      FROM check_ins ci
      INNER JOIN users u ON u.id = ci.user_id
      WHERE ci.user_id = ?
      ORDER BY ci.checked_at DESC
    ''', [userId]);
  }

  /// Get recent check-ins across all users (relational join). (Read)
  Future<List<Map<String, dynamic>>> getRecentCheckIns({int limit = 50}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        ci.id,
        ci.status,
        ci.checked_at,
        u.id       AS user_id,
        u.display_name,
        u.email,
        u.photo_url
      FROM check_ins ci
      INNER JOIN users u ON u.id = ci.user_id
      ORDER BY ci.checked_at DESC
      LIMIT ?
    ''', [limit]);
  }

  /// Count how many times user was in CCWS (aggregation on relation). (Read)
  Future<int> countCheckIns(String userId, String status) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT COUNT(*) as cnt
      FROM check_ins
      WHERE user_id = ? AND status = ?
    ''', [userId, status]);
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  // LOCAL COMMENTS  (CRUD)
  // ══════════════════════════════════════════════════════════════════════════

  /// Insert a comment locally. (Create)
  Future<void> insertComment({
    required String firestoreId,
    required String userId,
    required String text,
    String? presenceAtPost,
    required DateTime createdAt,
  }) async {
    final db = await database;
    await db.insert(
      'local_comments',
      {
        'firestore_id': firestoreId,
        'user_id': userId,
        'text': text,
        'presence_at_post': presenceAtPost,
        'created_at': createdAt.millisecondsSinceEpoch,
        'synced': 1,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all comments joined with user data. (Read — relational join)
  Future<List<Map<String, dynamic>>> getCommentsWithUsers() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        lc.firestore_id,
        lc.text,
        lc.presence_at_post,
        lc.created_at,
        lc.updated_at,
        lc.synced,
        u.id         AS user_id,
        u.display_name,
        u.email,
        u.photo_url
      FROM local_comments lc
      INNER JOIN users u ON u.id = lc.user_id
      ORDER BY lc.created_at DESC
    ''');
  }

  /// Get comments by a specific user (filtered join). (Read)
  Future<List<Map<String, dynamic>>> getCommentsByUser(String userId) async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        lc.firestore_id,
        lc.text,
        lc.presence_at_post,
        lc.created_at,
        lc.updated_at,
        u.display_name,
        u.email
      FROM local_comments lc
      INNER JOIN users u ON u.id = lc.user_id
      WHERE lc.user_id = ?
      ORDER BY lc.created_at DESC
    ''', [userId]);
  }

  /// Update a comment's text. (Update)
  Future<void> updateComment(String firestoreId, String newText) async {
    final db = await database;
    await db.update(
      'local_comments',
      {
        'text': newText,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
        'synced': 0, // mark dirty until Firestore confirms
      },
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
    );
  }

  /// Mark a local comment as synced after Firestore update. (Update)
  Future<void> markCommentSynced(String firestoreId) async {
    final db = await database;
    await db.update(
      'local_comments',
      {'synced': 1},
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
    );
  }

  /// Delete a comment. (Delete)
  Future<void> deleteComment(String firestoreId) async {
    final db = await database;
    await db.delete(
      'local_comments',
      where: 'firestore_id = ?',
      whereArgs: [firestoreId],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // STATS  (aggregation queries across relations)
  // ══════════════════════════════════════════════════════════════════════════

  /// Returns per-user visit counts (join + group by).
  Future<List<Map<String, dynamic>>> getVisitLeaderboard() async {
    final db = await database;
    return db.rawQuery('''
      SELECT
        u.display_name,
        u.photo_url,
        COUNT(CASE WHEN ci.status = 'inCCWS' THEN 1 END) AS visit_count,
        MAX(ci.checked_at) AS last_seen
      FROM users u
      LEFT JOIN check_ins ci ON ci.user_id = u.id
      GROUP BY u.id
      ORDER BY visit_count DESC
    ''');
  }

  /// Close the database.
  Future<void> close() async {
    final db = _db;
    if (db != null) {
      await db.close();
      _db = null;
    }
  }
}

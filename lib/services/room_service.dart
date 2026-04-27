import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'local_database.dart';
import 'notification_service.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LocalDatabase _local = LocalDatabase();
  final NotificationService _notif = NotificationService();

  CollectionReference get _presence => _db.collection('presence');
  CollectionReference get _comments => _db.collection('comments');

  // ─── PRESENCE ────────────────────────────────────────────────────────────

  Future<void> setPresence({
    required String userId,
    required String userEmail,
    required String userDisplayName,
    required String userPhotoUrl,
    required CheckInStatus status,
  }) async {
    // 1. Ensure user exists in local SQLite users table
    await _local.upsertUser(
      id: userId,
      email: userEmail,
      displayName: userDisplayName,
      photoUrl: userPhotoUrl,
    );

    // 2. Log check-in event to local SQLite check_ins table (relational)
    await _local.logCheckIn(userId: userId, status: status.name);

    // 3. Check previous status for notification trigger
    final prev = await getMyPresence(userId);

    // 4. Upsert Firestore presence doc
    await _presence.doc(userId).set(
      UserPresence(
        userId: userId,
        userEmail: userEmail,
        userDisplayName: userDisplayName,
        userPhotoUrl: userPhotoUrl,
        status: status,
        updatedAt: DateTime.now(),
      ).toFirestore(),
      SetOptions(merge: true),
    );

    // 5. Notify on first check-in
    if (prev?.status == CheckInStatus.notInCCWS &&
        status == CheckInStatus.inCCWS) {
      final count = await getPresentCount();
      if (count == 1) {
        await _notif.showRoomActiveNotification(userDisplayName);
      }
    }
  }

  Stream<UserPresence?> myPresenceStream(String userId) {
    return _presence.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserPresence.fromFirestore(doc);
    });
  }

  Future<UserPresence?> getMyPresence(String userId) async {
    final doc = await _presence.doc(userId).get();
    if (!doc.exists) return null;
    return UserPresence.fromFirestore(doc);
  }

  Stream<List<UserPresence>> presentUsersStream() {
    return _presence
        .where('status', isEqualTo: 'inCCWS')
        .snapshots()
        .map((s) => s.docs.map(UserPresence.fromFirestore).toList());
  }

  Future<int> getPresentCount() async {
    final snap =
        await _presence.where('status', isEqualTo: 'inCCWS').count().get();
    return snap.count ?? 0;
  }

  // ─── COMMENTS ────────────────────────────────────────────────────────────

  Stream<List<RoomComment>> commentsStream() {
    return _comments
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(RoomComment.fromFirestore).toList());
  }

  Future<void> addComment({
    required String userId,
    required String userEmail,
    required String userDisplayName,
    required String userPhotoUrl,
    required String text,
    CheckInStatus? presenceAtPost,
  }) async {
    // 1. Ensure user in SQLite
    await _local.upsertUser(
      id: userId,
      email: userEmail,
      displayName: userDisplayName,
      photoUrl: userPhotoUrl,
    );

    // 2. Write to Firestore
    final doc = _comments.doc();
    final now = DateTime.now();
    await doc.set(
      RoomComment(
        id: doc.id,
        userId: userId,
        userEmail: userEmail,
        userDisplayName: userDisplayName,
        userPhotoUrl: userPhotoUrl,
        text: text,
        presenceAtPost: presenceAtPost,
        createdAt: now,
      ).toFirestore(),
    );

    // 3. Mirror to local SQLite local_comments (relational, FK → users)
    await _local.insertComment(
      firestoreId: doc.id,
      userId: userId,
      text: text,
      presenceAtPost: presenceAtPost?.name,
      createdAt: now,
    );
  }

  Future<void> updateComment(String commentId, String newText) async {
    // 1. Update Firestore
    await _comments.doc(commentId).update({
      'text': newText,
      'updatedAt': Timestamp.now(),
    });

    // 2. Update local SQLite (marks as dirty, then re-synced)
    await _local.updateComment(commentId, newText);
    await _local.markCommentSynced(commentId);
  }

  Future<void> deleteComment(String commentId) async {
    // 1. Delete from Firestore
    await _comments.doc(commentId).delete();

    // 2. Delete from local SQLite
    await _local.deleteComment(commentId);
  }

  // ─── LOCAL STATS (SQLite only) ───────────────────────────────────────────

  /// Check-in history for the current user from local DB.
  Future<List<Map<String, dynamic>>> getLocalCheckInHistory(
      String userId) async {
    return _local.getCheckInHistory(userId);
  }

  /// Leaderboard based on local check-in logs (relational aggregation).
  Future<List<Map<String, dynamic>>> getVisitLeaderboard() async {
    return _local.getVisitLeaderboard();
  }

  /// All local comments joined with user data.
  Future<List<Map<String, dynamic>>> getLocalComments() async {
    return _local.getCommentsWithUsers();
  }

  /// Recent global check-ins from local SQLite.
  Future<List<Map<String, dynamic>>> getRecentCheckIns() async {
    return _local.getRecentCheckIns();
  }
}

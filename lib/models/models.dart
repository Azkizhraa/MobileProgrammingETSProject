import 'package:cloud_firestore/cloud_firestore.dart';

// ─── Check-in status ───────────────────────────────────────────────────────

enum CheckInStatus { inCCWS, notInCCWS }

extension CheckInStatusExt on CheckInStatus {
  String get label =>
      this == CheckInStatus.inCCWS ? 'In CCWS IUP' : 'Not in CCWS IUP';

  String get emoji =>
      this == CheckInStatus.inCCWS ? '✅' : '🚪';

  static CheckInStatus fromString(String v) =>
      v == 'inCCWS' ? CheckInStatus.inCCWS : CheckInStatus.notInCCWS;
}

// ─── User presence record (one per user, upserted) ─────────────────────────

class UserPresence {
  final String userId;
  final String userEmail;
  final String userDisplayName;
  final String userPhotoUrl;
  final CheckInStatus status;
  final DateTime updatedAt;

  UserPresence({
    required this.userId,
    required this.userEmail,
    required this.userDisplayName,
    required this.userPhotoUrl,
    required this.status,
    required this.updatedAt,
  });

  factory UserPresence.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return UserPresence(
      userId: doc.id,
      userEmail: d['userEmail'] ?? '',
      userDisplayName: d['userDisplayName'] ?? 'Unknown',
      userPhotoUrl: d['userPhotoUrl'] ?? '',
      status: CheckInStatusExt.fromString(d['status'] ?? 'notInCCWS'),
      updatedAt: (d['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userEmail': userEmail,
        'userDisplayName': userDisplayName,
        'userPhotoUrl': userPhotoUrl,
        'status': status.name,
        'updatedAt': Timestamp.fromDate(updatedAt),
      };
}

// ─── Comment ────────────────────────────────────────────────────────────────

class RoomComment {
  final String id;
  final String userId;
  final String userEmail;
  final String userDisplayName;
  final String userPhotoUrl;
  final String text;
  final CheckInStatus? presenceAtPost; // user's check-in status when they posted
  final DateTime createdAt;
  final DateTime? updatedAt;

  RoomComment({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userDisplayName,
    required this.userPhotoUrl,
    required this.text,
    this.presenceAtPost,
    required this.createdAt,
    this.updatedAt,
  });

  factory RoomComment.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return RoomComment(
      id: doc.id,
      userId: d['userId'] ?? '',
      userEmail: d['userEmail'] ?? '',
      userDisplayName: d['userDisplayName'] ?? 'Unknown',
      userPhotoUrl: d['userPhotoUrl'] ?? '',
      text: d['text'] ?? '',
      presenceAtPost: d['presenceAtPost'] != null
          ? CheckInStatusExt.fromString(d['presenceAtPost'])
          : null,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userEmail': userEmail,
        'userDisplayName': userDisplayName,
        'userPhotoUrl': userPhotoUrl,
        'text': text,
        'presenceAtPost': presenceAtPost?.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };

  RoomComment copyWith({String? text, DateTime? updatedAt}) => RoomComment(
        id: id,
        userId: userId,
        userEmail: userEmail,
        userDisplayName: userDisplayName,
        userPhotoUrl: userPhotoUrl,
        text: text ?? this.text,
        presenceAtPost: presenceAtPost,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

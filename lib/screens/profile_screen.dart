import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../models/models.dart';
import '../utils/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final room = RoomService();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            CircleAvatar(
              radius: 44,
              backgroundImage: auth.userPhotoUrl.isNotEmpty
                  ? NetworkImage(auth.userPhotoUrl)
                  : null,
              backgroundColor: T.primary.withOpacity(0.15),
              child: auth.userPhotoUrl.isEmpty
                  ? Text(
                      auth.userDisplayName.isNotEmpty
                          ? auth.userDisplayName[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                          fontSize: 30,
                          color: T.primary,
                          fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(auth.userDisplayName,
                style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: T.ink)),
            const SizedBox(height: 4),
            Text(auth.userEmail,
                style: GoogleFonts.dmSans(fontSize: 13, color: T.muted)),
            const SizedBox(height: 16),

            // Current presence status
            StreamBuilder<UserPresence?>(
              stream: room.myPresenceStream(auth.userId),
              builder: (_, snap) {
                final isIn = snap.data?.status == CheckInStatus.inCCWS;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: (isIn ? T.inCCWS : T.muted).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: (isIn ? T.inCCWS : T.muted).withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isIn
                            ? Icons.where_to_vote_rounded
                            : Icons.exit_to_app_rounded,
                        size: 16,
                        color: isIn ? T.inCCWS : T.muted,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isIn
                            ? 'Currently in CCWS IUP'
                            : 'Not currently in CCWS',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: isIn ? T.inCCWS : T.muted,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout_rounded, color: Colors.red, size: 18),
                label: Text('Sign Out',
                    style: GoogleFonts.dmSans(
                        color: Colors.red, fontWeight: FontWeight.w600)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  // Mark as not in CCWS on sign out
                  await room.setPresence(
                    userId: auth.userId,
                    userEmail: auth.userEmail,
                    userDisplayName: auth.userDisplayName,
                    userPhotoUrl: auth.userPhotoUrl,
                    status: CheckInStatus.notInCCWS,
                  );
                  await auth.signOut();
                  if (context.mounted) {
                    Navigator.of(context).popUntil((r) => r.isFirst);
                  }
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

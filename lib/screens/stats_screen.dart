import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../utils/theme.dart';

/// Displays data sourced entirely from local SQLite —
/// demonstrating relational CRUD reads (JOINs, GROUP BY, aggregation).
class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _room = RoomService();
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Stats'),
        bottom: TabBar(
          controller: _tabs,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          indicatorColor: T.accent,
          tabs: const [
            Tab(text: 'My History'),
            Tab(text: 'Recent Ins'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _MyHistoryTab(auth: _auth, room: _room),
          _RecentCheckInsTab(room: _room),
        ],
      ),
    );
  }
}

// ─── My History Tab ──────────────────────────────────────────────────────────

class _MyHistoryTab extends StatelessWidget {
  final AuthService auth;
  final RoomService room;
  const _MyHistoryTab({required this.auth, required this.room});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: room.getLocalCheckInHistory(auth.userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmer();
        final rows = snap.data ?? [];

        // Count stats
        final totalIn = rows.where((r) => r['status'] == 'inCCWS').length;
        final totalOut = rows.where((r) => r['status'] == 'notInCCWS').length;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary cards
            Row(
              children: [
                _StatCard(
                  label: 'Times Checked In',
                  value: '$totalIn',
                  color: T.inCCWS,
                  icon: Icons.login_rounded,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Times Checked Out',
                  value: '$totalOut',
                  color: T.muted,
                  icon: Icons.logout_rounded,
                ),
              ],
            ),
            const SizedBox(height: 20),

            _SectionLabel(
              'Check-in Log',
              subtitle: 'From local SQLite · check_ins JOIN users',
            ),
            const SizedBox(height: 10),

            if (rows.isEmpty)
              _empty('No check-in history yet.\nToggle your presence to start.')
            else
              ...rows.map((r) {
                final isIn = r['status'] == 'inCCWS';
                final ts = DateTime.fromMillisecondsSinceEpoch(
                    r['checked_at'] as int);
                return _HistoryRow(
                  isIn: isIn,
                  timestamp: ts,
                );
              }),
          ],
        );
      },
    );
  }
}

// ─── Recent Check-ins Tab ────────────────────────────────────────────────────

class _RecentCheckInsTab extends StatelessWidget {
  final RoomService room;
  const _RecentCheckInsTab({required this.room});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: room.getRecentCheckIns(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _shimmer();
        final rows = snap.data ?? [];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel(
              'Recent Activity',
              subtitle:
                  'SQLite: check_ins INNER JOIN users ORDER BY checked_at DESC',
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              _empty('No activity yet.')
            else
              ...rows.map((r) {
                final isIn = r['status'] == 'inCCWS';
                final ts = DateTime.fromMillisecondsSinceEpoch(
                    r['checked_at'] as int);
                final name = r['display_name'] as String? ?? '?';
                final photoUrl = r['photo_url'] as String? ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundImage: photoUrl.isNotEmpty
                            ? NetworkImage(photoUrl)
                            : null,
                        backgroundColor: T.primary.withOpacity(0.1),
                        child: photoUrl.isEmpty
                            ? Text(name[0].toUpperCase(),
                                style: const TextStyle(
                                    color: T.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: GoogleFonts.dmSans(
                                    fontWeight: FontWeight.w600, fontSize: 13)),
                            Text(_fmt(ts),
                                style: GoogleFonts.dmSans(
                                    fontSize: 11, color: T.muted)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isIn ? T.inCCWS : T.muted).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isIn ? '✅ Checked in' : '🚪 Checked out',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: isIn ? T.inCCWS : T.muted,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

// ─── Shared widgets ──────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard(
      {required this.label,
      required this.value,
      required this.color,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 28, color: color)),
            Text(label,
                style: GoogleFonts.dmSans(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  final String subtitle;
  const _SectionLabel(this.title, {required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: T.ink)),
        const SizedBox(height: 2),
        Text(subtitle,
            style: GoogleFonts.dmSans(fontSize: 10, color: T.muted)),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  final bool isIn;
  final DateTime timestamp;
  const _HistoryRow({required this.isIn, required this.timestamp});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isIn ? T.inCCWS : T.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isIn ? 'Checked in' : 'Checked out',
            style: GoogleFonts.dmSans(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: isIn ? T.inCCWS : T.muted),
          ),
          const Spacer(),
          Text(
            _fmt(timestamp),
            style: GoogleFonts.dmSans(fontSize: 11, color: T.muted),
          ),
        ],
      ),
    );
  }
}

String _fmt(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}

Widget _shimmer() => Shimmer.fromColors(
      baseColor: Colors.grey.shade200,
      highlightColor: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 56,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );

Widget _empty(String msg) => Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(color: T.muted, fontSize: 14)),
      ),
    );

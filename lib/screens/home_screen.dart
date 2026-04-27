import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:io';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/room_service.dart';
import '../services/image_service.dart';
import '../utils/theme.dart';
import 'profile_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = AuthService();
  final _room = RoomService();
  final _image = ImageService();
  final _commentCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  String? _editingCommentId;
  final _editCtrl = TextEditingController();
  String? _selectedPhotoPath;

  @override
  void dispose() {
    _commentCtrl.dispose();
    _editCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _togglePresence(CheckInStatus newStatus) async {
    await _room.setPresence(
      userId: _auth.userId,
      userEmail: _auth.userEmail,
      userDisplayName: _auth.userDisplayName,
      userPhotoUrl: _auth.userPhotoUrl,
      status: newStatus,
    );
  }

  Future<void> _postComment(CheckInStatus? presence) async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    _commentCtrl.clear();
    FocusScope.of(context).unfocus();

    await _room.addComment(
      userId: _auth.userId,
      userEmail: _auth.userEmail,
      userDisplayName: _auth.userDisplayName,
      userPhotoUrl: _auth.userPhotoUrl,
      text: text,
      presenceAtPost: presence,
    );
    
    setState(() => _selectedPhotoPath = null);
  }

  Future<void> _pickPhotoForComment() async {
    final filePath = await _image.pickPhotoFromGallery();
    if (filePath != null) {
      setState(() => _selectedPhotoPath = filePath);
    }
  }

  Future<void> _takePhotoForComment() async {
    final filePath = await _image.takePhoto();
    if (filePath != null) {
      setState(() => _selectedPhotoPath = filePath);
    }
  }

  void _clearPhotoForComment() {
    setState(() => _selectedPhotoPath = null);
  }

  void _showCameraOptions() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.blue),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_rounded, color: Colors.green),
              title: const Text('Pick from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.purple),
              title: const Text('View All Photos'),
              onTap: () {
                Navigator.pop(context);
                _viewPhotos();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final filePath = await _image.takePhoto();
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved locally!')),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final filePath = await _image.pickPhotoFromGallery();
    if (filePath != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Photo saved locally!')),
      );
    }
  }

  void _viewPhotos() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _PhotoGalleryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.domain_rounded, size: 20),
            const SizedBox(width: 8),
            const Text('CCWS Vision'),
          ],
        ),
        actions: [
          StreamBuilder<List<UserPresence>>(
            stream: _room.presentUsersStream(),
            builder: (_, snap) {
              final count = snap.data?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Chip(
                  avatar: const Icon(Icons.people_alt_rounded, size: 14, color: Colors.white),
                  label: Text('$count in room',
                      style: GoogleFonts.dmSans(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                  backgroundColor: count > 0 ? T.inCCWS : T.notInCCWS,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
          StreamBuilder<UserPresence?>(
            stream: _room.myPresenceStream(_auth.userId),
            builder: (_, snap) {
              final isIn = snap.data?.status == CheckInStatus.inCCWS;
              if (!isIn) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.camera_alt_rounded),
                tooltip: 'Capture CCWS Condition',
                onPressed: _showCameraOptions,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Local Stats (SQLite)',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const StatsScreen())),
          ),
          IconButton(
            icon: StreamBuilder<UserPresence?>(
              stream: _room.myPresenceStream(_auth.userId),
              builder: (_, snap) {
                final photoUrl = _auth.userPhotoUrl;
                return CircleAvatar(
                  radius: 16,
                  backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                  backgroundColor: T.accent,
                  child: photoUrl.isEmpty
                      ? Text(_auth.userDisplayName.isNotEmpty
                            ? _auth.userDisplayName[0].toUpperCase()
                            : 'U',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))
                      : null,
                );
              },
            ),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ─── Check-in header ───────────────────────────────────────────
          StreamBuilder<UserPresence?>(
            stream: _room.myPresenceStream(_auth.userId),
            builder: (context, snap) {
              final presence = snap.data;
              final isIn = presence?.status == CheckInStatus.inCCWS;

              return _CheckInBanner(
                isIn: isIn,
                onToggle: _togglePresence,
                displayName: _auth.userDisplayName,
              );
            },
          ),

          // ─── Live presence strip ───────────────────────────────────────
          StreamBuilder<List<UserPresence>>(
            stream: _room.presentUsersStream(),
            builder: (_, snap) {
              final users = snap.data ?? [];
              if (users.isEmpty) return const SizedBox.shrink();
              return _PresenceStrip(users: users);
            },
          ),

          // ─── Comments feed ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<List<RoomComment>>(
              stream: _room.commentsStream(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return _shimmerList();
                }
                final comments = snap.data ?? [];
                if (comments.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline_rounded,
                            size: 52, color: T.muted.withOpacity(0.4)),
                        const SizedBox(height: 12),
                        Text('No updates yet.\nBe the first to comment!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.dmSans(
                                color: T.muted, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
                  itemCount: comments.length,
                  itemBuilder: (_, i) => _CommentCard(
                    comment: comments[i],
                    currentUserId: _auth.userId,
                    isEditing: _editingCommentId == comments[i].id,
                    editCtrl: _editCtrl,
                    onEditTap: () {
                      setState(() {
                        _editingCommentId = comments[i].id;
                        _editCtrl.text = comments[i].text;
                      });
                    },
                    onEditSave: () async {
                      final text = _editCtrl.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment cannot be empty')),
                        );
                        return;
                      }
                      await _room.updateComment(comments[i].id, text);
                      _editCtrl.clear();
                      setState(() => _editingCommentId = null);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Comment updated')),
                        );
                      }
                    },
                    onEditCancel: () =>
                        setState(() => _editingCommentId = null),
                    onDelete: () => _confirmDelete(comments[i]),
                  ),
                );
              },
            ),
          ),

          // ─── Comment input bar ─────────────────────────────────────────
          _CommentInputBar(
            controller: _commentCtrl,
            presenceStream: _room.myPresenceStream(_auth.userId),
            onSend: _postComment,
            selectedPhotoPath: _selectedPhotoPath,
            onPickPhoto: _pickPhotoForComment,
            onTakePhoto: _takePhotoForComment,
            onClearPhoto: _clearPhotoForComment,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(RoomComment c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await _room.deleteComment(c.id);
  }

  Widget _shimmerList() => ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: 4,
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey.shade200,
          highlightColor: Colors.grey.shade50,
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );
}

// ─── Check-in Banner ────────────────────────────────────────────────────────

class _CheckInBanner extends StatelessWidget {
  final bool isIn;
  final void Function(CheckInStatus) onToggle;
  final String displayName;

  const _CheckInBanner({
    required this.isIn,
    required this.onToggle,
    required this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isIn ? T.inCCWS.withOpacity(0.08) : T.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isIn ? T.inCCWS.withOpacity(0.4) : Colors.grey.shade200,
          width: isIn ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isIn ? T.inCCWS : T.muted.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isIn ? 'You\'re currently in CCWS IUP' : 'You\'re not in CCWS IUP right now',
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: isIn ? T.inCCWS : T.muted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ToggleBtn(
                  label: '✅  I\'m in CCWS IUP',
                  selected: isIn,
                  color: T.inCCWS,
                  onTap: () => onToggle(CheckInStatus.inCCWS),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ToggleBtn(
                  label: '🚪  I\'m not here',
                  selected: !isIn,
                  color: T.muted,
                  onTap: () => onToggle(CheckInStatus.notInCCWS),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ToggleBtn({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected ? color : Colors.grey.shade300, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : T.muted,
          ),
        ),
      ),
    );
  }
}

// ─── Presence strip ─────────────────────────────────────────────────────────

class _PresenceStrip extends StatelessWidget {
  final List<UserPresence> users;
  const _PresenceStrip({required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.people_alt_rounded, size: 14, color: T.inCCWS),
          const SizedBox(width: 6),
          Text(
            '${users.length} ${users.length == 1 ? 'person' : 'people'} in room now:',
            style: GoogleFonts.dmSans(
                fontSize: 12, color: T.inCCWS, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: users.map((u) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: u.userDisplayName,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundImage: u.userPhotoUrl.isNotEmpty
                            ? NetworkImage(u.userPhotoUrl)
                            : null,
                        backgroundColor: T.primary.withOpacity(0.15),
                        child: u.userPhotoUrl.isEmpty
                            ? Text(
                                u.userDisplayName.isNotEmpty
                                    ? u.userDisplayName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: T.primary,
                                    fontWeight: FontWeight.bold))
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comment Card ────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final RoomComment comment;
  final String currentUserId;
  final bool isEditing;
  final TextEditingController editCtrl;
  final VoidCallback onEditTap;
  final VoidCallback onEditSave;
  final VoidCallback onEditCancel;
  final VoidCallback onDelete;

  const _CommentCard({
    required this.comment,
    required this.currentUserId,
    required this.isEditing,
    required this.editCtrl,
    required this.onEditTap,
    required this.onEditSave,
    required this.onEditCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isOwner = comment.userId == currentUserId && currentUserId.isNotEmpty;
    final presenceColor = comment.presenceAtPost == CheckInStatus.inCCWS
        ? T.inCCWS
        : T.muted;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundImage: comment.userPhotoUrl.isNotEmpty
                      ? NetworkImage(comment.userPhotoUrl) 
                      : null,
                  backgroundColor: T.primary.withOpacity(0.12),
                  child: comment.userPhotoUrl.isEmpty
                      ? Text(
                          comment.userDisplayName.isNotEmpty
                              ? comment.userDisplayName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                              color: T.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13))
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              comment.userDisplayName,
                              style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.w700, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (comment.presenceAtPost != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: presenceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                comment.presenceAtPost!.emoji +
                                    ' ' +
                                    comment.presenceAtPost!.label,
                                style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    color: presenceColor,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        timeago.format(comment.createdAt) +
                            (comment.updatedAt != null ? ' · edited' : ''),
                        style: GoogleFonts.dmSans(
                            fontSize: 11, color: T.muted),
                      ),
                    ],
                  ),
                ),
                if (isOwner)
                  PopupMenuButton<String>(
                    iconSize: 18,
                    padding: EdgeInsets.zero,
                    onSelected: (v) {
                      if (v == 'edit') onEditTap();
                      if (v == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red))),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (isEditing) ...[
              TextField(
                controller: editCtrl,
                maxLines: null,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Edit your comment...',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                      onPressed: onEditCancel,
                      child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                      onPressed: onEditSave, child: const Text('Save')),
                ],
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(left: 44),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment.text,
                      style: GoogleFonts.dmSans(fontSize: 14, height: 1.5),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

// ─── Comment Input Bar ───────────────────────────────────────────────────────

class _CommentInputBar extends StatelessWidget {
  final TextEditingController controller;
  final Stream<UserPresence?> presenceStream;
  final void Function(CheckInStatus?) onSend;
  final String? selectedPhotoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback onTakePhoto;
  final VoidCallback onClearPhoto;

  const _CommentInputBar({
    required this.controller,
    required this.presenceStream,
    required this.onSend,
    this.selectedPhotoPath,
    required this.onPickPhoto,
    required this.onTakePhoto,
    required this.onClearPhoto,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserPresence?>(
      stream: presenceStream,
      builder: (_, snap) {
        final presence = snap.data;
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.fromLTRB(
                14, 10, 14, MediaQuery.of(context).viewInsets.bottom + 14),
            decoration: BoxDecoration(
              color: T.card,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo preview
                if (selectedPhotoPath != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          File(selectedPhotoPath!),
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: onClearPhoto,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Photo button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.image_rounded, color: T.primary),
                      onSelected: (value) {
                        if (value == 'camera') {
                          onTakePhoto();
                        } else if (value == 'gallery') {
                          onPickPhoto();
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'camera',
                          child: Row(
                            children: [
                              Icon(Icons.camera_alt_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Take photo'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'gallery',
                          child: Row(
                            children: [
                              Icon(Icons.photo_library_rounded, size: 18),
                              SizedBox(width: 10),
                              Text('Pick from gallery'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Share the room vibe…',
                          hintStyle: GoogleFonts.dmSans(color: T.muted, fontSize: 13),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => onSend(presence?.status),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: T.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Photo Gallery Screen ───────────────────────────────────────────────────

class _PhotoGalleryScreen extends StatefulWidget {
  const _PhotoGalleryScreen();

  @override
  State<_PhotoGalleryScreen> createState() => _PhotoGalleryScreenState();
}

class _PhotoGalleryScreenState extends State<_PhotoGalleryScreen> {
  final _imageService = ImageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CCWS Photos'),
      ),
      body: FutureBuilder<List>(
        future: _imageService.getCCWSPhotos(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final photos = snapshot.data ?? [];

          if (photos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image_not_supported_outlined,
                      size: 64, color: T.muted.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  Text('No photos yet',
                      style: GoogleFonts.dmSans(
                          fontSize: 16, color: T.muted, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('Capture CCWS conditions to get started',
                      style: GoogleFonts.dmSans(color: T.muted, fontSize: 13)),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: photos.length,
            itemBuilder: (_, index) {
              final photo = photos[index];
              return GestureDetector(
                onLongPress: () => _confirmDelete(context, photo),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: FileImage(photo),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          DateTime.fromMillisecondsSinceEpoch(
                            int.parse(photo.path
                                .split('_')
                                .last
                                .replaceAll('.jpg', '')),
                          ).toString().split('.')[0],
                          style: GoogleFonts.dmSans(
                              color: Colors.white, fontSize: 10),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, var photo) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete photo?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _imageService.deletePhoto(photo.path);
      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo deleted')),
        );
      }
    }
  }
}

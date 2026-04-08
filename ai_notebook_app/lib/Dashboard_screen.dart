import 'dart:convert';
import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const DashboardScreen({super.key, this.onSwitchTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<dynamic> _notes = [];
  bool _loading = true;
  String _userName = 'User';
  String _userEmail = '';
  String _selectedMood = '';

  static const _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Tired'},
    {'emoji': '😤', 'label': 'Angry'},
    {'emoji': '😍', 'label': 'Love'},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final name = await ApiService.getUserName();
      final email = await ApiService.getUserEmail();
      final notes = await ApiService.getNotes();
      if (mounted) {
        setState(() {
          _userName = name;
          _userEmail = email;
          _notes = notes;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<dynamic> get _todayNotes {
    final today = DateTime.now();
    return _notes.where((n) {
      final d = DateTime.tryParse(n['createdAt'] ?? '');
      return d != null &&
          d.year == today.year &&
          d.month == today.month &&
          d.day == today.day;
    }).toList();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String get _greetingEmoji {
    final h = DateTime.now().hour;
    if (h < 12) return '☀️';
    if (h < 17) return '🌤️';
    return '🌙';
  }

  Future<void> _showAddNoteDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String mood = _selectedMood;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: const Color(0xFF2d1b4e),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Add Note',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _dialogField(
                    titleCtrl, 'Title (optional)', Icons.title_outlined),
                const SizedBox(height: 12),
                _dialogField(
                    contentCtrl, 'How are you feeling?',
                    Icons.edit_note_rounded,
                    maxLines: 4),
                const SizedBox(height: 14),
                const Text('Mood',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _moods
                      .map((m) => GestureDetector(
                            onTap: () => setSt(
                                () => mood = m['emoji'] as String),
                            child: AnimatedContainer(
                              duration:
                                  const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: mood == m['emoji']
                                    ? const Color(0xFF7c3aed)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius:
                                    BorderRadius.circular(20),
                                border: Border.all(
                                    color: mood == m['emoji']
                                        ? Colors.transparent
                                        : Colors.white24),
                              ),
                              child: Text(m['emoji'] as String,
                                  style:
                                      const TextStyle(fontSize: 20)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7c3aed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final content = contentCtrl.text.trim();
                        if (content.isEmpty) return;
                        Navigator.pop(ctx);
                        final noteId = await ApiService.createNote(
                          title: titleCtrl.text.trim(),
                          content: content,
                          mood: mood,
                        );
                        final ok = noteId != null;
                        if (ok && mounted) _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'Note saved! ✨ Generating sticker auto-reminder...' : 'Failed to save'),
                              backgroundColor: ok
                                  ? const Color(0xFF7c3aed)
                                  : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12)),
                            ),
                          );
                        }
                        // ✨ AUTO-STICKER WORKFLOW
                        if (ok && noteId.isNotEmpty) {
                           Future.microtask(() async {
                             try {
                                final stickerUrl = await ApiService.generateSticker(content);
                                if (stickerUrl.isNotEmpty) {
                                   await ApiService.saveNoteSticker(noteId, stickerUrl);
                                }
                             } catch(e) {
                                print("Auto sticker failed: $e");
                             }
                           });
                        }
                      },
                      child: const Text('Save',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteNote(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b4e),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Note',
            style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this note?',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final ok = await ApiService.deleteNote(id);
    if (ok && mounted) _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Note deleted' : 'Failed to delete'),
          backgroundColor: ok ? const Color(0xFF7c3aed) : Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _showEditNoteDialog(dynamic note) async {
    final titleCtrl = TextEditingController(text: note['title'] ?? '');
    final contentCtrl = TextEditingController(text: note['content'] ?? '');
    String mood = note['mood'] ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: const Color(0xFF2d1b4e),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Note',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                _dialogField(
                    titleCtrl, 'Title (optional)', Icons.title_outlined),
                const SizedBox(height: 12),
                _dialogField(
                    contentCtrl, 'How are you feeling?',
                    Icons.edit_note_rounded,
                    maxLines: 4),
                const SizedBox(height: 14),
                const Text('Mood',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _moods
                      .map((m) => GestureDetector(
                            onTap: () =>
                                setSt(() => mood = m['emoji'] as String),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: mood == m['emoji']
                                    ? const Color(0xFF7c3aed)
                                    : Colors.white.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: mood == m['emoji']
                                        ? Colors.transparent
                                        : Colors.white24),
                              ),
                              child: Text(m['emoji'] as String,
                                  style: const TextStyle(fontSize: 20)),
                            ),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel',
                          style: TextStyle(color: Colors.white54)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7c3aed),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () async {
                        final content = contentCtrl.text.trim();
                        if (content.isEmpty) return;
                        Navigator.pop(ctx);
                        final ok = await ApiService.updateNote(
                          note['_id'] as String,
                          titleCtrl.text.trim(),
                          content,
                          mood,
                        );
                        if (ok && mounted) _loadData();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  ok ? 'Note updated! ✓' : 'Failed to update'),
                              backgroundColor:
                                  ok ? const Color(0xFF7c3aed) : Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      },
                      child: const Text('Update',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      drawer: _buildDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1a0033), Color(0xFF2d1b4e)],
          ),
        ),
        child: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFFc084fc),
            onRefresh: _loadData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Builder(
                        builder: (ctx) => GestureDetector(
                          onTap: () => Scaffold.of(ctx).openDrawer(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.menu_rounded,
                                color: Colors.white, size: 22),
                          ),
                        ),
                      ),
                      const Icon(Icons.nightlight_round,
                          color: Colors.white70, size: 24),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Greeting
                  Text(
                    '$_greetingEmoji $_greeting,',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'How are you feeling today?',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),

                  const SizedBox(height: 20),

                  // Mood row
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _moods.map((m) {
                        final selected = _selectedMood == m['emoji'];
                        return GestureDetector(
                          onTap: () => setState(() =>
                              _selectedMood = m['emoji'] as String),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: selected
                                  ? const LinearGradient(colors: [
                                      Color(0xFF7c3aed),
                                      Color(0xFFa855f7)
                                    ])
                                  : null,
                              color: selected
                                  ? null
                                  : Colors.white.withOpacity(0.08),
                              borderRadius:
                                  BorderRadius.circular(20),
                              border: Border.all(
                                  color: selected
                                      ? Colors.transparent
                                      : Colors.white24),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(m['emoji'] as String,
                                    style: const TextStyle(
                                        fontSize: 26)),
                                const SizedBox(height: 4),
                                Text(m['label'] as String,
                                    style: TextStyle(
                                        color: selected
                                            ? Colors.white
                                            : Colors.white60,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Add Note button
                  GestureDetector(
                    onTap: _showAddNoteDialog,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7c3aed), Color(0xFFa855f7)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7c3aed)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_circle_outline,
                              color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Add Note +',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Today's notes header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Today's Notes",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                      GestureDetector(
                        onTap: () => widget.onSwitchTab?.call(1),
                        child: const Text('View All >',
                            style: TextStyle(
                                color: Color(0xFFc084fc),
                                fontSize: 13)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Notes
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(
                            color: Color(0xFFc084fc)),
                      ),
                    )
                  else if (_todayNotes.isEmpty)
                    _emptyState()
                  else
                    ..._todayNotes.map((n) => _buildNoteCard(n)),

                  const SizedBox(height: 16),

                  // Recent notes (other days)
                  if (!_loading && _notes.isNotEmpty) ...[
                    const Text('Recent Notes',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    ..._notes
                        .where((n) => !_todayNotes.contains(n))
                        .take(4)
                        .map((n) => _buildNoteCard(n)),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border:
            Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: const Column(
        children: [
          Text('📝', style: TextStyle(fontSize: 40)),
          SizedBox(height: 10),
          Text('No notes today',
              style: TextStyle(color: Colors.white54, fontSize: 15)),
          SizedBox(height: 4),
          Text('Tap "Add Note +" to start writing',
              style: TextStyle(color: Colors.white38, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildNoteCard(dynamic note) {
    final isWide = MediaQuery.of(context).size.width > 600;
    final createdAt =
        DateTime.tryParse(note['createdAt'] ?? '');
    final timeStr = createdAt != null
        ? '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}'
        : '';
    final hasReminder = note['reminderAt'] != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.symmetric(
          horizontal: 16, vertical: isWide ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF4c1d95),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                note['mood']?.isNotEmpty == true
                    ? note['mood']
                    : '📝',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note['title']?.isNotEmpty == true
                      ? note['title']
                      : note['content'],
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: isWide ? 15 : 14,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '$timeStr${hasReminder ? ' · Reminder Set' : ''}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showEditNoteDialog(note),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF7c3aed).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF7c3aed).withOpacity(0.3),
                    width: 1),
              ),
              child: const Icon(Icons.edit_outlined,
                  color: Color(0xFFc084fc), size: 18),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _deleteNote(note['_id'] as String),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: Colors.red.withOpacity(0.3), width: 1),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: Color(0xFFf87171), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: maxLines == 1
            ? Icon(icon, color: Colors.white38, size: 20)
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF7c3aed), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF130025),
      width: 260,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 16, 16),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7c3aed), Color(0xFFa855f7)],
                      ),
                    ),
                    child: const Center(
                        child: Text('🧑',
                            style: TextStyle(fontSize: 26))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userName,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(_userEmail,
                            style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11),
                            overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (ctx) => GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: const Icon(Icons.close,
                          color: Colors.white38, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            _drawerNavItem(
                Icons.dashboard_rounded, 'Dashboard', 0),
            _drawerNavItem(
                Icons.calendar_month_rounded, 'Calendar', 1),
            _drawerNavItem(
                Icons.auto_awesome_rounded, 'Stickers', 2),
            _drawerNavItem(
                Icons.notifications_rounded, 'Notifications', 3),
            _drawerNavItem(Icons.person_rounded, 'Profile', 4),
            const Spacer(),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: Color(0xFFf87171)),
              title: const Text('Log Out',
                  style: TextStyle(
                      color: Color(0xFFf87171),
                      fontWeight: FontWeight.w600)),
              onTap: () async {
                await ApiService.logout();
                if (!mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerNavItem(
      IconData icon, String title, int tabIndex) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF7c3aed).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFFc084fc), size: 20),
      ),
      title: Text(title,
          style:
              const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: const Icon(Icons.chevron_right,
          color: Colors.white24, size: 18),
      onTap: () {
        Navigator.pop(context);
        widget.onSwitchTab?.call(tabIndex);
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const ProfileScreen({super.key, this.onSwitchTab});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _name = '';
  String _email = '';
  bool _editing = false;
  int _noteCount = 0;
  int _stickerCount = 0;
  int _streakCount = 0;
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final name = await ApiService.getUserName();
    final email = await ApiService.getUserEmail();
    final notes = await ApiService.getNotes();

    final noteCount = notes.length;
    final stickerCount = notes.where((n) {
      final sticker = (n['stickerUrl'] ?? '').toString().trim();
      return sticker.isNotEmpty;
    }).length;

    final daySet = <DateTime>{};
    for (final n in notes) {
      final raw = (n['createdAt'] ?? '').toString();
      final parsed = DateTime.tryParse(raw);
      if (parsed == null) continue;
      daySet.add(DateTime(parsed.year, parsed.month, parsed.day));
    }

    int streak = 0;
    DateTime cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    while (daySet.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _nameCtrl.text = name;
        _emailCtrl.text = email;
        _noteCount = noteCount;
        _stickerCount = stickerCount;
        _streakCount = streak;
      });
    }
  }

  Future<void> _saveProfile() async {
    await ApiService.saveUser(_nameCtrl.text.trim(), _emailCtrl.text.trim());
    setState(() {
      _name = _nameCtrl.text.trim();
      _email = _emailCtrl.text.trim();
      _editing = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated!"),
          backgroundColor: Color(0xFF7c3aed),
        ),
      );
    }
  }

  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a0033), Color(0xFF2d1b4e)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.settings_rounded,
                      color: Colors.white70),
                  Text("Profile",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Icon(Icons.menu_rounded, color: Colors.white70),
                ],
              ),

              const SizedBox(height: 36),

              // Avatar
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF7c3aed), Color(0xFFa855f7)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7c3aed).withValues(alpha: 0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Text("🧑", style: TextStyle(fontSize: 48)),
                ),
              ),

              const SizedBox(height: 16),

              if (!_editing) ...[
                Text(_name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(_email,
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 14)),
              ] else ...[
                _editField("Name", _nameCtrl, Icons.person_outline),
                const SizedBox(height: 12),
                _editField("Email", _emailCtrl, Icons.email_outlined),
              ],

              const SizedBox(height: 24),

              // Edit / Save Profile button
              GestureDetector(
                onTap: _editing ? _saveProfile : () => setState(() => _editing = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 40, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7c3aed), Color(0xFFa855f7)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7c3aed).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.auto_awesome,
                          color: Colors.white, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        _editing ? "Save Profile" : "Edit Profile",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),

              if (_editing)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => setState(() => _editing = false),
                    child: const Text("Cancel",
                        style: TextStyle(color: Colors.white54)),
                  ),
                ),

              const SizedBox(height: 32),

              // Stats row
              Row(
                children: [
                  _statCard("Notes", "$_noteCount"),
                  const SizedBox(width: 12),
                  _statCard("Stickers", "$_stickerCount"),
                  const SizedBox(width: 12),
                  _statCard("Streak", "$_streakCount 🔥"),
                ],
              ),

              const SizedBox(height: 32),

              // Menu items
              _menuItem(Icons.note_alt_outlined, "My Notes",
                  const Color(0xFF7c3aed), onTap: () => widget.onSwitchTab?.call(0)),
              _menuItem(Icons.auto_awesome_outlined, "AI Stickers",
                  const Color(0xFFa855f7), onTap: () => widget.onSwitchTab?.call(2)),
              _menuItem(Icons.notifications_outlined, "Notifications",
                  const Color(0xFF6d28d9), onTap: () => widget.onSwitchTab?.call(3)),
              _menuItem(Icons.settings_outlined, "Settings",
                  Colors.white38, onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings удахгүй нэмэгдэнэ'),
                        backgroundColor: Color(0xFF7c3aed),
                      ),
                    );
                  }),

              const SizedBox(height: 20),

              // Logout
              GestureDetector(
                onTap: _logout,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3), width: 1),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded,
                          color: Color(0xFFf87171), size: 20),
                      SizedBox(width: 8),
                      Text("Log Out",
                          style: TextStyle(
                              color: Color(0xFFf87171),
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(
      String label, TextEditingController ctrl, IconData icon) {
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.08),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFa855f7), width: 1.5),
        ),
      ),
    );
  }

  Widget _statCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white54, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, Color iconColor, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500)),
            ),
            const Icon(Icons.chevron_right,
                color: Colors.white30, size: 20),
          ],
        ),
      ),
    );
  }
}

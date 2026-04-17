import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';

bool _isSvgDataUri(String value) => value.startsWith('data:image/svg');

bool _isDataUri(String value) => value.startsWith('data:');

bool _isSvgUrl(String value) {
  final uri = Uri.tryParse(value);
  final path = uri?.path.toLowerCase() ?? value.toLowerCase();
  return path.endsWith('.svg');
}

class _StickerThumb extends StatelessWidget {
  final String url;
  final Widget fallback;

  const _StickerThumb({
    required this.url,
    required this.fallback,
  });

  String? _decodeSvgDataUri(String value) {
    try {
      final parts = value.split(',');
      if (parts.length < 2) return null;
      return String.fromCharCodes(base64Decode(parts[1]));
    } catch (_) {
      return null;
    }
  }

  Uint8List? _decodeDataUri(String value) {
    try {
      final parts = value.split(',');
      if (parts.length < 2) return null;
      return base64Decode(parts.last);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (_isSvgDataUri(url)) {
      final svg = _decodeSvgDataUri(url);
      child = svg == null
          ? fallback
          : SvgPicture.string(
              svg,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
            );
    } else if (_isDataUri(url)) {
      final bytes = _decodeDataUri(url);
      child = bytes == null
          ? fallback
          : Image.memory(
              bytes,
              width: 46,
              height: 46,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );
    } else if (_isSvgUrl(url)) {
      child = SvgPicture.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        placeholderBuilder: (_) => const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    } else {
      child = Image.network(
        url,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: child,
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationsScreen({
    super.key,
    this.onUnreadCountChanged,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const String _dismissedKeyStore =
      'notifications_dismissed_keys_v1';
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  List<_Notif> _notifs = [];
  Set<String> _dismissedKeys = <String>{};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrapNotifications();
  }

  Future<void> _bootstrapNotifications() async {
    await _loadDismissedKeys();
    await _loadNotifications();
  }

  Future<void> _loadDismissedKeys() async {
    try {
      final raw = await _storage.read(key: _dismissedKeyStore);
      if (raw == null || raw.trim().isEmpty) return;

      final decoded = jsonDecode(raw);
      if (decoded is List) {
        _dismissedKeys = decoded.map((e) => e.toString()).toSet();
      }
    } catch (_) {
      _dismissedKeys = <String>{};
    }
  }

  Future<void> _persistDismissedKeys() async {
    try {
      await _storage.write(
        key: _dismissedKeyStore,
        value: jsonEncode(_dismissedKeys.toList()),
      );
    } catch (_) {}
  }

  void _notifyUnreadCountChanged() {
    widget.onUnreadCountChanged?.call(_unreadCount);
  }

  Future<void> _loadNotifications() async {
    setState(() => _loading = true);
    final notes = await ApiService.getNotes();

    final mapped = notes
        .where((n) {
          final hasReminder = (n['reminderAt'] ?? '').toString().trim().isNotEmpty;
          final hasSticker = (n['stickerUrl'] ?? '').toString().trim().isNotEmpty;
          return hasReminder || hasSticker;
        })
        .map((n) {
          final title = (n['title'] ?? '').toString().trim();
          final content = (n['content'] ?? '').toString().trim();
          final mood = (n['mood'] ?? '').toString().trim();
          final stickerUrl = (n['stickerUrl'] ?? '').toString().trim();
          final reminderAtRaw = (n['reminderAt'] ?? '').toString();
          final createdAtRaw = (n['createdAt'] ?? '').toString();
          final updatedAtRaw = (n['updatedAt'] ?? '').toString();

          final reminder = DateTime.tryParse(reminderAtRaw);
          final created = DateTime.tryParse(createdAtRaw);
          final updated = DateTime.tryParse(updatedAtRaw);
          final now = DateTime.now();
          final hasReminder = reminderAtRaw.trim().isNotEmpty;
          final noteId = (n['_id'] ?? '').toString().trim();
          final kind = hasReminder ? 'reminder' : 'sticker';
          final notificationKey = noteId.isNotEmpty
              ? '$noteId|$kind'
              : '${title.isNotEmpty ? title : content}|$kind|${now.millisecondsSinceEpoch}';

          final source = hasReminder
              ? (reminder ?? created ?? now)
              : (updated ?? created ?? now);
          final isRead = hasReminder
              ? (reminder == null ? false : reminder.isBefore(now))
              : now.difference(source).inHours >= 24;
          final subtitle = hasReminder
              ? (reminder == null
                    ? 'Reminder'
                    : '${_fmtTime(reminder)} · Reminder')
              : '${_fmtTime(source)} · Sticker generated';

          return _Notif(
            notificationKey: notificationKey,
            noteId: noteId,
            noteTitle: title,
            noteContent: content,
            noteMood: mood,
            hasReminder: hasReminder,
            icon: mood.isNotEmpty ? mood : '⏰',
            imageUrl: stickerUrl.isNotEmpty ? stickerUrl : null,
            title: title.isNotEmpty ? title : content,
            subtitle: subtitle,
            time: _relativeTime(source),
            sourceAt: source,
            read: isRead,
          );
        })
        .where((n) =>
            n.title.trim().isNotEmpty &&
            !_dismissedKeys.contains(n.notificationKey))
        .toList()
      ..sort((a, b) => b.sourceAt.compareTo(a.sourceAt));

    if (!mounted) return;
    setState(() {
      _notifs = mapped;
      _loading = false;
    });
    _notifyUnreadCountChanged();
  }

  static String _fmtTime(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String _relativeTime(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Future<bool> _deleteNotification(_Notif notif) async {
    var ok = true;

    if (notif.hasReminder && notif.noteId.isNotEmpty) {
      ok = await ApiService.updateNote(
        notif.noteId,
        notif.noteTitle,
        notif.noteContent,
        notif.noteMood,
        reminderAt: '',
      );

      if (ok) {
        await NotificationService.cancelScheduledReminderForNote(notif.noteId);
      }
    }

    if (!mounted) return false;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification delete failed'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return false;
    }

    setState(() {
      _notifs.removeWhere((n) => n.notificationKey == notif.notificationKey);
      _dismissedKeys.add(notif.notificationKey);
    });
    _notifyUnreadCountChanged();
    await _persistDismissedKeys();

    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notification deleted'),
        backgroundColor: Color(0xFF7c3aed),
      ),
    );
    return true;
  }

  int get _unreadCount => _notifs.where((n) => !n.read).length;

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
        child: Column(
          children: [
            // Top bar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Notifications",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  Stack(
                    children: [
                      const Icon(Icons.notifications_rounded,
                          color: Colors.white70, size: 28),
                      if (_unreadCount > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFf87171),
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              "$_unreadCount",
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // Mark all read
            if (_unreadCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        for (final n in _notifs) {
                          n.read = true;
                        }
                        _notifyUnreadCountChanged();
                      }),
                      child: const Text("Mark all as read",
                          style: TextStyle(
                              color: Color(0xFFc084fc), fontSize: 13)),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFc084fc),
                      ),
                    )
                  : _notifs.isEmpty
                      ? const Center(
                          child: Text(
                            'No reminders yet',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : RefreshIndicator(
                          color: const Color(0xFFc084fc),
                          onRefresh: _loadNotifications,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: _notifs.length,
                            itemBuilder: (ctx, i) {
                              final n = _notifs[i];
                              return Dismissible(
                                key: ValueKey(n.notificationKey),
                                direction: DismissDirection.endToStart,
                                confirmDismiss: (_) => _deleteNotification(n),
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade700,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  alignment: Alignment.centerRight,
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.white,
                                  ),
                                ),
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    n.read = true;
                                    _notifyUnreadCountChanged();
                                  }),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: n.read
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: n.read
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : const Color(0xFF7c3aed)
                                                .withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 46,
                                          height: 46,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF4c1d95),
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Center(
                                            child: n.imageUrl != null
                                                ? _StickerThumb(
                                                    url: n.imageUrl!,
                                                    fallback: Text(
                                                      n.icon,
                                                      style: const TextStyle(fontSize: 22),
                                                    ),
                                                  )
                                                : Text(
                                                    n.icon,
                                                    style: const TextStyle(
                                                        fontSize: 22),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(n.title,
                                                  style: TextStyle(
                                                      color: n.read
                                                          ? Colors.white70
                                                          : Colors.white,
                                                      fontSize: 14,
                                                      fontWeight: n.read
                                                          ? FontWeight.normal
                                                          : FontWeight.w600)),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  const Icon(Icons.alarm,
                                                      color: Color(0xFFc084fc), size: 14),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                    child: Text(n.subtitle,
                                                        style: const TextStyle(
                                                            color: Colors.white54,
                                                            fontSize: 12),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          children: [
                                            Text(n.time,
                                                style: const TextStyle(
                                                    color: Colors.white54, fontSize: 11)),
                                            const SizedBox(height: 6),
                                            if (!n.read)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFFa855f7),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          onPressed: () => _deleteNotification(n),
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white54,
                                            size: 18,
                                          ),
                                          tooltip: 'Delete notification',
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Notif {
  final String notificationKey;
  final String noteId;
  final String noteTitle;
  final String noteContent;
  final String noteMood;
  final bool hasReminder;
  final String icon, title, subtitle, time;
  final DateTime sourceAt;
  final String? imageUrl;
  bool read;
  _Notif({
    required this.notificationKey,
    required this.noteId,
    required this.noteTitle,
    required this.noteContent,
    required this.noteMood,
    required this.hasReminder,
    required this.icon,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.sourceAt,
    required this.read,
  });
}

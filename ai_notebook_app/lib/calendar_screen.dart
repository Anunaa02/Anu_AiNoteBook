import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
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
  final double size;
  final BorderRadius borderRadius;
  final Widget fallback;
  final bool isCircle;

  const _StickerThumb({
    required this.url,
    required this.size,
    required this.borderRadius,
    required this.fallback,
    this.isCircle = false,
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
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
    } else if (_isDataUri(url)) {
      final bytes = _decodeDataUri(url);
      child = bytes == null
          ? fallback
          : Image.memory(
              bytes,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => fallback,
            );
    } else if (_isSvgUrl(url)) {
      child = SvgPicture.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholderBuilder: (_) =>
            const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else {
      child = Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    final imageBox = SizedBox(width: size, height: size, child: child);

    if (isCircle) {
      return ClipOval(child: imageBox);
    }

    return ClipRRect(borderRadius: borderRadius, child: imageBox);
  }
}

class _DayStickerPreview {
  final String stickerUrl;
  final String label;
  final String noteText;
  final String subtitle;

  const _DayStickerPreview({
    required this.stickerUrl,
    required this.label,
    required this.noteText,
    required this.subtitle,
  });
}

class _DayNotePreview {
  final String stickerUrl;
  final String noteText;
  final String subtitle;
  final String mood;

  const _DayNotePreview({
    required this.stickerUrl,
    required this.noteText,
    required this.subtitle,
    required this.mood,
  });
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  List<dynamic> _notes = [];
  bool _loading = true;

  static const _moods = [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😴', 'label': 'Tired'},
    {'emoji': '😤', 'label': 'Angry'},
    {'emoji': '😍', 'label': 'Love'},
  ];

  static const List<String> _weekdays = [
    'SUN',
    'MON',
    'TUE',
    'WED',
    'THU',
    'FRI',
    'SAT',
  ];
  static const List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _loading = true);
    try {
      final notes = await ApiService.getNotes();
      setState(() {
        _notes = notes;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<DateTime?> _pickReminderDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final start = initial ?? now.add(const Duration(minutes: 5));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: start,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (pickedDate == null) return null;
    if (!mounted) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(start),
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  String _formatReminder(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    final h = d.hour.toString().padLeft(2, '0');
    final min = d.minute.toString().padLeft(2, '0');
    return '$y-$m-$day $h:$min';
  }

  String _formatDateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    final d = parsed.isUtc ? parsed.toLocal() : parsed;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  DateTime? _parseServerDateToLocalDay(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;

    final local = parsed.isUtc ? parsed.toLocal() : parsed;
    return DateTime(local.year, local.month, local.day);
  }

  DateTime? _parseCalendarDay(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;

    final datePrefix = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(raw);
    if (datePrefix != null) {
      final y = int.tryParse(datePrefix.group(1)!);
      final m = int.tryParse(datePrefix.group(2)!);
      final d = int.tryParse(datePrefix.group(3)!);
      if (y != null && m != null && d != null) {
        return DateTime(y, m, d);
      }
    }

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;

    // noteDate is semantic day data; keep day in UTC to avoid timezone drift.
    final utc = parsed.isUtc ? parsed : parsed.toUtc();
    return DateTime(utc.year, utc.month, utc.day);
  }

  DateTime? _parseServerDateTimeLocal(dynamic value) {
    final raw = (value ?? '').toString().trim();
    if (raw.isEmpty) return null;

    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return null;
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  Future<void> _syncReminderForNote({
    required String noteId,
    required DateTime? reminderAt,
    required String title,
    required String content,
    String? stickerUrl,
  }) async {
    if (reminderAt == null || !reminderAt.isAfter(DateTime.now())) {
      await NotificationService.cancelScheduledReminderForNote(noteId);
      return;
    }

    final notifTitle = title.trim().isNotEmpty ? title.trim() : 'Note reminder';
    final clean = content.trim().isNotEmpty
        ? content.trim()
        : 'You have a scheduled note reminder.';
    final notifBody = clean.length > 120
        ? '${clean.substring(0, 120)}...'
        : clean;

    await NotificationService.scheduleReminderNotification(
      noteId: noteId,
      reminderAt: reminderAt,
      title: notifTitle,
      body: notifBody,
      stickerUrl: stickerUrl,
    );
  }

  Future<void> _showAddNoteDialog() async {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    String selectedMood = '';
    DateTime noteDate = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    DateTime? reminderAt;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: const Color(0xFF2d1b4e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Note — ${noteDate.day}/${noteDate.month}/${noteDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Calendar date: ${_formatDateOnly(noteDate)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: noteDate,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (pickedDate == null) return;
                          setSt(() {
                            noteDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                            );
                            if (reminderAt != null) {
                              reminderAt = DateTime(
                                noteDate.year,
                                noteDate.month,
                                noteDate.day,
                                reminderAt!.hour,
                                reminderAt!.minute,
                              );
                            }
                          });
                        },
                        child: const Text(
                          'Set date',
                          style: TextStyle(color: Color(0xFFc084fc)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write your note...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminderAt == null
                              ? 'No reminder set'
                              : 'Reminder: ${_formatReminder(reminderAt!)}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final defaultReminder = DateTime(
                            noteDate.year,
                            noteDate.month,
                            noteDate.day,
                            9,
                            0,
                          );
                          final picked = await _pickReminderDateTime(
                            initial: reminderAt ?? defaultReminder,
                          );
                          if (picked == null) return;
                          setSt(() {
                            reminderAt = picked;
                            noteDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        },
                        child: const Text(
                          'Set',
                          style: TextStyle(color: Color(0xFFc084fc)),
                        ),
                      ),
                      if (reminderAt != null)
                        IconButton(
                          onPressed: () => setSt(() => reminderAt = null),
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white54,
                            size: 18,
                          ),
                          tooltip: 'Clear reminder',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Mood picker
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _moods.map((m) {
                      final active = selectedMood == m['emoji'];
                      return GestureDetector(
                        onTap: () => setSt(() => selectedMood = m['emoji']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF7c3aed)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${m['emoji']} ${m['label']}',
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final content = contentCtrl.text.trim();
                          if (content.isEmpty) return;
                          Navigator.pop(ctx);
                          final noteId = await ApiService.createNote(
                            title: titleCtrl.text.trim(),
                            content: content,
                            mood: selectedMood,
                            reminderAt: reminderAt?.toUtc().toIso8601String(),
                            noteDate: _formatDateOnly(noteDate),
                          );
                          final ok = noteId != null;
                          if (mounted) {
                            setState(() {
                              _selectedDay = DateTime(
                                noteDate.year,
                                noteDate.month,
                                noteDate.day,
                              );
                              _focusedDay = DateTime(
                                noteDate.year,
                                noteDate.month,
                                1,
                              );
                            });
                          }
                          if (ok && noteId.isNotEmpty) {
                            await _syncReminderForNote(
                              noteId: noteId,
                              reminderAt: reminderAt,
                              title: titleCtrl.text.trim(),
                              content: content,
                            );
                          }
                          if (ok) _loadNotes();
                          // ✨ AUTO-STICKER WORKFLOW
                          if (ok && noteId.isNotEmpty) {
                            Future.microtask(() async {
                              try {
                                final stickerUrl =
                                    await ApiService.generateSticker(content);
                                if (stickerUrl.isNotEmpty) {
                                  await ApiService.saveNoteSticker(
                                    noteId,
                                    stickerUrl,
                                  );
                                  final notifTitle =
                                      titleCtrl.text.trim().isNotEmpty
                                      ? titleCtrl.text.trim()
                                      : 'New sticker generated';
                                  final notifBody = content.length > 90
                                      ? '${content.substring(0, 90)}...'
                                      : content;
                                  await NotificationService.showStickerGeneratedNotification(
                                    title: notifTitle,
                                    body: notifBody,
                                    stickerUrl: stickerUrl,
                                  );
                                  await _syncReminderForNote(
                                    noteId: noteId,
                                    reminderAt: reminderAt,
                                    title: titleCtrl.text.trim(),
                                    content: content,
                                    stickerUrl: stickerUrl,
                                  );
                                  if (mounted) {
                                    await _loadNotes();
                                  }
                                }
                              } catch (e) {
                                debugPrint("Auto sticker failed: $e");
                              }
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7c3aed),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
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

  DateTime _noteDay(dynamic note) {
    final reminder = _parseServerDateToLocalDay(note['reminderAt']);
    if (reminder != null) {
      return DateTime(reminder.year, reminder.month, reminder.day);
    }

    final noteDate = _parseCalendarDay(note['noteDate']);
    if (noteDate != null) {
      return DateTime(noteDate.year, noteDate.month, noteDate.day);
    }

    final created = _parseServerDateToLocalDay(note['createdAt']);
    if (created != null) {
      return DateTime(created.year, created.month, created.day);
    }

    return DateTime(2000);
  }

  List<dynamic> get _selectedDayNotes => _notes.where((n) {
    final d = _noteDay(n);
    return d.year == _selectedDay.year &&
        d.month == _selectedDay.month &&
        d.day == _selectedDay.day;
  }).toList();

  Set<int> _daysWithNotes() {
    return _notes
        .map((n) => _noteDay(n))
        .where(
          (d) => d.year == _focusedDay.year && d.month == _focusedDay.month,
        )
        .map((d) => d.day)
        .toSet();
  }

  Map<int, List<_DayStickerPreview>> _dayStickers() {
    final result = <int, List<_DayStickerPreview>>{};

    for (final note in _notes) {
      final noteDay = _noteDay(note);
      if (noteDay.year != _focusedDay.year ||
          noteDay.month != _focusedDay.month) {
        continue;
      }

      final stickerUrl = (note['stickerUrl'] ?? '').toString().trim();
      if (stickerUrl.isEmpty) continue;

      final title = (note['title'] ?? '').toString().trim();
      final content = (note['content'] ?? '').toString().trim();
      final source = title.isNotEmpty ? title : content;
      final noteText = source.isNotEmpty ? source : 'No text';
      var label = source;
      if (label.length > 18) {
        label = '${label.substring(0, 18)}...';
      }
      if (label.isEmpty) {
        label = 'Sticker note';
      }

      final subtitle = _formatTime(
        (note['reminderAt'] ?? '').toString().trim().isNotEmpty
            ? note['reminderAt']
            : note['createdAt'],
      );

      final dayList = result.putIfAbsent(noteDay.day, () => <_DayStickerPreview>[]);
      dayList.add(
        _DayStickerPreview(
          stickerUrl: stickerUrl,
          label: label,
          noteText: noteText,
          subtitle: subtitle,
        ),
      );
    }

    return result;
  }

  List<_DayNotePreview> get _selectedDayPreviews {
    final result = <_DayNotePreview>[];

    for (final note in _selectedDayNotes) {
      final stickerUrl = (note['stickerUrl'] ?? '').toString().trim();
      final title = (note['title'] ?? '').toString().trim();
      final content = (note['content'] ?? '').toString().trim();
      final source = title.isNotEmpty ? title : content;
      final noteText = source.isNotEmpty ? source : 'Untitled note';
      final mood = (note['mood'] ?? '').toString().trim();

      final subtitle = _formatTime(
        (note['reminderAt'] ?? '').toString().trim().isNotEmpty
            ? note['reminderAt']
            : note['createdAt'],
      );

      result.add(
        _DayNotePreview(
          stickerUrl: stickerUrl,
          noteText: noteText,
          subtitle: subtitle,
          mood: mood,
        ),
      );
    }

    return result;
  }

  Future<void> _confirmDeleteNote(dynamic note) async {
    final noteId = (note['_id'] ?? '').toString().trim();
    if (noteId.isEmpty) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF2d1b4e),
        title: const Text('Delete note?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'This note and sticker will be removed from calendar.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Color(0xFFfca5a5))),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final ok = await ApiService.deleteNote(noteId);
    if (!mounted) return;

    if (ok) {
      await _loadNotes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note deleted'),
          backgroundColor: Color(0xFF7c3aed),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Delete failed'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Future<void> _showEditNoteDialog(dynamic note) async {
    final noteId = (note['_id'] ?? '').toString().trim();
    if (noteId.isEmpty) return;

    final titleCtrl = TextEditingController(
      text: (note['title'] ?? '').toString(),
    );
    final contentCtrl = TextEditingController(
      text: (note['content'] ?? '').toString(),
    );
    String selectedMood = (note['mood'] ?? '').toString();
    DateTime noteDate = _noteDay(note);
    DateTime? reminderAt = _parseServerDateTimeLocal(note['reminderAt']);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Dialog(
          backgroundColor: const Color(0xFF2d1b4e),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Note — ${noteDate.day}/${noteDate.month}/${noteDate.year}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Calendar date: ${_formatDateOnly(noteDate)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: noteDate,
                            firstDate: DateTime(DateTime.now().year - 1),
                            lastDate: DateTime(DateTime.now().year + 5),
                          );
                          if (pickedDate == null) return;
                          setSt(() {
                            noteDate = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                            );
                            if (reminderAt != null) {
                              reminderAt = DateTime(
                                noteDate.year,
                                noteDate.month,
                                noteDate.day,
                                reminderAt!.hour,
                                reminderAt!.minute,
                              );
                            }
                          });
                        },
                        child: const Text('Set date',
                            style: TextStyle(color: Color(0xFFc084fc))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Title',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Write your note...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          reminderAt == null
                              ? 'No reminder set'
                              : 'Reminder: ${_formatReminder(reminderAt!)}',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final defaultReminder = DateTime(
                            noteDate.year,
                            noteDate.month,
                            noteDate.day,
                            9,
                            0,
                          );
                          final picked = await _pickReminderDateTime(
                            initial: reminderAt ?? defaultReminder,
                          );
                          if (picked == null) return;
                          setSt(() {
                            reminderAt = picked;
                            noteDate = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                            );
                          });
                        },
                        child: const Text('Set',
                            style: TextStyle(color: Color(0xFFc084fc))),
                      ),
                      if (reminderAt != null)
                        IconButton(
                          onPressed: () => setSt(() => reminderAt = null),
                          icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                          tooltip: 'Clear reminder',
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _moods.map((m) {
                      final active = selectedMood == m['emoji'];
                      return GestureDetector(
                        onTap: () => setSt(() => selectedMood = m['emoji']!),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? const Color(0xFF7c3aed)
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${m['emoji']} ${m['label']}',
                            style: TextStyle(
                              color: active ? Colors.white : Colors.white54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel',
                            style: TextStyle(color: Colors.white54)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final content = contentCtrl.text.trim();
                          if (content.isEmpty) return;

                          final ok = await ApiService.updateNote(
                            noteId,
                            titleCtrl.text.trim(),
                            content,
                            selectedMood,
                            reminderAt: reminderAt?.toUtc().toIso8601String(),
                            noteDate: _formatDateOnly(noteDate),
                          );

                          if (!mounted) return;
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);

                          if (ok) {
                            await _syncReminderForNote(
                              noteId: noteId,
                              reminderAt: reminderAt,
                              title: titleCtrl.text.trim(),
                              content: content,
                              stickerUrl: (note['stickerUrl'] ?? '').toString(),
                            );
                            setState(() {
                              _selectedDay = DateTime(
                                noteDate.year,
                                noteDate.month,
                                noteDate.day,
                              );
                              _focusedDay = DateTime(noteDate.year, noteDate.month, 1);
                            });
                            await _loadNotes();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Note updated'),
                                backgroundColor: Color(0xFF7c3aed),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Update failed'),
                                backgroundColor: Colors.red.shade700,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7c3aed),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Save'),
                      ),
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

  Widget _buildSelectedDayStickerPanel() {
    final previews = _selectedDayPreviews;
    final dayText = '${_selectedDay.day}';
    final monthText = _months[_selectedDay.month - 1].substring(0, 3).toUpperCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7c3aed), Color(0xFFa855f7)],
                  ),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        height: 1,
                      ),
                    ),
                    Text(
                      monthText,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected day notes',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      previews.isEmpty
                          ? 'No notes for this day'
                          : '${previews.length} note${previews.length > 1 ? 's' : ''}',
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (previews.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'No notes on this day',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ),
            )
          else
            SizedBox(
              height: 146,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: previews.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final p = previews[index];
                  final hasSticker = p.stickerUrl.isNotEmpty;
                  return Container(
                    width: 118,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Column(
                      children: [
                        hasSticker
                            ? _StickerThumb(
                                url: p.stickerUrl,
                                size: 64,
                                borderRadius: BorderRadius.circular(32),
                                isCircle: true,
                                fallback: const Icon(
                                  Icons.auto_awesome,
                                  color: Color(0xFFc084fc),
                                  size: 20,
                                ),
                              )
                            : Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white24),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  p.mood.isNotEmpty ? p.mood : '📝',
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                        const SizedBox(height: 6),
                        Text(
                          p.noteText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasSticker ? 'Sticker' : 'Text only',
                          style: const TextStyle(
                            color: Color(0xFFc084fc),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.subtitle,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final daysInMonth = DateTime(
      _focusedDay.year,
      _focusedDay.month + 1,
      0,
    ).day;
    final startWeekday = firstDay.weekday % 7;
    final daysWithNotes = _daysWithNotes();
    final dayStickers = _dayStickers();
    final totalCells = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, color: Colors.white70),
                onPressed: () => setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month - 1,
                  );
                }),
              ),
              Text(
                "${_months[_focusedDay.month - 1]} ${_focusedDay.year}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.7,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Colors.white70),
                onPressed: () => setState(() {
                  _focusedDay = DateTime(
                    _focusedDay.year,
                    _focusedDay.month + 1,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final boardWidth = constraints.maxWidth;
              final isPhone = boardWidth < 420;
              final isCompact = boardWidth < 560;
              final weekdayGap = isPhone ? 3.0 : 6.0;
              final gridGap = isPhone ? 3.0 : 6.0;
              final cellWidth = (boardWidth - (6 * gridGap)) / 7;
              final showLabel = cellWidth >= 54;
              final stickerSize = (cellWidth * (isPhone ? 0.78 : 0.88)).clamp(
                34.0,
                84.0,
              );
              final dayFontSize = isPhone ? 10.0 : 12.0;
              final labelFontSize = isPhone ? 8.0 : 10.0;
              final weekdayFontSize = isPhone ? 8.5 : 11.0;
              final weekdayHeight = isPhone ? 20.0 : 24.0;
              final cellRadius = isPhone ? 4.0 : 6.0;
              final targetCellHeight = showLabel
                  ? (isPhone ? 74.0 : 96.0)
                  : (isPhone ? 62.0 : 82.0);
              final cellAspect = cellWidth / targetCellHeight;

              String weekdayLabel(String value) {
                if (isPhone) return value.substring(0, 1);
                if (isCompact) return value.substring(0, 3);
                return value;
              }

              return Column(
                children: [
                  Row(
                    children: List.generate(_weekdays.length, (i) {
                      final bg = (i == 0 || i == 6)
                          ? const Color(0xFFffcfda)
                          : const Color(0xFFd7efeb);
                      return Expanded(
                        child: Container(
                          height: weekdayHeight,
                          margin: EdgeInsets.only(
                            right: i == _weekdays.length - 1 ? 0 : weekdayGap,
                          ),
                          decoration: BoxDecoration(
                            color: bg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            weekdayLabel(_weekdays[i]),
                            style: TextStyle(
                              color: const Color(0xFF4b5563),
                              fontSize: weekdayFontSize,
                              fontWeight: FontWeight.w700,
                              letterSpacing: isPhone ? 0.6 : 1,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  SizedBox(height: isPhone ? 4 : 6),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      childAspectRatio: cellAspect,
                      mainAxisSpacing: gridGap,
                      crossAxisSpacing: gridGap,
                    ),
                    itemCount: totalCells,
                    itemBuilder: (ctx, i) {
                      final weekDayIndex = i % 7;
                      if (i < startWeekday || i >= startWeekday + daysInMonth) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(cellRadius),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                        );
                      }

                      final day = i - startWeekday + 1;
                      final isToday =
                          day == DateTime.now().day &&
                          _focusedDay.month == DateTime.now().month &&
                          _focusedDay.year == DateTime.now().year;
                      final isSelected =
                          day == _selectedDay.day &&
                          _focusedDay.month == _selectedDay.month &&
                          _focusedDay.year == _selectedDay.year;
                      final hasNote = daysWithNotes.contains(day);
                      final stickers = dayStickers[day] ?? const <_DayStickerPreview>[];
                      final hasSticker = stickers.isNotEmpty;
                      final visibleStickers = stickers.take(3).toList();
                      final label = hasSticker
                          ? (stickers.length > 1
                                ? '${stickers.length} stickers'
                                : stickers.first.label)
                          : '';
                      final stickerShift = isPhone ? 11.0 : 14.0;
                      final stickerThumbSize = (stickerSize *
                              (visibleStickers.length > 1 ? 0.56 : 0.75))
                          .clamp(24.0, 60.0);
                      final stackWidth =
                          stickerThumbSize +
                          ((visibleStickers.length - 1) * stickerShift) +
                          (stickers.length > 3 ? (isPhone ? 18 : 20) : 0);

                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDay = DateTime(
                            _focusedDay.year,
                            _focusedDay.month,
                            day,
                          );
                        }),
                        child: AnimatedScale(
                          duration: const Duration(milliseconds: 140),
                          scale: isSelected ? 1.08 : 1.0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 140),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF3b2b62)
                                  : Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(cellRadius),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFc084fc)
                                    : isToday
                                    ? const Color(0xFF9f7aea)
                                    : const Color(0xFFd1d5db),
                                width: isSelected || isToday ? 1.6 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFa855f7)
                                            .withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        spreadRadius: 0,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    isPhone ? 4 : 6,
                                    isPhone ? 4 : 5,
                                    isPhone ? 4 : 6,
                                    0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      '$day',
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white
                                            : (weekDayIndex == 0 ||
                                                  weekDayIndex == 6)
                                            ? const Color(0xFFc84d7f)
                                            : const Color(0xFF6b7280),
                                        fontSize: dayFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: hasSticker
                                        ? SizedBox(
                                            width: stackWidth,
                                            height: stickerThumbSize + 14,
                                            child: Stack(
                                              clipBehavior: Clip.none,
                                              children: [
                                                for (var idx = 0;
                                                    idx < visibleStickers.length;
                                                    idx++)
                                                  Positioned(
                                                    left: idx * stickerShift,
                                                    top: idx.isEven ? 0 : 4,
                                                    child: Container(
                                                      width: stickerThumbSize,
                                                      height: stickerThumbSize,
                                                      padding:
                                                          const EdgeInsets.all(2),
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: isSelected
                                                            ? Colors.white
                                                                .withValues(
                                                                  alpha: 0.2,
                                                                )
                                                            : const Color(
                                                              0xFFF3E8FF,
                                                            ),
                                                        border: Border.all(
                                                          color: isSelected
                                                              ? const Color(
                                                                0xFFd8b4fe,
                                                              )
                                                              : const Color(
                                                                0xFFE9D5FF,
                                                              ),
                                                        ),
                                                      ),
                                                      child: _StickerThumb(
                                                        url: visibleStickers[idx]
                                                            .stickerUrl,
                                                        size: stickerThumbSize - 4,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              (stickerThumbSize -
                                                                      4) /
                                                                  2,
                                                            ),
                                                        isCircle: true,
                                                        fallback: Icon(
                                                          Icons.auto_awesome,
                                                          color: const Color(
                                                            0xFF7c3aed,
                                                          ),
                                                          size: isPhone ? 14 : 18,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                if (stickers.length > 3)
                                                  Positioned(
                                                    right: 0,
                                                    bottom: -2,
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 5,
                                                            vertical: 2,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFF7c3aed,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Text(
                                                        '+${stickers.length - 3}',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize:
                                                              isPhone ? 8 : 9,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        : hasNote
                                        ? Container(
                                            width: isPhone ? 6 : 8,
                                            height: isPhone ? 6 : 8,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFa855f7),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(
                                                    0xFFa855f7,
                                                  ).withValues(alpha: 0.35),
                                                  blurRadius: 8,
                                                ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                if (showLabel)
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.fromLTRB(
                                      isPhone ? 3 : 6,
                                      0,
                                      isPhone ? 3 : 6,
                                      isPhone ? 4 : 6,
                                    ),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: isSelected
                                            ? Colors.white70
                                            : const Color(0xFF334155),
                                        fontSize: labelFontSize,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
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
        child: Column(
          children: [
            // Top bar
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Calendar",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.nightlight_round, color: Colors.white70),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFc084fc),
                      ),
                    )
                  : RefreshIndicator(
                      color: const Color(0xFFc084fc),
                      onRefresh: _loadNotes,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCalendar(),
                            const SizedBox(height: 16),
                            // Go to Today
                            GestureDetector(
                              onTap: () => setState(() {
                                _focusedDay = DateTime.now();
                                _selectedDay = DateTime.now();
                              }),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF7c3aed),
                                      Color(0xFFa855f7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        "Go to Today",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildSelectedDayStickerPanel(),
                            const SizedBox(height: 16),

                            // ── Notes header ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Notes",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: _showAddNoteDialog,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Color(0xFF7c3aed),
                                          Color(0xFFa855f7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'Add Note',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (_selectedDayNotes.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Center(
                                  child: Text(
                                    "No notes for this day",
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ..._selectedDayNotes.map(
                                (n) => _CalNoteCard(
                                  note: n,
                                  onEdit: () => _showEditNoteDialog(n),
                                  onDelete: () => _confirmDeleteNote(n),
                                ),
                              ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalNoteCard extends StatelessWidget {
  final dynamic note;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CalNoteCard({
    required this.note,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final stickerUrl = (note['stickerUrl'] ?? '').toString().trim();
    final title = (note['title'] ?? '').toString().trim();
    final content = (note['content'] ?? '').toString().trim();
    final displayTitle = title.isNotEmpty ? title : 'Untitled note';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF4c1d95),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    note['mood']?.isNotEmpty == true ? note['mood'] : '📝',
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
                      displayTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(
                        (note['reminderAt'] ?? '').toString().trim().isNotEmpty
                            ? note['reminderAt']
                            : note['createdAt'],
                      ),
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                color: const Color(0xFF2d1b4e),
                icon: const Icon(Icons.more_vert, color: Colors.white70, size: 20),
                onSelected: (value) {
                  if (value == 'edit') {
                    onEdit();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(
                    value: 'edit',
                    child: Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Color(0xFFfca5a5)),
                    ),
                  ),
                ],
              ),
              if (stickerUrl.isNotEmpty) ...[
                const SizedBox(width: 10),
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  child: _StickerThumb(
                    url: stickerUrl,
                    size: 64,
                    borderRadius: BorderRadius.circular(32),
                    isCircle: true,
                    fallback: const Icon(
                      Icons.auto_awesome,
                      color: Color(0xFFc084fc),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (content.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              content,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.35,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String? iso) {
    if (iso == null) return '';
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return '';
    final d = parsed.isUtc ? parsed.toLocal() : parsed;
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return "$h:$m";
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  NotificationService.handleNotificationTapPayload(response.payload);
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  static final StreamController<DateTime> _calendarDayTapController =
      StreamController<DateTime>.broadcast();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sticker_events_channel',
    'Sticker Events',
    description: 'Notifications for generated stickers and reminders',
    importance: Importance.max,
  );

  static bool _initialized = false;
  static int _notificationSeed = 1;
  static DateTime? _pendingCalendarDay;

  static Stream<DateTime> get calendarDayTapStream =>
      _calendarDayTapController.stream;

  static DateTime? consumePendingCalendarDay() {
    final day = _pendingCalendarDay;
    _pendingCalendarDay = null;
    return day;
  }

  static Future<void> init() async {
    if (_initialized) return;

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz_data.initializeTimeZones();

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_channel);
    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    final iosPlugin =
        _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    handleNotificationTapPayload(launchDetails?.notificationResponse?.payload);

    _initialized = true;
  }

  static void _onNotificationResponse(NotificationResponse response) {
    handleNotificationTapPayload(response.payload);
  }

  static void handleNotificationTapPayload(String? payload) {
    final calendarDay = _extractCalendarDay(payload);
    if (calendarDay == null) return;

    _pendingCalendarDay = calendarDay;
    _calendarDayTapController.add(calendarDay);
  }

  static Future<void> showStickerGeneratedNotification({
    required String title,
    required String body,
    String? stickerUrl,
    DateTime? targetDay,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return;

    final details = await _buildDetails(
      title: title,
      body: body,
      stickerUrl: stickerUrl,
    );

    await _plugin.show(
      _nextNotificationId(),
      title,
      body,
      details,
      payload: _buildCalendarPayload(
        day: targetDay ?? DateTime.now(),
      ),
    );
  }

  static Future<void> scheduleReminderNotification({
    required String noteId,
    required DateTime reminderAt,
    required String title,
    required String body,
    String? stickerUrl,
  }) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return;

    final id = _reminderIdForNote(noteId);

    if (!reminderAt.isAfter(DateTime.now())) {
      await _plugin.cancel(id);
      return;
    }

    final details = await _buildDetails(
      title: title,
      body: body,
      stickerUrl: stickerUrl,
    );

    // Use UTC instant to preserve exact user-selected local moment.
    final scheduledAt = tz.TZDateTime.from(reminderAt.toUtc(), tz.UTC);

    await _plugin.cancel(id);
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledAt,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: _buildCalendarPayload(
        day: reminderAt,
        noteId: noteId,
      ),
    );
  }

  static Future<void> cancelScheduledReminderForNote(String noteId) async {
    if (!_initialized) {
      await init();
    }

    if (kIsWeb) return;
    await _plugin.cancel(_reminderIdForNote(noteId));
  }

  static int _reminderIdForNote(String noteId) {
    var hash = 0;
    for (final unit in noteId.codeUnits) {
      hash = ((hash << 5) - hash) + unit;
      hash &= 0x7fffffff;
    }
    const base = 500000000;
    return base + (hash % 500000000);
  }

  static Future<NotificationDetails> _buildDetails({
    required String title,
    required String body,
    String? stickerUrl,
  }) async {
    final imagePath = await _prepareImage(stickerUrl);

    final androidDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: imagePath == null
          ? BigTextStyleInformation(body)
          : BigPictureStyleInformation(
              FilePathAndroidBitmap(imagePath),
              largeIcon: FilePathAndroidBitmap(imagePath),
              contentTitle: title,
              summaryText: body,
            ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      attachments: imagePath == null
          ? null
          : <DarwinNotificationAttachment>[
              DarwinNotificationAttachment(imagePath),
            ],
    );

    return NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  static int _nextNotificationId() {
    _notificationSeed += 1;
    if (_notificationSeed > 400000000) {
      _notificationSeed = 1;
    }
    return _notificationSeed;
  }

  static String _buildCalendarPayload({required DateTime day, String? noteId}) {
    final dateToken = _formatDayToken(day);
    final cleanNoteId = (noteId ?? '').trim();
    if (cleanNoteId.isEmpty) {
      return 'calday:$dateToken';
    }
    return 'calday:$dateToken;note:$cleanNoteId';
  }

  static String _formatDayToken(DateTime value) {
    final local = value.isUtc ? value.toLocal() : value;
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime? _extractCalendarDay(String? payload) {
    final raw = (payload ?? '').trim();
    if (raw.isEmpty) return null;

    final match = RegExp(r'calday:(\d{4}-\d{2}-\d{2})').firstMatch(raw);
    if (match == null) {
      if (raw.startsWith('note:')) {
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day);
      }
      return null;
    }

    final dateText = match.group(1);
    if (dateText == null) return null;
    final parts = dateText.split('-');
    if (parts.length != 3) return null;

    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;

    return DateTime(y, m, d);
  }

  static Future<String?> _prepareImage(String? stickerUrl) async {
    if (stickerUrl == null || stickerUrl.trim().isEmpty) {
      return null;
    }

    final value = stickerUrl.trim();

    Uint8List? bytes;
    String extension = 'png';

    try {
      if (value.startsWith('data:')) {
        final parts = value.split(',');
        if (parts.length < 2) return null;

        final header = parts.first.toLowerCase();
        if (header.contains('image/svg')) return null;

        if (header.contains('image/jpeg')) extension = 'jpg';
        if (header.contains('image/webp')) extension = 'webp';

        bytes = base64Decode(parts.last);
      } else {
        final uri = Uri.tryParse(value);
        if (uri == null) return null;

        final path = uri.path.toLowerCase();
        if (path.endsWith('.svg')) return null;

        final response = await http
            .get(uri)
            .timeout(const Duration(seconds: 12));
        if (response.statusCode < 200 || response.statusCode >= 300) {
          return null;
        }

        final type = (response.headers['content-type'] ?? '').toLowerCase();
        if (type.contains('svg')) return null;
        if (type.contains('jpeg') || type.contains('jpg')) extension = 'jpg';
        if (type.contains('webp')) extension = 'webp';

        bytes = response.bodyBytes;
      }
    } catch (_) {
      return null;
    }

    if (bytes.isEmpty) {
      return null;
    }

    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/sticker_notif_${DateTime.now().millisecondsSinceEpoch}.$extension',
      );
      await file.writeAsBytes(bytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

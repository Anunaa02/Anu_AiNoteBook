import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'sticker_events_channel',
    'Sticker Events',
    description: 'Notifications for generated stickers and reminders',
    importance: Importance.max,
  );

  static bool _initialized = false;
  static int _notificationSeed = 1;

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

    await _plugin.initialize(initSettings);

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

    _initialized = true;
  }

  static Future<void> showStickerGeneratedNotification({
    required String title,
    required String body,
    String? stickerUrl,
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
      payload: 'note:$noteId',
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

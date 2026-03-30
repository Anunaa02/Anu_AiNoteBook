import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {

  // ── Change this if testing on a real device (use your PC LAN IP) ──
  static const String _devHost = '192.168.1.9';

  static String get _base {
    if (kIsWeb) return 'http://localhost:3000/api';
    if (Platform.isAndroid) {
      return 'http://$_devHost:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // ───── AUTH ─────────────────────────────────────

  static Future<Map<String, dynamic>> login(
      String email, String password) async {

    try {
      final res = await http.post(
        Uri.parse("$_base/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body);

    } catch (e) {
      return {"message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {

    try {
      final res = await http.post(
        Uri.parse("$_base/auth/signup"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password
        }),
      ).timeout(const Duration(seconds: 10));

      return jsonDecode(res.body);

    } catch (e) {
      return {"message": "Connection error: $e"};
    }
  }

  // ───── NOTES ─────────────────────────────────────

  static Future<List<dynamic>> getNotes() async {

    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return [];

    try {
      final res = await http.get(
        Uri.parse("$_base/notes"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        return jsonDecode(res.body)["notes"] ?? [];
      }

    } catch (_) {}

    return [];
  }

  static Future<bool> createNote({
    required String content,
    String title = "",
    String mood = "",
    String? reminderAt
  }) async {

    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;

    final body = {
      "title": title,
      "content": content,
      "mood": mood
    };

    if (reminderAt != null) {
      body["reminderAt"] = reminderAt;
    }

    try {
      final res = await http.post(
        Uri.parse("$_base/notes"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 201;

    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteNote(String id) async {

    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;

    try {
      final res = await http.delete(
        Uri.parse("$_base/notes/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;

    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateNote(
      String id,
      String title,
      String content,
      String mood) async {

    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;

    try {
      final res = await http.put(
        Uri.parse("$_base/notes/$id"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "title": title,
          "content": content,
          "mood": mood
        }),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;

    } catch (_) {
      return false;
    }
  }

  static Future<bool> saveNoteSticker(String noteId, String stickerUrl) async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;

    try {
      final res = await http.patch(
        Uri.parse("$_base/notes/$noteId/sticker"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"stickerUrl": stickerUrl}),
      ).timeout(const Duration(seconds: 10));

      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ───── AI STICKER GENERATOR ─────────────────────

  /// Generates a sticker using OpenAI DALL-E API
  /// Returns a data:image/png;base64,... URI or image URL.
  static Future<String> generateSticker(String prompt) async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) {
      throw Exception("Authentication required");
    }

    try {
      print("🎨 Sending prompt to backend: $prompt");
      
      final res = await http.post(
        Uri.parse("$_base/notes/generate-sticker"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"prompt": prompt}),
      ).timeout(const Duration(minutes: 5));

      final data = jsonDecode(res.body);

      if (res.statusCode != 200) {
        throw Exception(data["message"] ?? "Server error ${res.statusCode}");
      }

      final stickerUrl = data["stickerUrl"] as String?;
      if (stickerUrl == null || stickerUrl.isEmpty) {
        throw Exception("No image returned from server");
      }

      print("✅ Sticker generated successfully");
      return stickerUrl;
    } on http.ClientException catch (e) {
      throw Exception("Network error: ${e.message}");
    } on FormatException {
      throw Exception("Invalid response from server");
    } catch (e) {
      throw Exception("Generation failed: ${e.toString()}");
    }
  }

  // ───── STORAGE HELPERS ─────────────────────────

  static Future<void> saveToken(String token) =>
      _storage.write(key: "jwt", value: token);

  static Future<void> saveUser(String name, String email) async {

    await _storage.write(key: "user_name", value: name);
    await _storage.write(key: "user_email", value: email);

  }

  static Future<String> getUserName() async =>
      (await _storage.read(key: "user_name")) ?? "User";

  static Future<String> getUserEmail() async =>
      (await _storage.read(key: "user_email")) ?? "";

  static Future<void> logout() async => _storage.deleteAll();

}
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Android emulator routes localhost → 10.0.2.2 (host machine)
  static String get _base {
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:5000/api';
    return 'http://localhost:5000/api';
  }
  static final FlutterSecureStorage _storage = FlutterSecureStorage();

  // ─── Auth ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse("$_base/auth/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {"message": "Connection error: $e"};
    }
  }

  static Future<Map<String, dynamic>> signup(
      String name, String email, String password) async {
    try {
      final res = await http
          .post(
            Uri.parse("$_base/auth/signup"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"name": name, "email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 10));
      return jsonDecode(res.body);
    } catch (e) {
      return {"message": "Connection error: $e"};
    }
  }

  // ─── Notes ───────────────────────────────────────────────────
  static Future<List<dynamic>> getNotes() async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return [];
    try {
      final res = await http
          .get(
            Uri.parse("$_base/notes"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return jsonDecode(res.body)["notes"] ?? [];
      }
    } catch (_) {}
    return [];
  }

  static Future<bool> createNote(
      {required String content,
      String title = "",
      String mood = "",
      String? reminderAt}) async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;
    final body = <String, dynamic>{
      "title": title,
      "content": content,
      "mood": mood,
    };
    if (reminderAt != null) body["reminderAt"] = reminderAt;

    try {
      final res = await http
          .post(
            Uri.parse("$_base/notes"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> deleteNote(String id) async {
    final token = await _storage.read(key: "jwt");
    if (token == null || token.isEmpty) return false;
    try {
      final res = await http
          .delete(
            Uri.parse("$_base/notes/$id"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
          )
          .timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> updateNote(
      String id, String title, String content, String mood) async {
    final token = await _storage.read(key: "jwt");
    final res = await http.put(
      Uri.parse("$_base/notes/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({"title": title, "content": content, "mood": mood}),
    );
    return res.statusCode == 200;
  }

  // ─── Storage helpers ─────────────────────────────────────────
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

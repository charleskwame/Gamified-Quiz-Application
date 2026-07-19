import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/guest_user.dart';

class LocalProgressService {
  static const String _guestUserKey = 'guest_user';
  static const String _guestProgressKey = 'guest_progress';

  static Future<void> saveGuestUser(GuestUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_guestUserKey, jsonEncode(user.toJson()));
  }

  static Future<GuestUser?> loadGuestUser() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_guestUserKey);
    if (jsonStr == null) return null;
    try {
      return GuestUser.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  static Future<List<GuestProgress>> getAllProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_guestProgressKey);
    if (list == null) return [];
    return list.map((item) {
      return GuestProgress.fromJson(jsonDecode(item) as Map<String, dynamic>);
    }).toList();
  }

  static Future<void> addProgress(GuestProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getAllProgress();
    current.add(progress);
    final stringList = current.map((item) => jsonEncode(item.toJson())).toList();
    await prefs.setStringList(_guestProgressKey, stringList);
  }

  static Future<void> clearProgress() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestProgressKey);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_guestUserKey);
    await prefs.remove(_guestProgressKey);
  }
}

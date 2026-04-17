import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _sessionKey = "session_id";
  static const _tableKey = "table_id";

  Future<void> saveSession(String sessionId, String tableId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, sessionId);
    await prefs.setString(_tableKey, tableId);
  }

  Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      "session_id": prefs.getString(_sessionKey),
      "table_id": prefs.getString(_tableKey),
    };
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    await prefs.remove(_tableKey);
  }
}
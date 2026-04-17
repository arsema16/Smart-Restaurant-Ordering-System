import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://YOUR_BACKEND_URL";

  Future<Map<String, dynamic>> startSession(String tableId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/session/start"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"table_id": tableId}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to start session");
    }
  }
}
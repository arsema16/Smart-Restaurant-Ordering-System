import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // ✅ FIX: baseUrl must be inside the class
  final String baseUrl = "http://127.0.0.1:8000";

  // START SESSION
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

  // FETCH MENU
  Future<List<dynamic>> fetchMenu() async {
    final response = await http.get(
      Uri.parse("$baseUrl/menu"),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to load menu");
    }
  }

  // ✅ CREATE ORDER (THIS IS WHERE YOUR ERROR WAS)
  Future<Map<String, dynamic>> createOrder(
    String sessionId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/order"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "session_id": sessionId,
        "items": items,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to create order");
    }
  }

Future<Map<String, dynamic>> getOrder(String orderId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/order/$orderId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to fetch order");
  }
}
Future<List<dynamic>> getRecommendations(String sessionId) async {
  final response = await http.get(
    Uri.parse("$baseUrl/recommend/$sessionId"),
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body);
  } else {
    throw Exception("Failed to load recommendations");
  }
}}
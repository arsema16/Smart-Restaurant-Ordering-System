import '../services/api_service.dart';
import '../models/session_model.dart';

class SessionRepository {
  final ApiService _api;

  SessionRepository(this._api);

  /// Create or resume a session
  Future<SessionCreateResponse> createSession(SessionCreateRequest request) async {
    final response = await _api.post('/sessions', data: request.toJson());
    return SessionCreateResponse.fromJson(response.data);
  }

  /// Get full session state
  Future<SessionStateResponse> getSessionState(String sessionId) async {
    final response = await _api.get('/sessions/$sessionId');
    return SessionStateResponse.fromJson(response.data);
  }
}
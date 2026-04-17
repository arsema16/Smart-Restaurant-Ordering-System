import '../core/services/api_service.dart';
import '../models/session_model.dart';

class SessionRepository {
  final ApiService api;

  SessionRepository(this.api);

  Future<SessionModel> createSession(String tableId) async {
    final data = await api.startSession(tableId);
    return SessionModel.fromJson(data);
  }
}
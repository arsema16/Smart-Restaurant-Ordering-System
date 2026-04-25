import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import 'api_provider.dart';

/// Session state notifier
class SessionNotifier extends StateNotifier<SessionCreateResponse?> {
  final SessionRepository _repository;

  SessionNotifier(this._repository) : super(null);

  /// Create or resume session from QR code scan
  Future<void> createSession(String tableIdentifier) async {
    try {
      // Get or create persistent user ID
      final prefs = await SharedPreferences.getInstance();
      String? persistentUserId = prefs.getString('persistent_user_id');
      
      if (persistentUserId == null) {
        persistentUserId = const Uuid().v4();
        await prefs.setString('persistent_user_id', persistentUserId);
      }

      // Check if we have an existing session token
      final existingToken = prefs.getString('session_token');

      // Create session request
      final request = SessionCreateRequest(
        tableIdentifier: tableIdentifier,
        sessionToken: existingToken,
        persistentUserId: persistentUserId,
      );

      // Call API to create/resume session
      final response = await _repository.createSession(request);

      // Store session token
      await prefs.setString('session_token', response.sessionToken);
      await prefs.setString('session_id', response.sessionId);
      await prefs.setString('table_identifier', response.tableIdentifier);

      // Update state
      state = response;
    } catch (e) {
      rethrow;
    }
  }

  /// Resume session from stored token
  Future<void> resumeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('session_token');
      final sessionId = prefs.getString('session_id');
      final tableIdentifier = prefs.getString('table_identifier');

      if (sessionToken != null && sessionId != null && tableIdentifier != null) {
        state = SessionCreateResponse(
          sessionId: sessionId,
          sessionToken: sessionToken,
          tableIdentifier: tableIdentifier,
          isNew: false,
        );
      }
    } catch (e) {
      // Ignore errors during resume
    }
  }

  /// Clear session
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('session_id');
    await prefs.remove('table_identifier');
    state = null;
  }

  /// Check if session exists
  bool get hasSession => state != null;

  /// Get session ID
  String? get sessionId => state?.sessionId;

  /// Get session token
  String? get sessionToken => state?.sessionToken;

  /// Get table identifier
  String? get tableIdentifier => state?.tableIdentifier;
}

final sessionProvider = StateNotifierProvider<SessionNotifier, SessionCreateResponse?>((ref) {
  final repository = ref.watch(sessionRepositoryProvider);
  return SessionNotifier(repository);
});
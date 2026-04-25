import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';

/// Session state notifier
class SessionNotifier extends StateNotifier<SessionCreateResponse?> {
  SessionNotifier() : super(null);

  /// Update session with response from API
  void updateSession(SessionCreateResponse session) {
    state = session;
  }

  /// Clear session
  void clearSession() {
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
  return SessionNotifier();
});
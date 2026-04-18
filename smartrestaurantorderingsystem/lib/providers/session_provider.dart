import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../repositories/session_repository.dart';
import '../core/services/api_service.dart';
import '../core/services/storage_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final storageServiceProvider = Provider((ref) => StorageService());

final sessionRepositoryProvider = Provider((ref) {
  final api = ref.watch(apiServiceProvider);
  return SessionRepository(api);
});

class SessionNotifier extends StateNotifier<AsyncValue<SessionModel?>> {
  final SessionRepository repo;
  final StorageService storage;

  SessionNotifier(this.repo, this.storage) : super(const AsyncLoading()) {
    loadSession();
  }

  /// Load existing session from local storage
  Future<void> loadSession() async {
    try {
      final data = await storage.getSession();
      final sessionId = data["session_id"];
      final tableId = data["table_id"];

      if (sessionId != null && tableId != null) {
        state = AsyncData(
          SessionModel(sessionId: sessionId, tableId: tableId),
        );
      } else {
        state = const AsyncData(null);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Create new session (after QR scan)
  Future<void> createSession(String tableId) async {
  state = const AsyncLoading();

  try {
    final data = await repo.startSession(tableId);

    final sessionId = data['session_id'];
    final tableIdFromApi = data['table_id'];

    final session = SessionModel(
      sessionId: sessionId,
      tableId: tableIdFromApi,
    );

    // ✅ FIXED HERE
    await storage.saveSession(sessionId, tableIdFromApi);

    state = AsyncData(session);

  } catch (e, st) {
    state = AsyncError(e, st);
  }
}

  /// Clear session (optional)
  Future<void> clearSession() async {
    await storage.clearSession();
    state = const AsyncData(null);
  }
}

final sessionProvider =
    StateNotifierProvider<SessionNotifier, AsyncValue<SessionModel?>>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  final storage = ref.watch(storageServiceProvider);

  return SessionNotifier(repo, storage);
});
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/websocket_service.dart';
import '../core/constants/api_constants.dart';

/// Provider for WebSocket service
final websocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService(baseUrl: ApiConstants.baseUrl);
  ref.onDispose(() {
    service.dispose();
  });
  return service;
});

/// Provider for WebSocket event stream
final websocketEventStreamProvider = StreamProvider((ref) {
  final service = ref.watch(websocketServiceProvider);
  return service.eventStream;
});

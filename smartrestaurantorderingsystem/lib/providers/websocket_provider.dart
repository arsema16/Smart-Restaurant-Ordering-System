import 'package:flutter_riverpod/flutter_riverpod.dart';

class WebSocketState {
  final bool isConnected;
  WebSocketState({this.isConnected = false});
}

class WebSocketNotifier extends StateNotifier<WebSocketState> {
  WebSocketNotifier() : super(WebSocketState());

  Future<void> connectGuest() async {}
  Future<void> connectStaff() async {}
  Future<void> disconnect() async {}
}

final websocketProvider =
    StateNotifierProvider<WebSocketNotifier, WebSocketState>(
        (ref) => WebSocketNotifier());

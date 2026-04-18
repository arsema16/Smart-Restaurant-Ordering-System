import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../qr/qr_scanner_screen.dart';
import '../menu/menu_screen.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {

    // ✅ Correct place for listen
    ref.listen(sessionProvider, (previous, next) {
      next.when(
        data: (session) {
          if (session != null) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MenuScreen()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const QRScannerScreen()),
            );
          }
        },
        loading: () {},
        error: (_, __) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const QRScannerScreen()),
          );
        },
      );
    });

    final sessionState = ref.watch(sessionProvider);

    return Scaffold(
      body: Center(
        child: sessionState.when(
          data: (_) => const Text("Redirecting..."),
          loading: () => const CircularProgressIndicator(),
          error: (e, _) => Text("Error: $e"),
        ),
      ),
    );
  }
}
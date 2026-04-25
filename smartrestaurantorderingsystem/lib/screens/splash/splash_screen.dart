import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/session_provider.dart';
import '../menu/menu_screen.dart';
import '../welcome/welcome_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  final String? tableIdentifier;

  const SplashScreen({super.key, this.tableIdentifier});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    try {
      // If table identifier is provided (from QR code URL), create new session
      if (widget.tableIdentifier != null && widget.tableIdentifier!.isNotEmpty) {
        await ref.read(sessionProvider.notifier).createSession(widget.tableIdentifier!);
      } else {
        // Otherwise, try to resume existing session
        await ref.read(sessionProvider.notifier).resumeSession();
      }
      
      // Wait a bit for the UI
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final session = ref.read(sessionProvider);
      
      if (session != null) {
        // Has session, go to menu
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MenuScreen()),
        );
      } else {
        // No session and no table ID, show welcome screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // On error, show welcome screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant,
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 24),
            const Text(
              'Smart Restaurant',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 48),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

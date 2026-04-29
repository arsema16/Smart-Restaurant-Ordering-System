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
      if (widget.tableIdentifier != null && widget.tableIdentifier!.isNotEmpty) {
        print('Creating session for table: ${widget.tableIdentifier}');
        await ref.read(sessionProvider.notifier).createSession(widget.tableIdentifier!);
        print('Session created successfully');
      } else {
        print('Attempting to resume session');
        await ref.read(sessionProvider.notifier).resumeSession();
      }
    } catch (e) {
      print('Session error (ignored): $e');
      // Even if session fails, try to create a default one
      try {
        await ref.read(sessionProvider.notifier).createSession(
          widget.tableIdentifier ?? 'table-1',
        );
      } catch (e2) {
        print('Default session error (ignored): $e2');
      }
    }

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    final session = ref.read(sessionProvider);
    print('Session state after init: $session');

    if (session != null) {
      print('Going to menu');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } else if (widget.tableIdentifier != null && widget.tableIdentifier!.isNotEmpty) {
      // We had a table ID from QR scan but session failed — go to menu anyway
      // The menu will show an error if the backend is unreachable
      print('Session null but table ID present — going to menu anyway');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MenuScreen()),
      );
    } else {
      print('No session, no table ID — showing welcome screen');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE65100), Color(0xFFBF360C)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.restaurant,
                  size: 64,
                  color: Color(0xFFE65100),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Habesha Bites',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authentic Ethiopian Cuisine',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 60),
              const SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import 'onboarding_screen.dart';
import 'shell.dart';

/// App khulte hi chhota sa animated logo, phir sahi screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      final next = AppState.onboarded ? const AppShell() : const OnboardingScreen();
      Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 450),
        pageBuilder: (_, _, _) => next,
        transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
      ));
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = CurvedAnimation(parent: _c, curve: Curves.easeOutBack);
    final fade = CurvedAnimation(parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOut));
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween(begin: 0.6, end: 1.0).animate(scale),
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2B3A67), Color(0xFF141B2E)],
                  ),
                  boxShadow: [BoxShadow(color: C.brand.withValues(alpha: 0.35), blurRadius: 40)],
                ),
                child: const Icon(Icons.shield_rounded, size: 64, color: C.safe),
              ),
            ),
            const SizedBox(height: Sp.xl),
            FadeTransition(
              opacity: fade,
              child: Column(
                children: [
                  Text('Ghar Alert', style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 4),
                  Text(tr('tagline'), style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_colors.dart';
import 'auth/auth_gate.dart';
import 'onboarding_screen.dart';

/// Layar pembuka: menentukan apakah onboarding perlu ditampilkan.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _decideNextScreen();
  }

  Future<void> _decideNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    bool seenOnboarding = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      seenOnboarding = prefs.getBool('onboarding_done') ?? false;
    } catch (_) {
      seenOnboarding = false;
    }
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            seenOnboarding ? const AuthGate() : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 50,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'SAPA Alumni',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Sistem Aplikasi Pelayanan Alumni',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 34),
            const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                valueColor: AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

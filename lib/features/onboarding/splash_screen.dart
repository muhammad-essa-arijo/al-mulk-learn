import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../home/home_screen.dart';
import '../settings/settings_controller.dart';
import 'onboarding_screen.dart';

/// Logo + surah name for about 2 seconds, then go to onboarding or home.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (!mounted) return;
      final done = context.read<SettingsController>().onboardingDone;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (_) => done ? const HomeScreen() : const OnboardingScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOut,
          builder: (context, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: 0.8 + 0.2 * v, child: child)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                  color: c.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.secondary, width: 4)),
              child: Icon(Icons.menu_book_rounded, size: 56, color: c.onPrimary),
            ),
            const SizedBox(height: 20),
            const Text('سُورَةُ الْمُلْكِ',
                style: TextStyle(fontFamily: 'AmiriQuran', fontSize: 38, height: 1.8)),
            Text('Al-Mulk Learn',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: c.primary, fontWeight: FontWeight.w600)),
          ]),
        ),
      ),
    );
  }
}

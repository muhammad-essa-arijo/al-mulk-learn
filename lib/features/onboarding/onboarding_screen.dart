import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../home/home_screen.dart';
import '../settings/settings_controller.dart';

/// 3 short pages: what the app does, offline promise, level + daily goal.
/// [fromSettings] = true when re-opened from Settings (then we just go back).
class OnboardingScreen extends StatefulWidget {
  final bool fromSettings;
  const OnboardingScreen({super.key, this.fromSettings = false});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  late String _level;
  late int _goal;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsController>();
    _level = s.level;
    _goal = s.dailyGoal;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    // Save the choices and remember onboarding is done.
    context.read<SettingsController>().update(() {
      final s = context.read<SettingsController>();
      s.level = _level;
      s.dailyGoal = _goal;
      s.onboardingDone = true;
    });
    if (widget.fromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    }
  }

  void _next() {
    if (_page == 2) {
      _finish();
    } else {
      _controller.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    }
  }

  Widget _info(IconData icon, String title, String body) {
    final c = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        CircleAvatar(
            radius: 54,
            backgroundColor: c.primary.withValues(alpha: 0.12),
            child: Icon(icon, size: 56, color: c.primary)),
        const SizedBox(height: 28),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        Text(body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge),
      ]),
    );
  }

  Widget _choices() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text(context.tr('ob3Title'),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(context.tr('ob3Body')),
        const SizedBox(height: 24),
        Text(context.tr('level'), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(value: 'beginner', label: Text(context.tr('beginner'))),
            ButtonSegment(
                value: 'intermediate', label: Text(context.tr('intermediate'))),
          ],
          selected: {_level},
          onSelectionChanged: (v) => setState(() => _level = v.first),
        ),
        const SizedBox(height: 24),
        Text(context.tr('dailyGoal'),
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 5, label: Text('5')),
            ButtonSegment(value: 10, label: Text('10')),
            ButtonSegment(value: 20, label: Text('20')),
          ],
          selected: {_goal},
          onSelectionChanged: (v) => setState(() => _goal = v.first),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: PageView(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _info(Icons.menu_book_rounded, context.tr('ob1Title'),
                    context.tr('ob1Body')),
                _info(Icons.wifi_off_rounded, context.tr('ob2Title'),
                    context.tr('ob2Body')),
                _choices(),
              ],
            ),
          ),
          // Dots show which page we are on.
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < 3; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.all(4),
                width: _page == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                    color: _page == i ? c.primary : c.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4)),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: _next,
                  child: Text(context.tr(_page == 2 ? 'start' : 'next'))),
            ),
          ),
        ]),
      ),
    );
  }
}

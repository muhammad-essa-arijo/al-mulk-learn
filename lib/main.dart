import 'dart:async';
import 'package:flutter/foundation.dart' show LicenseEntryWithLineBreaks, LicenseRegistry;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'app/app_theme.dart';
import 'data/quran_repository.dart';
import 'data/user_data_store.dart';
import 'features/achievements/achievements_controller.dart';
import 'features/achievements/badges.dart';
import 'features/audio/audio_controller.dart';
import 'features/audio/mini_player.dart';
import 'features/common/library_controller.dart';
import 'features/common/practice_controller.dart';
import 'features/common/progress_controller.dart';
import 'features/onboarding/splash_screen.dart';
import 'features/settings/settings_controller.dart';

/// Entry point. Any error while starting is caught and shown on screen,
/// so the phone never stays stuck on a blank screen without a reason.
void main() {
  // If a screen fails to draw, show the error text instead of a grey box.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFFBF6E9),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Text('Error:\n${details.exceptionAsString()}',
                style: const TextStyle(color: Color(0xFF8B1A1A), fontSize: 14)),
          ),
        ),
      );
  runZonedGuarded(_start, (error, stack) {
    runApp(_StartupError('$error\n\n$stack'));
  });
}

/// Simple screen that prints the startup error (cream background, selectable).
class _StartupError extends StatelessWidget {
  final String message;
  const _StartupError(this.message);
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: const Color(0xFFFBF6E9),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: SelectableText('Startup error:\n\n$message',
                  style: const TextStyle(color: Color(0xFF8B1A1A), fontSize: 13)),
            ),
          ),
        ),
      );
}

Future<void> _start() async {
  WidgetsFlutterBinding.ensureInitialized();

  // A short note about the bundled fonts for Flutter's license page.
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['Amiri Quran', 'Noto Nastaliq Urdu', 'Inter'],
      'These fonts are licensed under the SIL Open Font License, Version 1.1.\n'
      'See https://openfontlicense.org for the full text.',
    );
  });

  // Load everything before the first screen (all from the app bundle).
  final repo = await QuranRepository.load();
  final store = await UserDataStore.open();
  runApp(MultiProvider(
    providers: [
      Provider<QuranRepository>.value(value: repo),
      Provider<UserDataStore>.value(value: store),
      ChangeNotifierProvider(create: (_) => SettingsController(store)),
      ChangeNotifierProvider(create: (_) => ProgressController(store)),
      ChangeNotifierProvider(create: (_) => LibraryController(store)),
      ChangeNotifierProvider(create: (_) => PracticeController(store)),
      // lazy: false = start watching right away, so badges unlock on time.
      ChangeNotifierProvider(
        lazy: false,
        create: (ctx) => AchievementsController(
          store,
          ctx.read<ProgressController>(),
          ctx.read<LibraryController>(),
          ctx.read<PracticeController>(),
          repo.ayahs.length,
        ),
      ),
      ChangeNotifierProvider(
          create: (ctx) => AudioController(ctx.read<SettingsController>(), repo)),
    ],
    child: const AlMulkApp(),
  ));
}

class AlMulkApp extends StatefulWidget {
  const AlMulkApp({super.key});
  @override
  State<AlMulkApp> createState() => _AlMulkAppState();
}

class _AlMulkAppState extends State<AlMulkApp> with WidgetsBindingObserver {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  Timer? _timer;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Count "time spent" only while the app is open on screen.
    _timer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_foreground) context.read<ProgressController>().addSeconds(15);
    });
    context.read<AchievementsController>().onUnlock = _showBadge;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  /// Small pop-up when a new badge is earned.
  void _showBadge(AppBadge b) {
    final lang = context.read<SettingsController>().uiLang;
    _messengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        content: Row(children: [
          Icon(b.icon, color: const Color(0xFFC9A24B)),
          const SizedBox(width: 12),
          Expanded(
            child: Text('${lang == 'ur' ? 'بیج حاصل ہوا!' : 'Badge unlocked!'}  ${b.title(lang)}'),
          ),
        ]),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final urdu = s.uiLang == 'ur';
    return MaterialApp(
      title: 'Al-Mulk Learn',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: _messengerKey,
      theme: AppTheme.of(s.themeKind, font: urdu ? 'NotoNastaliqUrdu' : 'Inter'),
      // Setting the locale to Urdu flips the whole layout to right-to-left.
      locale: Locale(s.uiLang),
      supportedLocales: const [Locale('en'), Locale('ur')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // The mini-player lives here so it stays at the bottom on every screen.
      builder: (context, child) {
        final showing = context.watch<AudioController>().currentAyah != null;
        return Column(children: [
          Expanded(
            child: showing
                ? MediaQuery.removePadding(
                    context: context, removeBottom: true, child: child!)
                : child!,
          ),
          const MiniPlayer(),
        ]);
      },
      home: const SplashScreen(),
    );
  }
}

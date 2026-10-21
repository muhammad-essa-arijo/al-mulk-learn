import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/app_theme.dart';
import '../../core/backup_service.dart';
import '../../core/notification_service.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../../data/user_data_store.dart';
import '../achievements/achievements_controller.dart';
import '../common/library_controller.dart';
import '../common/practice_controller.dart';
import '../common/progress_controller.dart';
import '../credits/credits_screen.dart';
import '../onboarding/onboarding_screen.dart';
import 'settings_controller.dart';

/// All settings, in simple sections.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _langNames = {'en': 'English', 'ur': 'اردو', 'sd': 'سنڌي'};

  Widget _title(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 6),
        child: Text(text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w700)),
      );

  void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  // ---------- reminders ----------
  Future<void> _setReminder(BuildContext context, SettingsController s, bool on) async {
    if (!on) {
      await NotificationService.cancel();
      s.update(() => s.reminderEnabled = false);
      return;
    }
    final ok = await NotificationService.enableDaily(
      TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
      title: 'Al-Mulk Learn',
      body: s.uiLang == 'ur'
          ? 'سورۃ الملک کی روزانہ مشق کا وقت ہو گیا ہے۔'
          : 'Time for your daily Surah Al-Mulk practice.',
    );
    if (!context.mounted) return;
    if (ok) {
      s.update(() => s.reminderEnabled = true);
      _snack(context, context.tr('reminderOn'));
    } else {
      _snack(context, context.tr('reminderDenied'));
    }
  }

  Future<void> _pickTime(BuildContext context, SettingsController s) async {
    final t = await showTimePicker(
        context: context, initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute));
    if (t == null || !context.mounted) return;
    s.update(() {
      s.reminderHour = t.hour;
      s.reminderMinute = t.minute;
    });
    if (s.reminderEnabled) await _setReminder(context, s, true); // reschedule
  }

  // ---------- backup / restore ----------
  Future<void> _backup(BuildContext context) async {
    final store = context.read<UserDataStore>();
    final text = BackupService.export(store);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(title: Text(context.tr('backup')), children: [
        if (!kIsWeb)
          SimpleDialogOption(
            child: Text(context.tr('backupShare')),
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await SharePlus.instance.share(ShareParams(files: [
                  XFile.fromData(utf8.encode(text),
                      mimeType: 'application/json', name: 'al_mulk_backup.json')
                ]));
              } catch (_) {
                if (context.mounted) _snack(context, context.tr('shareFailed'));
              }
            },
          ),
        SimpleDialogOption(
          child: Text(context.tr('backupCopy')),
          onPressed: () async {
            Navigator.pop(dialogContext);
            await Clipboard.setData(ClipboardData(text: text));
            if (context.mounted) _snack(context, context.tr('copied'));
          },
        ),
      ]),
    );
  }

  Future<void> _finishRestore(BuildContext context, String text) async {
    final store = context.read<UserDataStore>();
    final settings = context.read<SettingsController>();
    final progress = context.read<ProgressController>();
    final library = context.read<LibraryController>();
    final practice = context.read<PracticeController>();
    final ach = context.read<AchievementsController>();
    final ok = await BackupService.restore(store, text);
    if (!context.mounted) return;
    if (ok) {
      // Re-read everything so the screens show the restored data.
      settings.reload();
      progress.reload();
      library.reload();
      practice.reload();
      ach.reload();
      _snack(context, context.tr('restoreDone'));
    } else {
      _snack(context, context.tr('restoreBad'));
    }
  }

  Future<void> _restore(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => SimpleDialog(title: Text(context.tr('restore')), children: [
        SimpleDialogOption(
          child: Text(context.tr('chooseFile')),
          onPressed: () async {
            Navigator.pop(dialogContext);
            final res = await FilePicker.platform
                .pickFiles(type: FileType.custom, allowedExtensions: ['json'], withData: true);
            final bytes = res?.files.first.bytes;
            if (bytes == null || !context.mounted) return;
            await _finishRestore(context, utf8.decode(bytes, allowMalformed: true));
          },
        ),
        SimpleDialogOption(
          child: Text(context.tr('pasteText')),
          onPressed: () async {
            Navigator.pop(dialogContext);
            final c = TextEditingController();
            final text = await showDialog<String>(
              context: context,
              builder: (d) => AlertDialog(
                title: Text(context.tr('pasteText')),
                content: TextField(controller: c, maxLines: 6, autofocus: true),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(d), child: Text(context.tr('cancel'))),
                  FilledButton(onPressed: () => Navigator.pop(d, c.text), child: Text(context.tr('restore'))),
                ],
              ),
            );
            if (text == null || !context.mounted) return;
            await _finishRestore(context, text);
          },
        ),
      ]),
    );
  }

  Future<void> _reset(BuildContext context) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (d) => AlertDialog(
        title: Text(context.tr('resetProgress')),
        content: Text(context.tr('resetWarn')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(d, false), child: Text(context.tr('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(d, true), child: Text(context.tr('resetProgress'))),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    context.read<ProgressController>().reset();
    context.read<PracticeController>().reset();
    context.read<AchievementsController>().reset();
    _snack(context, context.tr('resetDone'));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    final repo = context.read<QuranRepository>();
    final themeNames = {
      AppThemeKind.light: context.tr('light'),
      AppThemeKind.sepia: context.tr('sepia'),
      AppThemeKind.softBlue: context.tr('softBlue'),
      AppThemeKind.dark: context.tr('dark'),
    };
    final langs = repo.translationLanguages.toList()..sort();

    Widget slider(String label, double v, double min, double max, ValueChanged<double> f) =>
        Row(children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Slider(value: v, min: min, max: max, onChanged: f)),
        ]);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 32), children: [
        // ---- Appearance
        _title(context, context.tr('theme')),
        Wrap(spacing: 8, children: [
          for (final k in AppThemeKind.values)
            ChoiceChip(
              label: Text(themeNames[k]!),
              selected: s.themeKind == k,
              onSelected: (_) => s.update(() => s.themeKind = k),
            ),
        ]),

        // ---- Language
        _title(context, context.tr('language')),
        RadioGroup<String>(
          groupValue: s.uiLang,
          onChanged: (v) => s.update(() => s.uiLang = v ?? 'en'),
          child: Column(children: [
            const RadioListTile<String>(title: Text('English'), value: 'en'),
            const RadioListTile<String>(title: Text('اردو'), value: 'ur'),
            RadioListTile<String>(title: Text(context.tr('sindhiSoon')), value: 'sd', enabled: false),
          ]),
        ),

        // ---- Translations
        _title(context, context.tr('translations')),
        Text(context.tr('translationHint'), style: Theme.of(context).textTheme.bodySmall),
        for (final l in langs)
          CheckboxListTile(
            title: Text(_langNames[l] ?? l.toUpperCase()),
            value: s.translationLangs.contains(l),
            onChanged: (v) => s.update(() {
              if (v == true) {
                s.translationLangs = {...s.translationLangs, l};
              } else if (s.translationLangs.length > 1) {
                s.translationLangs = {...s.translationLangs}..remove(l); // keep at least one
              }
            }),
          ),
        if (!langs.contains('sd'))
          ListTile(
            enabled: false,
            leading: const Icon(Icons.hourglass_empty_rounded),
            title: Text(context.tr('sindhiNoData')),
          ),

        // ---- Reading
        _title(context, context.tr('readingPrefs')),
        slider(context.tr('arabicSize'), s.arabicSize, 20, 44, (v) => s.update(() => s.arabicSize = v)),
        slider(context.tr('translationSize'), s.translationSize, 12, 26, (v) => s.update(() => s.translationSize = v)),
        slider(context.tr('lineSpacing'), s.lineSpacing, 1.4, 2.4, (v) => s.update(() => s.lineSpacing = v)),
        SwitchListTile(
            title: Text(context.tr('showTranslit')),
            value: s.showTranslit,
            onChanged: (v) => s.update(() => s.showTranslit = v)),
        SwitchListTile(
            title: Text(context.tr('showMeanings')),
            value: s.showWordMeanings,
            onChanged: (v) => s.update(() => s.showWordMeanings = v)),
        SwitchListTile(
            title: Text(context.tr('defaultWordView')),
            value: s.wordByWordView,
            onChanged: (v) => s.update(() => s.wordByWordView = v)),

        // ---- Audio
        _title(context, context.tr('audioSettings')),
        Wrap(spacing: 8, children: [
          for (final v in [0.75, 1.0, 1.25, 1.5])
            ChoiceChip(
                label: Text('$v×'),
                selected: s.audioSpeed == v,
                onSelected: (_) => s.update(() => s.audioSpeed = v)),
        ]),
        const SizedBox(height: 8),
        Text(context.tr('defaultRepeat'), style: Theme.of(context).textTheme.bodySmall),
        Wrap(spacing: 8, children: [
          for (final v in [1, 2, 3, 5, 10, 0])
            ChoiceChip(
                label: Text(v == 0 ? '∞' : '×$v'),
                selected: s.repeatCount == v,
                onSelected: (_) => s.update(() => s.repeatCount = v)),
        ]),
        SwitchListTile(
            title: Text(context.tr('autoNext')),
            value: s.autoNext,
            onChanged: (v) => s.update(() => s.autoNext = v)),
        ListTile(
          leading: const Icon(Icons.record_voice_over_rounded),
          title: Text(context.tr('reciter')),
          subtitle: Text('Mishary Rashid Alafasy\n${context.tr('reciterNote')}'),
          isThreeLine: true,
        ),

        // ---- Reminders
        _title(context, context.tr('reminders')),
        SwitchListTile(
          title: Text(context.tr('reminders')),
          subtitle: kIsWeb ? Text(context.tr('reminderWeb')) : null,
          value: s.reminderEnabled,
          onChanged: kIsWeb ? null : (v) => _setReminder(context, s, v),
        ),
        ListTile(
          enabled: !kIsWeb,
          leading: const Icon(Icons.schedule_rounded),
          title: Text(context.tr('reminderTime')),
          trailing: Text(TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute).format(context)),
          onTap: kIsWeb ? null : () => _pickTime(context, s),
        ),

        // ---- Data
        _title(context, context.tr('data')),
        ListTile(
            leading: const Icon(Icons.upload_file_rounded),
            title: Text(context.tr('backup')),
            onTap: () => _backup(context)),
        ListTile(
            leading: const Icon(Icons.download_rounded),
            title: Text(context.tr('restore')),
            onTap: () => _restore(context)),
        ListTile(
            leading: Icon(Icons.restart_alt_rounded, color: Theme.of(context).colorScheme.error),
            title: Text(context.tr('resetProgress')),
            onTap: () => _reset(context)),

        // ---- About
        _title(context, context.tr('about')),
        ListTile(
          leading: const Icon(Icons.slideshow_rounded),
          title: Text(context.tr('replayIntro')),
          onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const OnboardingScreen(fromSettings: true))),
        ),
        ListTile(
          leading: const Icon(Icons.info_outline_rounded),
          title: Text(context.tr('about')),
          onTap: () => showAboutDialog(
            context: context,
            applicationName: 'Al-Mulk Learn',
            applicationVersion: '1.0.0',
            children: [Text(context.tr('aboutText'))],
          ),
        ),
        ListTile(
          leading: const Icon(Icons.favorite_outline_rounded),
          title: Text(context.tr('credits')),
          onTap: () => Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
        ),
      ]),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../settings/settings_controller.dart';
import 'achievements_controller.dart';
import 'badges.dart';

/// All badges. Earned ones pop in with a small bounce; locked ones are grey.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ach = context.watch<AchievementsController>();
    final lang = context.watch<SettingsController>().uiLang;
    final c = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('badges'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('${ach.unlocked.length} / ${allBadges.length} ${context.tr('unlockedCount')}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: c.primary)),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220, mainAxisExtent: 190, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: allBadges.length,
            itemBuilder: (context, i) {
              final b = allBadges[i];
              final got = ach.unlocked.containsKey(b.id);
              final icon = CircleAvatar(
                radius: 30,
                backgroundColor: got ? c.secondary : c.onSurface.withValues(alpha: 0.12),
                child: Icon(got ? b.icon : Icons.lock_outline_rounded,
                    size: 30, color: got ? Colors.white : c.onSurface.withValues(alpha: 0.5)),
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    got
                        ? TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.4, end: 1),
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.elasticOut,
                            builder: (_, v, child) => Transform.scale(scale: v, child: child),
                            child: icon)
                        : icon,
                    const SizedBox(height: 8),
                    Text(b.title(lang),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: got ? null : c.onSurface.withValues(alpha: 0.6))),
                    const SizedBox(height: 4),
                    Text(b.desc(lang),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

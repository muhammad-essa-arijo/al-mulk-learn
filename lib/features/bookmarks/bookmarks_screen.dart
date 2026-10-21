import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../data/quran_repository.dart';
import '../common/library_controller.dart';
import '../common/note_dialog.dart';
import '../reader/reader_screen.dart';

/// Two tabs: bookmarked ayahs and personal notes.
class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lib = context.watch<LibraryController>();
    final repo = context.read<QuranRepository>();
    final marks = lib.bookmarks.toList()..sort();
    final c = Theme.of(context).colorScheme;

    void openAyah(int n) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ReaderScreen(initialAyah: n)));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('bookmarks')),
          bottom: TabBar(tabs: [
            Tab(text: context.tr('bookmarks')),
            Tab(text: context.tr('notes')),
          ]),
        ),
        body: TabBarView(children: [
          // ----- Bookmarks -----
          marks.isEmpty
              ? _empty(context, Icons.bookmark_border_rounded, context.tr('noBookmarks'))
              : ListView.builder(
                  itemCount: marks.length,
                  itemBuilder: (context, i) {
                    final a = repo.ayah(marks[i]);
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      child: ListTile(
                        onTap: () => openAyah(a.number),
                        title: Text('${context.tr('ayah')} ${a.number}'),
                        subtitle: Directionality(
                          textDirection: TextDirection.rtl,
                          child: Text(a.arabic,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontFamily: 'AmiriQuran', fontSize: 22, height: 1.8)),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.bookmark_rounded, color: c.secondary),
                          onPressed: () => lib.toggleBookmark(a.number),
                        ),
                      ),
                    );
                  },
                ),

          // ----- Notes -----
          lib.notes.isEmpty
              ? _empty(context, Icons.sticky_note_2_outlined, context.tr('noNotes'))
              : ListView(
                  children: [
                    for (final e in lib.notes.entries)
                      _noteTile(context, repo, e.key, e.value, openAyah),
                  ],
                ),
        ]),
      ),
    );
  }

  Widget _noteTile(BuildContext context, QuranRepository repo, String key,
      String text, void Function(int) openAyah) {
    // Keys look like "a:3" (ayah) or "w:3:2" (ayah 3, word 2).
    final p = key.split(':');
    var title = key;
    int? ayahNumber;
    if (p.length >= 2) {
      ayahNumber = int.tryParse(p[1]);
      title = '${context.tr('ayah')} ${p[1]}';
      if (p[0] == 'w' && p.length == 3 && ayahNumber != null &&
          ayahNumber >= 1 && ayahNumber <= repo.ayahs.length) {
        final pos = int.tryParse(p[2]);
        final matches =
            repo.ayah(ayahNumber).words.where((w) => w.position == pos);
        if (matches.isNotEmpty) title = '$title • ${matches.first.arabic}';
      }
    }
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: ListTile(
        title: Text(title),
        subtitle: Text(text),
        onTap: () => showNoteDialog(context, noteKey: key, title: title),
        trailing: ayahNumber == null
            ? null
            : IconButton(
                tooltip: context.tr('gotoAyah'),
                icon: const Icon(Icons.menu_book_rounded),
                onPressed: () => openAyah(ayahNumber!),
              ),
      ),
    );
  }

  Widget _empty(BuildContext context, IconData icon, String text) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.secondary),
            const SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
          ]),
        ),
      );
}

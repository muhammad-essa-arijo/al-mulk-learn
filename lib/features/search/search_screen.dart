import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import '../../core/text_utils.dart';
import '../../data/models.dart';
import '../../data/quran_repository.dart';
import '../reader/reader_screen.dart';
import '../word_detail/word_detail_sheet.dart';

/// Search words by Arabic, English meaning, transliteration or root.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  List<Word> _results = [];

  void _search(String text, QuranRepository repo) {
    final q = text.trim();
    if (q.isEmpty) {
      setState(() {
        _query = '';
        _results = [];
      });
      return;
    }
    // Compare simplified copies; the shown text is never touched.
    final qAr = normalizeArabic(q);
    final qLat = normalizeLatin(q);
    final found = repo.allWords.where((w) {
      return normalizeArabic(w.arabic).contains(qAr) ||
          normalizeArabic(w.root).contains(qAr) ||
          normalizeLatin(w.meaning).contains(qLat) ||
          normalizeLatin(w.translit).contains(qLat);
    }).take(100).toList();
    setState(() {
      _query = q;
      _results = found;
    });
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<QuranRepository>();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('search'))),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            autofocus: true,
            onChanged: (t) => _search(t, repo),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: context.tr('searchHint'),
              filled: true,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: _query.isEmpty
              ? _message(context, Icons.search_rounded, context.tr('searchEmpty'))
              : _results.isEmpty
                  ? _message(context, Icons.search_off_rounded, context.tr('noResults'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, i) {
                        final w = _results[i];
                        return ListTile(
                          onTap: () => showWordDetail(context, w),
                          leading: Text(w.arabic,
                              textDirection: TextDirection.rtl,
                              style: const TextStyle(
                                  fontFamily: 'AmiriQuran', fontSize: 26, height: 1.8)),
                          title: Text(w.meaning),
                          subtitle: Text(
                              '${w.translit} • ${context.tr('ayah')} ${w.ayah}'
                              '${w.root.isEmpty ? '' : ' • ${context.tr('root')}: ${w.root}'}'),
                          trailing: IconButton(
                            tooltip: context.tr('gotoAyah'),
                            icon: const Icon(Icons.menu_book_rounded),
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => ReaderScreen(initialAyah: w.ayah))),
                          ),
                        );
                      },
                    ),
        ),
      ]),
    );
  }

  Widget _message(BuildContext context, IconData icon, String text) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 56, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(height: 8),
          Text(text),
        ]),
      );
}

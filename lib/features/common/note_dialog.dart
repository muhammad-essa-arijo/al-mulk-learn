import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/strings.dart';
import 'library_controller.dart';

/// Small pop-up to write, edit or delete one note.
Future<void> showNoteDialog(BuildContext context,
    {required String noteKey, required String title}) {
  final lib = context.read<LibraryController>();
  final controller = TextEditingController(text: lib.notes[noteKey] ?? '');
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        maxLines: 5,
        autofocus: true,
        decoration: InputDecoration(hintText: context.tr('noteHint')),
      ),
      actions: [
        if (lib.notes.containsKey(noteKey))
          TextButton(
            onPressed: () {
              lib.setNote(noteKey, '');
              Navigator.pop(dialogContext);
            },
            child: Text(context.tr('delete')),
          ),
        TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.tr('cancel'))),
        FilledButton(
          onPressed: () {
            lib.setNote(noteKey, controller.text);
            Navigator.pop(dialogContext);
          },
          child: Text(context.tr('save')),
        ),
      ],
    ),
  );
}

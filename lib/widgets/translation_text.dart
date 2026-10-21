import 'package:flutter/material.dart';

/// Shows a translation in the right font and direction for its language.
/// Urdu (and Sindhi/Arabic) are right-to-left; English is left-to-right.
class TranslationText extends StatelessWidget {
  final String lang;
  final String text;
  final double size;
  final Color? color;
  const TranslationText(
      {super.key, required this.lang, required this.text, this.size = 16, this.color});

  static bool isRtl(String lang) => lang == 'ur' || lang == 'sd' || lang == 'ar';

  @override
  Widget build(BuildContext context) {
    final rtl = isRtl(lang);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: lang == 'ur' ? 'NotoNastaliqUrdu' : 'Inter',
          fontSize: size,
          height: lang == 'ur' ? 2.2 : 1.5, // Nastaliq needs extra height
          color: color,
        ),
      ),
    );
  }
}

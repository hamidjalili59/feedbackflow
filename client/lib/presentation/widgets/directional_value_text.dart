import 'package:flutter/material.dart';

/// Keeps left-to-right values such as phone numbers, emails, urls and ids
/// readable inside Persian/RTL sentences.
///
/// Without an LTR isolate, a value like `+989361360584` can be rendered as
/// `9361360584 +98` when it is embedded in an RTL paragraph.
String ltrIsolate(String value) => '\u2066$value\u2069';

String? nullableLtrIsolate(String? value) {
  if (value == null || value.isEmpty) return value;
  return ltrIsolate(value);
}

class LtrValueText extends StatelessWidget {
  const LtrValueText(
    this.value, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign = TextAlign.left,
  });

  final String value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        value,
        textAlign: textAlign,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
      ),
    );
  }
}

class PhoneNumberNormalizer {
  const PhoneNumberNormalizer._();

  static const String defaultCountryDialCode = '+98';

  /// Converts user input to a backend-compatible international phone number.
  ///
  /// Supported examples:
  /// - +989315245654 -> +989315245654
  /// - 00989315245654 -> +989315245654
  /// - 989315245654 -> +989315245654
  /// - 09315245654 -> +989315245654 (default Iran)
  /// - 9315245654 -> +989315245654 (default Iran mobile)
  static String normalize(
    String input, {
    String defaultDialCode = defaultCountryDialCode,
  }) {
    var value = _toEnglishDigits(input).trim();
    if (value.isEmpty) return value;

    value = value.replaceAll(RegExp(r'[\s\-()]+'), '');
    if (value.startsWith('00')) {
      value = '+${value.substring(2)}';
    }

    if (value.startsWith('+')) {
      final digits = value.substring(1).replaceAll(RegExp(r'\D'), '');
      return digits.isEmpty ? '' : '+$digits';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    final dialDigits = defaultDialCode.replaceAll('+', '');
    if (digits.startsWith(dialDigits)) return '+$digits';

    // Iran default: local mobile numbers often start with 09 or 9.
    if (defaultDialCode == '+98') {
      if (digits.startsWith('0')) return '+98${digits.substring(1)}';
      if (digits.length == 10 && digits.startsWith('9')) return '+98$digits';
    }

    return '$defaultDialCode$digits';
  }

  static bool isLikelyValid(String normalized) {
    final value = normalize(normalized);
    return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(value);
  }

  static String _toEnglishDigits(String input) {
    const fa = '۰۱۲۳۴۵۶۷۸۹';
    const ar = '٠١٢٣٤٥٦٧٨٩';
    final buffer = StringBuffer();
    for (final codeUnit in input.runes) {
      final char = String.fromCharCode(codeUnit);
      final faIndex = fa.indexOf(char);
      if (faIndex >= 0) {
        buffer.write(faIndex);
        continue;
      }
      final arIndex = ar.indexOf(char);
      if (arIndex >= 0) {
        buffer.write(arIndex);
        continue;
      }
      buffer.write(char);
    }
    return buffer.toString();
  }
}

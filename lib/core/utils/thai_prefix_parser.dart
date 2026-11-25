/// Immutable result of parsing a Thai student name into structured parts.
///
/// Pure Dart value object with zero Flutter or Supabase dependencies.
class ParsedThaiName {
  const ParsedThaiName({
    required this.prefix,
    required this.firstName,
    required this.lastName,
  });

  final String prefix;
  final String firstName;
  final String lastName;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other is ParsedThaiName &&
            other.prefix == prefix &&
            other.firstName == firstName &&
            other.lastName == lastName);
  }

  @override
  int get hashCode => Object.hash(prefix, firstName, lastName);

  @override
  String toString() =>
      'ParsedThaiName(prefix: "$prefix", firstName: "$firstName", lastName: "$lastName")';
}

/// Pure Dart utility for splitting Thai school student names into
/// `prefix`, `firstName`, and `lastName`.
///
/// Supports SGS exports including prefixes attached without a space
/// (e.g. `ด.ช.สมชาย ใจดี`, `UC-001`) and multi-word Thai surnames
/// (e.g. `ณ อยุธยา`).
abstract final class ThaiPrefixParser {
  // Ordered longest-first so 'นางสาว' always matches before 'นาง'.
  static const List<String> _thaiPrefixes = <String>[
    'ว่าที่ร้อยตรีหญิง',
    'ว่าที่ร้อยตรี',
    'เด็กหญิง',
    'เด็กชาย',
    'นางสาว',
    'ด.ญ.',
    'ด.ช.',
    'น.ส.',
    'นาง',
    'นาย',
  ];

  // English prefixes: dotted forms allow optional space; 'Miss' requires space.
  static final RegExp _englishPrefixPattern = RegExp(
    r'^(Mrs\.|Mr\.|Ms\.|Miss\s+)\s*',
    caseSensitive: false,
  );

  static final RegExp _whitespacePattern = RegExp(r'[\s\u00A0]+');

  /// Parses a single full-name string (e.g. `"ด.ช.สมชาย ใจดี"` or
  /// `"เด็กหญิงนภา ณ อยุธยา"`) into [ParsedThaiName].
  static ParsedThaiName parseFullName(String rawFullName) {
    final cleaned = _cleanWhitespace(rawFullName);
    if (cleaned.isEmpty) {
      return const ParsedThaiName(prefix: '', firstName: '', lastName: '');
    }

    final (prefix, remainder) = _extractPrefix(cleaned);
    final (firstName, lastName) = _splitFirstAndLast(remainder);
    return ParsedThaiName(
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
    );
  }

  /// Normalizes separated name columns where a prefix may still be attached
  /// to [rawFirstName] (e.g. `rawPrefix = ""`, `rawFirstName = "ด.ช.สมชาย"`,
  /// `rawLastName = "ใจดี"`).
  static ParsedThaiName normalizeParts({
    String? rawPrefix,
    required String rawFirstName,
    String? rawLastName,
  }) {
    var prefix = _cleanWhitespace(rawPrefix ?? '');
    var first = _cleanWhitespace(rawFirstName);
    var last = _cleanWhitespace(rawLastName ?? '');

    if (prefix.isEmpty && first.isNotEmpty) {
      final (extractedPrefix, remainder) = _extractPrefix(first);
      if (extractedPrefix.isNotEmpty) {
        prefix = extractedPrefix;
        first = remainder;
      }
    }

    if (last.isEmpty && first.contains(' ')) {
      final (splitFirst, splitLast) = _splitFirstAndLast(first);
      first = splitFirst;
      last = splitLast;
    }

    return ParsedThaiName(prefix: prefix, firstName: first, lastName: last);
  }

  static (String, String) _extractPrefix(String input) {
    for (final prefix in _thaiPrefixes) {
      if (input.startsWith(prefix)) {
        final remainder = input.substring(prefix.length).trimLeft();
        if (remainder.isNotEmpty) {
          return (prefix, remainder);
        }
      }
    }

    final englishMatch = _englishPrefixPattern.firstMatch(input);
    if (englishMatch != null) {
      final matchedPrefix = englishMatch.group(1)!.trim();
      final remainder = input.substring(englishMatch.end).trimLeft();
      if (remainder.isNotEmpty) {
        return (matchedPrefix, remainder);
      }
    }

    return ('', input);
  }

  static (String, String) _splitFirstAndLast(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return ('', '');
    }
    final spaceIndex = trimmed.indexOf(' ');
    if (spaceIndex == -1) {
      return (trimmed, '');
    }
    final first = trimmed.substring(0, spaceIndex).trim();
    final last = trimmed.substring(spaceIndex + 1).trim();
    return (first, last);
  }

  static String _cleanWhitespace(String value) {
    return value.replaceAll(_whitespacePattern, ' ').trim();
  }
}

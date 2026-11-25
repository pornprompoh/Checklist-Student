/// Pure Dart utility for converting between PostgreSQL ISO dates (`YYYY-MM-DD`)
/// and Thai Buddhist Era (พ.ศ.) formatted dates and times.
///
/// Has zero Flutter or Supabase dependencies so it can be shared across
/// `domain/`, `presentation/`, and unit tests without locale initialization.
abstract final class ThaiDateFormatter {
  static const int buddhistYearOffset = 543;

  static const List<String> _fullMonths = <String>[
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม',
  ];

  static const List<String> _shortMonths = <String>[
    'ม.ค.',
    'ก.พ.',
    'มี.ค.',
    'เม.ย.',
    'พ.ค.',
    'มิ.ย.',
    'ก.ค.',
    'ส.ค.',
    'ก.ย.',
    'ต.ค.',
    'พ.ย.',
    'ธ.ค.',
  ];

  static const List<String> _fullWeekdays = <String>[
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
    'เสาร์',
    'อาทิตย์',
  ];

  static const List<String> _shortWeekdays = <String>[
    'จ.',
    'อ.',
    'พ.',
    'พฤ.',
    'ศ.',
    'ส.',
    'อา.',
  ];

  static final RegExp _isoDatePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

  /// Converts a Christian Era (ค.ศ.) year to Thai Buddhist Era (พ.ศ.).
  static int toBuddhistYear(int christianYear) =>
      christianYear + buddhistYearOffset;

  /// Converts a Thai Buddhist Era (พ.ศ.) year to Christian Era (ค.ศ.).
  static int toChristianYear(int buddhistYear) =>
      buddhistYear - buddhistYearOffset;

  /// Formats [date] as zero-padded ISO `YYYY-MM-DD` for PostgreSQL `DATE`.
  static String toIsoDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = _pad2(date.month);
    final day = _pad2(date.day);
    return '$year-$month-$day';
  }

  /// Safely parses an ISO `YYYY-MM-DD` string into a local [DateTime].
  ///
  /// Returns `null` if [isoDate] is null, malformed, or not a valid calendar date.
  static DateTime? parseIsoDate(String? isoDate) {
    if (isoDate == null) {
      return null;
    }
    final trimmed = isoDate.trim();
    final match = _isoDatePattern.firstMatch(trimmed);
    if (match == null) {
      return null;
    }

    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    if (month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }

    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  /// Formats [date] with short Thai month name, e.g. `23 พ.ย. 2569`.
  static String formatShortDate(DateTime date) {
    final month = _shortMonths[date.month - 1];
    return '${date.day} $month ${toBuddhistYear(date.year)}';
  }

  /// Formats [date] with full Thai month name, e.g. `23 พฤศจิกายน 2569`.
  static String formatFullDate(DateTime date) {
    final month = _fullMonths[date.month - 1];
    return '${date.day} $month ${toBuddhistYear(date.year)}';
  }

  /// Formats [date] numerically in Buddhist Era, e.g. `23/11/2569`.
  static String formatNumericDate(DateTime date) {
    return '${_pad2(date.day)}/${_pad2(date.month)}/${toBuddhistYear(date.year)}';
  }

  /// Converts [dateTime] to local time and formats as `23 พ.ย. 2569 เวลา 14:30 น.`.
  static String formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final time = '${_pad2(local.hour)}:${_pad2(local.minute)}';
    return '${formatShortDate(local)} เวลา $time น.';
  }

  /// Formats a date range using short Thai dates, e.g. `16 พ.ค. 2569 – 10 ต.ค. 2569`.
  static String formatDateRange(DateTime start, DateTime end) {
    return '${formatShortDate(start)} – ${formatShortDate(end)}';
  }

  /// Returns the Thai weekday name for [isoWeekday] (`1` = จันทร์ ... `7` = อาทิตย์).
  static String weekdayThaiName(int isoWeekday, {bool short = false}) {
    RangeError.checkValueInInterval(isoWeekday, 1, 7, 'isoWeekday');
    final names = short ? _shortWeekdays : _fullWeekdays;
    return names[isoWeekday - 1];
  }

  static String _pad2(int value) => value.toString().padLeft(2, '0');
}

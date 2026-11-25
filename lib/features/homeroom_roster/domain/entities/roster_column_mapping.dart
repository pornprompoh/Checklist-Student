/// Name column layout selected by the teacher during import column mapping.
enum RosterNameColumnMode {
  /// Separate columns for `prefix` (optional), `firstName`, and `lastName`.
  separated,

  /// Single combined column (common in SGS exports) parsed by `ThaiPrefixParser`.
  combinedFullName,
}

/// Maps zero-based column indices from a parsed spreadsheet into system fields.
/// Pure Dart entity.
class RosterColumnMapping {
  const RosterColumnMapping({
    required this.headerRowIndex,
    required this.nameMode,
    this.studentNumberColumn,
    this.studentCodeColumn,
    this.prefixColumn,
    this.firstNameColumn,
    this.lastNameColumn,
    this.fullNameColumn,
  });

  /// Zero-based index of the header row (e.g. `0`, or `2..5` in SGS reports).
  final int headerRowIndex;
  final RosterNameColumnMode nameMode;
  final int? studentNumberColumn;
  final int? studentCodeColumn;
  final int? prefixColumn;
  final int? firstNameColumn;
  final int? lastNameColumn;
  final int? fullNameColumn;

  bool get hasRequiredColumns {
    if (studentCodeColumn == null) return false;
    return switch (nameMode) {
      RosterNameColumnMode.separated => firstNameColumn != null,
      RosterNameColumnMode.combinedFullName => fullNameColumn != null,
    };
  }

  RosterColumnMapping copyWith({
    int? headerRowIndex,
    RosterNameColumnMode? nameMode,
    int? studentNumberColumn,
    bool clearStudentNumberColumn = false,
    int? studentCodeColumn,
    bool clearStudentCodeColumn = false,
    int? prefixColumn,
    bool clearPrefixColumn = false,
    int? firstNameColumn,
    bool clearFirstNameColumn = false,
    int? lastNameColumn,
    bool clearLastNameColumn = false,
    int? fullNameColumn,
    bool clearFullNameColumn = false,
  }) {
    return RosterColumnMapping(
      headerRowIndex: headerRowIndex ?? this.headerRowIndex,
      nameMode: nameMode ?? this.nameMode,
      studentNumberColumn: clearStudentNumberColumn
          ? null
          : (studentNumberColumn ?? this.studentNumberColumn),
      studentCodeColumn: clearStudentCodeColumn
          ? null
          : (studentCodeColumn ?? this.studentCodeColumn),
      prefixColumn: clearPrefixColumn
          ? null
          : (prefixColumn ?? this.prefixColumn),
      firstNameColumn: clearFirstNameColumn
          ? null
          : (firstNameColumn ?? this.firstNameColumn),
      lastNameColumn: clearLastNameColumn
          ? null
          : (lastNameColumn ?? this.lastNameColumn),
      fullNameColumn: clearFullNameColumn
          ? null
          : (fullNameColumn ?? this.fullNameColumn),
    );
  }
}

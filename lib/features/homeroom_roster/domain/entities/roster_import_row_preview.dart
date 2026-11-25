import 'homeroom_student.dart';

/// Validation and duplicate classification for a single imported row.
enum RosterImportRowStatus {
  readyNew,
  duplicateExisting,
  duplicateInFile,
  invalid,
}

/// Resolution chosen by the teacher when [RosterImportRowStatus.duplicateExisting] occurs.
enum DuplicateResolutionAction { skip, overwrite }

/// Preview model for one student row before committing an Excel/CSV import.
/// Pure Dart entity.
class RosterImportRowPreview {
  const RosterImportRowPreview({
    required this.sourceRowNumber,
    required this.studentNumber,
    required this.studentCode,
    required this.prefix,
    required this.firstName,
    required this.lastName,
    required this.status,
    this.existingStudent,
    this.errorReason,
    this.duplicateAction = DuplicateResolutionAction.skip,
  });

  /// 1-based row number in the source spreadsheet for clear error references.
  final int sourceRowNumber;
  final int studentNumber;
  final String studentCode;
  final String prefix;
  final String firstName;
  final String lastName;
  final RosterImportRowStatus status;
  final HomeroomStudent? existingStudent;
  final String? errorReason;
  final DuplicateResolutionAction duplicateAction;

  String get fullName {
    final p = prefix.trim();
    final f = firstName.trim();
    final l = lastName.trim();
    final namePart = l.isEmpty ? f : '$f $l';
    return p.isEmpty ? namePart : '$p$namePart';
  }

  RosterImportRowPreview copyWith({
    DuplicateResolutionAction? duplicateAction,
  }) {
    return RosterImportRowPreview(
      sourceRowNumber: sourceRowNumber,
      studentNumber: studentNumber,
      studentCode: studentCode,
      prefix: prefix,
      firstName: firstName,
      lastName: lastName,
      status: status,
      existingStudent: existingStudent,
      errorReason: errorReason,
      duplicateAction: duplicateAction ?? this.duplicateAction,
    );
  }
}

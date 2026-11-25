import 'export_orientation.dart';
import 'export_section.dart';

/// User-configurable options controlling sections, A4 orientation, student
/// inclusion, signatures, and official-document cleanliness.
///
/// Defaults `includeTeacherResolvedBadges = false` so teacher-only `"เคยแก้ ร/มส"`
/// badges never leak into official ปพ.5 documents unintentionally.
class ExportOptions {
  const ExportOptions({
    this.selectedSections = const <ExportSection>{
      ExportSection.roster,
      ExportSection.gradeSummary,
    },
    this.orientationMode = ExportOrientationMode.auto,
    this.includeTransferredOut = false,
    this.includeSignatureLines = true,
    this.includeTeacherResolvedBadges = false,
  });

  final Set<ExportSection> selectedSections;
  final ExportOrientationMode orientationMode;
  final bool includeTransferredOut;
  final bool includeSignatureLines;
  final bool includeTeacherResolvedBadges;

  bool hasSection(ExportSection section) => selectedSections.contains(section);

  ExportOptions copyWith({
    Set<ExportSection>? selectedSections,
    ExportOrientationMode? orientationMode,
    bool? includeTransferredOut,
    bool? includeSignatureLines,
    bool? includeTeacherResolvedBadges,
  }) {
    return ExportOptions(
      selectedSections: selectedSections ?? this.selectedSections,
      orientationMode: orientationMode ?? this.orientationMode,
      includeTransferredOut:
          includeTransferredOut ?? this.includeTransferredOut,
      includeSignatureLines:
          includeSignatureLines ?? this.includeSignatureLines,
      includeTeacherResolvedBadges:
          includeTeacherResolvedBadges ?? this.includeTeacherResolvedBadges,
    );
  }
}

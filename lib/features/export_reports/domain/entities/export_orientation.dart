/// Concrete A4 page orientation used by Preview Canvas and Step 5.2–5.3
/// document generators.
enum ExportPageOrientation {
  portrait('แนวตั้ง', 'A4 แนวตั้ง (210 × 297 มม.)'),
  landscape('แนวนอน', 'A4 แนวนอน (297 × 210 มม.)');

  const ExportPageOrientation(this.shortThaiLabel, this.dimensionThaiLabel);

  final String shortThaiLabel;
  final String dimensionThaiLabel;
}

/// User-selected A4 orientation mode (`อัตโนมัติ`, `แนวตั้ง`, `แนวนอน`).
enum ExportOrientationMode {
  auto('อัตโนมัติ'),
  portrait('แนวตั้ง'),
  landscape('แนวนอน');

  const ExportOrientationMode(this.thaiLabel);

  final String thaiLabel;
}

/// Output of `ExportLayoutAdvisorService.resolveOrientation`.
class OrientationDecision {
  const OrientationDecision({
    required this.orientation,
    required this.isAuto,
    required this.reasonThai,
  });

  final ExportPageOrientation orientation;
  final bool isAuto;
  final String reasonThai;
}

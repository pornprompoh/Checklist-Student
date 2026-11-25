import '../entities/export_orientation.dart';

/// Pure Dart OOXML (`WordprocessingML`) low-level builders for Thai documents
/// using `TH Sarabun New` with synchronized Latin (`w:sz`) and Thai complex
/// script (`w:szCs`) sizing.
class DocxXmlPrimitives {
  const DocxXmlPrimitives();

  static const String fontName = 'TH Sarabun New';

  /// A4 dimensions in twips (1 inch = 1440 twips; 210mm x 297mm).
  static const int a4PortraitWidth = 11906;
  static const int a4PortraitHeight = 16838;
  static const int a4LandscapeWidth = 16838;
  static const int a4LandscapeHeight = 11906;

  /// 0.5 inch page margins (720 twips) on all sides.
  static const int pageMarginTwips = 720;

  static final RegExp _invalidXmlControlChars = RegExp(
    r'[\x00-\x08\x0B\x0C\x0E-\x1F]',
  );

  int contentWidthFor(ExportPageOrientation orientation) {
    final pageWidth = orientation == ExportPageOrientation.landscape
        ? a4LandscapeWidth
        : a4PortraitWidth;
    return pageWidth - (pageMarginTwips * 2);
  }

  /// Strips invalid XML 1.0 control characters and escapes all XML entities.
  String escapeXml(String input) {
    final sanitized = input.replaceAll(_invalidXmlControlChars, '');
    return sanitized
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Builds `<w:rPr>` with `TH Sarabun New` on ascii/hAnsi/cs and matching
  /// half-point sizes on both `w:sz` and `w:szCs` so Thai font sizes match Word.
  String buildRunProps({required double fontSizePt, bool bold = false}) {
    final halfPt = (fontSizePt * 2).round();
    final boldXml = bold ? '<w:b/><w:bCs/>' : '';
    return '<w:rPr>'
        '<w:rFonts w:ascii="$fontName" w:hAnsi="$fontName" w:cs="$fontName"/>'
        '$boldXml'
        '<w:sz w:val="$halfPt"/>'
        '<w:szCs w:val="$halfPt"/>'
        '<w:lang w:val="en-US" w:bidi="th-TH"/>'
        '</w:rPr>';
  }

  /// Builds a `<w:r>` run supporting embedded `\n` line breaks via `<w:br/>`.
  String buildRun({
    required String text,
    required double fontSizePt,
    bool bold = false,
  }) {
    final rPr = buildRunProps(fontSizePt: fontSizePt, bold: bold);
    final lines = text.split('\n');
    final buffer = StringBuffer('<w:r>$rPr');
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        buffer.write('<w:br/>');
      }
      buffer.write('<w:t xml:space="preserve">${escapeXml(lines[i])}</w:t>');
    }
    buffer.write('</w:r>');
    return buffer.toString();
  }

  String buildParagraph({
    required String text,
    double fontSizePt = 14,
    bool bold = false,
    String align = 'left',
    int spaceBefore = 0,
    int spaceAfter = 0,
    bool keepNext = false,
  }) {
    final keepNextXml = keepNext ? '<w:keepNext/>' : '';
    return '<w:p>'
        '<w:pPr>'
        '$keepNextXml'
        '<w:spacing w:before="$spaceBefore" w:after="$spaceAfter" '
        'w:line="240" w:lineRule="auto"/>'
        '<w:jc w:val="$align"/>'
        '</w:pPr>'
        '${buildRun(text: text, fontSizePt: fontSizePt, bold: bold)}'
        '</w:p>';
  }

  String buildSectionHeading(String title) {
    return buildParagraph(
      text: title,
      fontSizePt: 15,
      bold: true,
      align: 'left',
      spaceBefore: 160,
      spaceAfter: 60,
      keepNext: true,
    );
  }

  /// Builds a fixed-layout `<w:tbl>` with repeating `<w:tblHeader/>` and
  /// non-splitting rows (`<w:cantSplit/>`).
  String buildTable({
    required List<String> headers,
    required List<List<String>> rows,
    required List<int> columnWidthsTwips,
    List<String>? columnAlignments,
    double fontSizePt = 13,
    bool borderless = false,
  }) {
    final totalWidth = columnWidthsTwips.fold<int>(0, (sum, w) => sum + w);
    final borderAttr = borderless
        ? 'w:val="none" w:sz="0" w:space="0" w:color="auto"'
        : 'w:val="single" w:sz="4" w:space="0" w:color="888888"';

    final buffer = StringBuffer()
      ..write('<w:tbl><w:tblPr>')
      ..write('<w:tblW w:w="$totalWidth" w:type="dxa"/>')
      ..write('<w:tblBorders>')
      ..write('<w:top $borderAttr/><w:left $borderAttr/>')
      ..write('<w:bottom $borderAttr/><w:right $borderAttr/>')
      ..write('<w:insideH $borderAttr/><w:insideV $borderAttr/>')
      ..write('</w:tblBorders>')
      ..write('<w:tblLayout w:type="fixed"/>')
      ..write('<w:tblCellMar>')
      ..write('<w:top w:w="40" w:type="dxa"/>')
      ..write('<w:left w:w="70" w:type="dxa"/>')
      ..write('<w:bottom w:w="40" w:type="dxa"/>')
      ..write('<w:right w:w="70" w:type="dxa"/>')
      ..write('</w:tblCellMar>')
      ..write('</w:tblPr><w:tblGrid>');

    for (final w in columnWidthsTwips) {
      buffer.write('<w:gridCol w:w="$w"/>');
    }
    buffer.write('</w:tblGrid>');

    if (headers.isNotEmpty) {
      buffer.write('<w:tr><w:trPr><w:cantSplit/><w:tblHeader/></w:trPr>');
      for (var i = 0; i < headers.length; i++) {
        final w = columnWidthsTwips[i];
        buffer
          ..write('<w:tc><w:tcPr>')
          ..write('<w:tcW w:w="$w" w:type="dxa"/>')
          ..write('<w:shd w:val="clear" w:color="auto" w:fill="F2F4F7"/>')
          ..write('<w:vAlign w:val="center"/>')
          ..write('</w:tcPr>')
          ..write(
            buildParagraph(
              text: headers[i],
              fontSizePt: fontSizePt,
              bold: true,
              align: 'center',
              spaceBefore: 0,
              spaceAfter: 0,
            ),
          )
          ..write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }

    for (final row in rows) {
      buffer.write('<w:tr><w:trPr><w:cantSplit/></w:trPr>');
      for (var i = 0; i < columnWidthsTwips.length; i++) {
        final w = columnWidthsTwips[i];
        final cellText = i < row.length ? row[i] : '';
        final align = (columnAlignments != null && i < columnAlignments.length)
            ? columnAlignments[i]
            : 'center';
        buffer
          ..write('<w:tc><w:tcPr>')
          ..write('<w:tcW w:w="$w" w:type="dxa"/>')
          ..write('<w:vAlign w:val="center"/>')
          ..write('</w:tcPr>')
          ..write(
            buildParagraph(
              text: cellText,
              fontSizePt: fontSizePt,
              bold: false,
              align: align,
              spaceBefore: 0,
              spaceAfter: 0,
            ),
          )
          ..write('</w:tc>');
      }
      buffer.write('</w:tr>');
    }

    buffer.write('</w:tbl>');
    return buffer.toString();
  }

  /// Allocates [totalWidth] proportionally across [weights] with exact sum.
  List<int> allocateColumnWidths(List<int> weights, int totalWidth) {
    final totalWeight = weights.fold<int>(0, (sum, w) => sum + w);
    if (totalWeight <= 0 || weights.isEmpty) return const <int>[];
    final result = <int>[];
    var assigned = 0;
    for (var i = 0; i < weights.length; i++) {
      if (i == weights.length - 1) {
        result.add(totalWidth - assigned);
      } else {
        final width = (totalWidth * weights[i] / totalWeight).round();
        result.add(width);
        assigned += width;
      }
    }
    return result;
  }

  String buildSectionProperties(
    ExportPageOrientation orientation, {
    required String footerRelId,
  }) {
    final pgSz = orientation == ExportPageOrientation.landscape
        ? '<w:pgSz w:w="$a4LandscapeWidth" w:h="$a4LandscapeHeight" w:orient="landscape"/>'
        : '<w:pgSz w:w="$a4PortraitWidth" w:h="$a4PortraitHeight"/>';
    return '<w:sectPr>'
        '<w:footerReference w:type="default" r:id="$footerRelId"/>'
        '$pgSz'
        '<w:pgMar w:top="$pageMarginTwips" w:right="$pageMarginTwips" '
        'w:bottom="$pageMarginTwips" w:left="$pageMarginTwips" '
        'w:header="420" w:footer="420" w:gutter="0"/>'
        '</w:sectPr>';
  }
}

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../../../core/utils/thai_date_formatter.dart';
import '../entities/export_report_bundle.dart';
import '../entities/export_section.dart';
import 'docx_grade_and_chrome_builders.dart';
import 'docx_section_table_builders.dart';
import 'docx_xml_primitives.dart';

/// Pure Dart Microsoft Word (`.docx`) OOXML document generator tailored for
/// Thai official school reports (`TH Sarabun New` + `w:szCs` complex script
/// sizing, exact unrounded decimals, A4 Portrait/Landscape switching, and
/// repeating table headers).
class DocxReportGeneratorService {
  const DocxReportGeneratorService({
    this.xml = const DocxXmlPrimitives(),
    this.sectionBuilders = const DocxSectionTableBuilders(),
    this.gradeAndChromeBuilders = const DocxGradeAndChromeBuilders(),
  });

  final DocxXmlPrimitives xml;
  final DocxSectionTableBuilders sectionBuilders;
  final DocxGradeAndChromeBuilders gradeAndChromeBuilders;

  static const String _footerRelId = 'rId2';

  Uint8List generate(ExportReportBundle bundle) {
    final archive = Archive();

    _addUtf8File(archive, '[Content_Types].xml', _buildContentTypesXml());
    _addUtf8File(archive, '_rels/.rels', _buildRootRelsXml());
    _addUtf8File(
      archive,
      'word/_rels/document.xml.rels',
      _buildDocumentRelsXml(),
    );
    _addUtf8File(archive, 'word/styles.xml', _buildStylesXml());
    _addUtf8File(
      archive,
      'word/footer1.xml',
      _buildFooterXml(bundle.header.exportedAt),
    );
    _addUtf8File(archive, 'word/document.xml', _buildDocumentXml(bundle));

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('ไม่สามารถสร้างไฟล์เอกสาร Word (.docx) ได้');
    }
    return Uint8List.fromList(encoded);
  }

  void _addUtf8File(Archive archive, String path, String xmlContent) {
    final bytes = utf8.encode(xmlContent);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  String _buildDocumentXml(ExportReportBundle bundle) {
    final orientation = bundle.orientationDecision.orientation;
    final contentWidth = xml.contentWidthFor(orientation);
    final body = StringBuffer()
      ..write(gradeAndChromeBuilders.buildDocumentHeader(bundle.header));

    if (bundle.options.hasSection(ExportSection.roster)) {
      body.write(sectionBuilders.buildRosterSection(bundle, contentWidth));
    }
    if (bundle.options.hasSection(ExportSection.attendance)) {
      body.write(sectionBuilders.buildAttendanceSection(bundle, contentWidth));
    }
    if (bundle.options.hasSection(ExportSection.assignments)) {
      body.write(sectionBuilders.buildAssignmentsSection(bundle, contentWidth));
    }
    if (bundle.options.hasSection(ExportSection.gradeSummary)) {
      body.write(
        gradeAndChromeBuilders.buildGradeSummarySection(bundle, contentWidth),
      );
    }
    if (bundle.options.includeSignatureLines) {
      body.write(
        gradeAndChromeBuilders.buildSignatureBlock(bundle.header, contentWidth),
      );
    }
    body.write(
      xml.buildSectionProperties(orientation, footerRelId: _footerRelId),
    );

    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:document '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<w:body>$body</w:body>'
        '</w:document>';
  }

  String _buildStylesXml() {
    const font = DocxXmlPrimitives.fontName;
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:styles '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:docDefaults>'
        '<w:rPrDefault><w:rPr>'
        '<w:rFonts w:ascii="$font" w:hAnsi="$font" w:cs="$font"/>'
        '<w:sz w:val="32"/>'
        '<w:szCs w:val="32"/>'
        '<w:lang w:val="en-US" w:bidi="th-TH"/>'
        '</w:rPr></w:rPrDefault>'
        '<w:pPrDefault><w:pPr>'
        '<w:spacing w:before="0" w:after="0" w:line="240" w:lineRule="auto"/>'
        '</w:pPr></w:pPrDefault>'
        '</w:docDefaults>'
        '<w:style w:type="paragraph" w:default="1" w:styleId="Normal">'
        '<w:name w:val="Normal"/>'
        '<w:qFormat/>'
        '<w:rPr>'
        '<w:rFonts w:ascii="$font" w:hAnsi="$font" w:cs="$font"/>'
        '<w:sz w:val="32"/>'
        '<w:szCs w:val="32"/>'
        '<w:lang w:val="en-US" w:bidi="th-TH"/>'
        '</w:rPr>'
        '</w:style>'
        '</w:styles>';
  }

  String _buildFooterXml(DateTime exportedAt) {
    final dateText = ThaiDateFormatter.formatFullDate(exportedAt);
    final rPr = xml.buildRunProps(fontSizePt: 12);
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<w:ftr '
        'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">'
        '<w:p>'
        '<w:pPr><w:jc w:val="right"/></w:pPr>'
        '${xml.buildRun(text: 'วันที่ออกเอกสาร $dateText · หน้า ', fontSizePt: 12)}'
        '<w:r>$rPr<w:fldChar w:fldCharType="begin"/></w:r>'
        '<w:r>$rPr<w:instrText xml:space="preserve"> PAGE </w:instrText></w:r>'
        '<w:r>$rPr<w:fldChar w:fldCharType="separate"/></w:r>'
        '<w:r>$rPr<w:t>1</w:t></w:r>'
        '<w:r>$rPr<w:fldChar w:fldCharType="end"/></w:r>'
        '${xml.buildRun(text: ' / ', fontSizePt: 12)}'
        '<w:r>$rPr<w:fldChar w:fldCharType="begin"/></w:r>'
        '<w:r>$rPr<w:instrText xml:space="preserve"> NUMPAGES </w:instrText></w:r>'
        '<w:r>$rPr<w:fldChar w:fldCharType="separate"/></w:r>'
        '<w:r>$rPr<w:t>1</w:t></w:r>'
        '<w:r>$rPr<w:fldChar w:fldCharType="end"/></w:r>'
        '</w:p>'
        '</w:ftr>';
  }

  String _buildContentTypesXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" '
        'ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/word/document.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>'
        '<Override PartName="/word/styles.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>'
        '<Override PartName="/word/footer1.xml" '
        'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml"/>'
        '</Types>';
  }

  String _buildRootRelsXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" '
        'Target="word/document.xml"/>'
        '</Relationships>';
  }

  String _buildDocumentRelsXml() {
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" '
        'Target="styles.xml"/>'
        '<Relationship Id="$_footerRelId" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/footer" '
        'Target="footer1.xml"/>'
        '</Relationships>';
  }
}

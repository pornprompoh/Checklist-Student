import 'package:checklist_student/core/utils/thai_prefix_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThaiPrefixParser.parseFullName', () {
    test('UC-001: parses prefixes attached directly without a space', () {
      expect(
        ThaiPrefixParser.parseFullName('ด.ช.สมชาย ใจดี'),
        const ParsedThaiName(
          prefix: 'ด.ช.',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('เด็กชายธนพล วงศ์สุวรรณ'),
        const ParsedThaiName(
          prefix: 'เด็กชาย',
          firstName: 'ธนพล',
          lastName: 'วงศ์สุวรรณ',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('นายกฤษฎา มั่นคง'),
        const ParsedThaiName(
          prefix: 'นาย',
          firstName: 'กฤษฎา',
          lastName: 'มั่นคง',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('นางสาวพิมพ์ชนก ศรีสุข'),
        const ParsedThaiName(
          prefix: 'นางสาว',
          firstName: 'พิมพ์ชนก',
          lastName: 'ศรีสุข',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('น.ส.กมลวรรณ ดีงาม'),
        const ParsedThaiName(
          prefix: 'น.ส.',
          firstName: 'กมลวรรณ',
          lastName: 'ดีงาม',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('นางสมศรี ยิ้มแย้ม'),
        const ParsedThaiName(
          prefix: 'นาง',
          firstName: 'สมศรี',
          lastName: 'ยิ้มแย้ม',
        ),
      );
    });

    test('parses prefixes followed by spaces and collapses extra whitespace', () {
      expect(
        ThaiPrefixParser.parseFullName('ด.ญ. สุดา   รักเรียน'),
        const ParsedThaiName(
          prefix: 'ด.ญ.',
          firstName: 'สุดา',
          lastName: 'รักเรียน',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('  นาย\tสมศักดิ์   ใจกล้า  '),
        const ParsedThaiName(
          prefix: 'นาย',
          firstName: 'สมศักดิ์',
          lastName: 'ใจกล้า',
        ),
      );
    });

    test('preserves multi-word Thai surnames such as ณ อยุธยา', () {
      expect(
        ThaiPrefixParser.parseFullName('เด็กหญิงนภา ณ อยุธยา'),
        const ParsedThaiName(
          prefix: 'เด็กหญิง',
          firstName: 'นภา',
          lastName: 'ณ อยุธยา',
        ),
      );
      expect(
        ThaiPrefixParser.parseFullName('นาย กฤษฎา ณ อยุธยา'),
        const ParsedThaiName(
          prefix: 'นาย',
          firstName: 'กฤษฎา',
          lastName: 'ณ อยุธยา',
        ),
      );
    });

    test('handles names without prefix, single-word names, and English prefixes', () {
      expect(
        ThaiPrefixParser.parseFullName('สมชาย ใจดี'),
        const ParsedThaiName(prefix: '', firstName: 'สมชาย', lastName: 'ใจดี'),
      );
      expect(
        ThaiPrefixParser.parseFullName('นายสมศักดิ์'),
        const ParsedThaiName(prefix: 'นาย', firstName: 'สมศักดิ์', lastName: ''),
      );
      expect(
        ThaiPrefixParser.parseFullName('Mr. John Doe'),
        const ParsedThaiName(prefix: 'Mr.', firstName: 'John', lastName: 'Doe'),
      );
      expect(
        ThaiPrefixParser.parseFullName(''),
        const ParsedThaiName(prefix: '', firstName: '', lastName: ''),
      );
    });
  });

  group('ThaiPrefixParser.normalizeParts', () {
    test('extracts prefix attached to firstName when prefix column is empty', () {
      expect(
        ThaiPrefixParser.normalizeParts(
          rawPrefix: '',
          rawFirstName: 'ด.ช.สมชาย',
          rawLastName: 'ใจดี',
        ),
        const ParsedThaiName(
          prefix: 'ด.ช.',
          firstName: 'สมชาย',
          lastName: 'ใจดี',
        ),
      );
    });

    test('splits full name placed in firstName column when lastName is empty', () {
      expect(
        ThaiPrefixParser.normalizeParts(
          rawPrefix: 'นางสาว',
          rawFirstName: 'พิมพ์ชนก   ศรีสุข',
          rawLastName: '',
        ),
        const ParsedThaiName(
          prefix: 'นางสาว',
          firstName: 'พิมพ์ชนก',
          lastName: 'ศรีสุข',
        ),
      );
    });
  });
}

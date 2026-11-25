import 'package:flutter/material.dart';

/// Left showcase column shown on wide desktop viewports (`>= 840px`) on
/// [TeacherLoginPage], written in calm, authentic Thai EdTech copy without
/// redundant inner borders.
class LoginShowcasePanel extends StatelessWidget {
  const LoginShowcasePanel({super.key});

  static const List<(IconData, String, String)> _highlights =
      <(IconData, String, String)>[
        (
          Icons.fact_check_rounded,
          'เช็คชื่อรายคาบและทำงานออฟไลน์ได้',
          'บันทึก มา / สาย / ลา / ขาด ได้แม้สัญญาณเน็ตหลุด และซิงค์ข้อมูลอัตโนมัติเมื่อกลับมาออนไลน์',
        ),
        (
          Icons.table_chart_rounded,
          'ตารางคะแนนทศนิยมจริง พร้อมส่งออก ปพ.5',
          'รวมคะแนนตามจริงไม่ปัดเศษ แนะนำ ร / มส อัตโนมัติ และส่งออก Excel, PDF Sarabun, Word ได้ทันที',
        ),
        (
          Icons.badge_rounded,
          'พอร์ทัลนักเรียนด้วยรหัส PIN 6 หลัก',
          'นักเรียนตรวจสอบเวลาเรียน งานค้าง และคะแนนได้เองผ่านลิงก์ครูโดยไม่ต้องสมัครบัญชี',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.42),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'พื้นที่ทำงานสำหรับครูผู้สอน',
            style: textTheme.labelLarge?.copyWith(color: colorScheme.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'เช็คชื่อ ตรวจงาน และตัดเกรด ปพ.5 ในระบบเดียว',
            style: textTheme.headlineSmall?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'จัดเก็บรายชื่อ แผนเก็บงาน และสรุปผลการเรียนแยกตามปีการศึกษาและภาคเรียนอย่างเป็นระบบ',
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _highlights.length; i++) ...[
            _HighlightRow(
              icon: _highlights[i].$1,
              title: _highlights[i].$2,
              subtitle: _highlights[i].$3,
            ),
            if (i != _highlights.length - 1) const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }
}

class _HighlightRow extends StatelessWidget {
  const _HighlightRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 19, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

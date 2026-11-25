import 'package:flutter/material.dart';

/// Left showcase column shown on wide desktop viewports (`>= 840px`) on
/// [TeacherLoginPage] highlighting the 3 core teacher workflows cleanly.
class LoginShowcasePanel extends StatelessWidget {
  const LoginShowcasePanel({super.key});

  static const List<(IconData, String, String)> _highlights =
      <(IconData, String, String)>[
        (
          Icons.fact_check_rounded,
          'เช็คชื่อไวใน 1 แตะ พร้อมใช้งานออฟไลน์',
          'บันทึก มา / สาย / ลา / ขาด ได้แม้อินเทอร์เน็ตในห้องเรียนขัดข้อง และซิงค์ให้อัตโนมัติ',
        ),
        (
          Icons.table_chart_rounded,
          'ตารางคะแนนทศนิยมจริง ตัดเกรด ปพ.5',
          'รวมคะแนนไม่ปัดเศษ แนะนำ ร / มส อัตโนมัติ และส่งออก Excel, PDF Sarabun, Word ได้ทันที',
        ),
        (
          Icons.badge_rounded,
          'พอร์ทัลนักเรียนปลอดภัยด้วย PIN 6 หลัก',
          'นักเรียนตรวจเวลาเรียน งานค้าง และคะแนนได้เองผ่านลิงก์ครูโดยไม่ต้องสมัครบัญชี',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.48),
        border: Border(right: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.school_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'สำหรับครูผู้สอนยุคใหม่',
                  style: textTheme.labelMedium?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'ผู้ช่วยจัดการชั้นเรียน\nครบจบในที่เดียว',
            style: textTheme.headlineMedium?.copyWith(
              color: colorScheme.onSurface,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'ออกแบบเพื่อลดภาระงานเอกสารของครูไทย ใช้งานลื่นทั้งคอมพิวเตอร์ แท็บเล็ต และมือถือ',
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
            if (i != _highlights.length - 1) const SizedBox(height: 14),
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
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Icon(icon, size: 19, color: colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: textTheme.titleSmall),
              const SizedBox(height: 2),
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

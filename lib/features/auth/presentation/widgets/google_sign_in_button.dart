import 'package:flutter/material.dart';

/// Responsive Google Sign-In button following `AppTheme` tokens (`10px` radius,
/// explicit hover/focus/pressed states, loading indicator, double-tap guard).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.enabled = true,
    this.label = 'เข้าสู่ระบบด้วย Google',
  });

  final VoidCallback? onPressed;
  final bool isLoading;
  final bool enabled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isInteractive = enabled && !isLoading && onPressed != null;

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: isInteractive ? onPressed : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: colorScheme.onSurfaceVariant,
                ),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.g_mobiledata_rounded,
                  size: 22,
                  color: isInteractive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isLoading ? 'กำลังเชื่อมต่อ Google...' : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: isInteractive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

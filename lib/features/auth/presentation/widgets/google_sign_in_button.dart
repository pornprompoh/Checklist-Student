import 'package:flutter/material.dart';

/// Responsive Google Sign-In button with built-in loading indicator and
/// double-tap prevention, styled strictly with Material 3 [ColorScheme].
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
            borderRadius: BorderRadius.circular(12),
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
              const Icon(Icons.login_rounded, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                isLoading ? 'กำลังเชื่อมต่อ Google...' : label,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: isInteractive
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

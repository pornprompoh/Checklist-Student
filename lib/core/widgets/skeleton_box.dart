import 'package:flutter/material.dart';

/// Animated theme-aware placeholder box for Skeleton Loading states.
///
/// Uses [ColorScheme.surfaceContainerHighest] and [ColorScheme.surfaceContainerLow]
/// so pulse placeholders render cleanly in both Light Mode and Dark Mode.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) : _isCircle = false;

  /// Convenience constructor for single-line text skeleton placeholders.
  const SkeletonBox.line({
    super.key,
    this.width = double.infinity,
    this.height = 14,
    this.borderRadius = const BorderRadius.all(Radius.circular(6)),
  }) : _isCircle = false;

  /// Convenience constructor for circular avatar/icon skeleton placeholders.
  const SkeletonBox.circle({
    super.key,
    required double size,
  }) : width = size,
       height = size,
       borderRadius = BorderRadius.zero,
       _isCircle = true;

  final double? width;
  final double height;
  final BorderRadiusGeometry borderRadius;
  final bool _isCircle;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
    _pulseAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final beginColor = colorScheme.surfaceContainerHighest;
    final endColor = colorScheme.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(beginColor, endColor, _pulseAnimation.value),
            shape: widget._isCircle ? BoxShape.circle : BoxShape.rectangle,
            borderRadius: widget._isCircle ? null : widget.borderRadius,
          ),
        );
      },
    );
  }
}

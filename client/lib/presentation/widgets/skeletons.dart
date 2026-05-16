import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// A subtle, dependency-free shimmer block used as a placeholder.
///
/// Animates opacity between two values to give a gentle pulsing effect
/// without pulling in third-party shimmer packages.
class SkeletonBlock extends StatefulWidget {
  const SkeletonBlock({
    this.height = 16,
    this.width = double.infinity,
    this.radius = 10,
    super.key,
  });

  final double height;
  final double width;
  final double radius;

  @override
  State<SkeletonBlock> createState() => _SkeletonBlockState();
}

class _SkeletonBlockState extends State<SkeletonBlock>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_controller.value);
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.surfaceContainerHighest.withValues(alpha: 0.45),
              scheme.surfaceContainerHighest.withValues(alpha: 0.85),
              t,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}

/// Skeleton placeholder that resembles a form card while loading.
class FormCardSkeleton extends StatelessWidget {
  const FormCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBlock(width: 48, height: 48, radius: 14),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(height: 18, width: 220),
                SizedBox(height: 8),
                SkeletonBlock(height: 12, width: 160),
                SizedBox(height: 14),
                Row(
                  children: [
                    SkeletonBlock(height: 24, width: 64, radius: 999),
                    SizedBox(width: 8),
                    SkeletonBlock(height: 24, width: 84, radius: 999),
                    SizedBox(width: 8),
                    SkeletonBlock(height: 24, width: 56, radius: 999),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

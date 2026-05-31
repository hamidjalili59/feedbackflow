import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_spacing.dart';

class FeedbackSheetFrame extends StatelessWidget {
  const FeedbackSheetFrame({
    required this.children,
    this.maxWidth = 560,
    this.padding = AppSpacing.card,
    super.key,
  });

  final List<Widget> children;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF0E1220) : const Color(0xFFF3F3F5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            border: Border.all(
              color: scheme.primary.withValues(alpha: dark ? 0.20 : 0.18),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 42,
                offset: const Offset(0, 22),
                color: Colors.black.withValues(alpha: dark ? 0.22 : 0.075),
              ),
            ],
          ),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
  }
}

class FeedbackFieldCard extends StatelessWidget {
  const FeedbackFieldCard({
    required this.index,
    required this.icon,
    required this.title,
    required this.child,
    this.description,
    this.isRequired = false,
    this.compact = false,
    super.key,
  });

  final int index;
  final IconData icon;
  final String title;
  final String? description;
  final bool isRequired;
  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF171A2A) : Colors.white,
        borderRadius: BorderRadius.circular(
          compact ? AppSpacing.radiusLg : AppSpacing.radiusXl,
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: dark ? 0.34 : 0.62),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 28,
            offset: const Offset(0, 14),
            color: Colors.black.withValues(alpha: dark ? 0.18 : 0.055),
          ),
        ],
      ),
      padding: EdgeInsets.all(compact ? AppSpacing.sm : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest.withValues(alpha: 0.72),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.55),
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 14, color: scheme.onPrimaryContainer),
                    const SizedBox(width: 5),
                    Text(
                      '$index',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (isRequired)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.66),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    context.l10n.t('required'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onErrorContainer,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style:
                (compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.2,
                    ),
          ),
          if ((description ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          SizedBox(height: compact ? 12 : 16),
          child,
        ],
      ),
    );
  }
}

class FeedbackOptionChip extends StatelessWidget {
  const FeedbackOptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expand = false,
    super.key,
  });

  final String label;
  final bool selected;
  final IconData? icon;
  final bool expand;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final radius = BorderRadius.circular(expand ? 14 : 18);
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 170),
      constraints: BoxConstraints(minHeight: expand ? 48 : 42),
      padding: EdgeInsets.symmetric(
        horizontal: expand ? 14 : 12,
        vertical: expand ? 12 : 10,
      ),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.095)
            : scheme.surface.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.08 : 0.72,
              ),
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.78),
          width: selected ? 1.45 : 1,
        ),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (selected && isRtl) ...[
            Icon(Icons.check_circle_rounded, size: 19, color: scheme.primary),
            const SizedBox(width: 8),
          ],
          if (icon != null) ...[
            Icon(
              icon,
              size: 18,
              color: selected ? scheme.primary : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
          ],
          if (expand)
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? scheme.primary : scheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? scheme.primary : scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (selected && !isRtl) ...[
            const SizedBox(width: 8),
            Icon(Icons.check_circle_rounded, size: 19, color: scheme.primary),
          ],
          if (!selected && expand) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.radio_button_unchecked_rounded,
              size: 19,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.58),
            ),
          ],
        ],
      ),
    );
    return InkWell(
      borderRadius: radius,
      onTap: onTap,
      child: expand
          ? SizedBox(width: double.infinity, child: content)
          : content,
    );
  }
}

class FeedbackInfoChip extends StatelessWidget {
  const FeedbackInfoChip({required this.label, this.icon, super.key});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      height: 36,
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.42 : 0.64,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.62),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeedbackRatingButton extends StatelessWidget {
  const FeedbackRatingButton({
    required this.selected,
    required this.icon,
    required this.onPressed,
    this.emoji,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String? emoji;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final starLike =
        emoji == null &&
        (icon == Icons.star_rounded || icon == Icons.star_outline_rounded);
    return InkWell(
      borderRadius: BorderRadius.circular(starLike ? 999 : 18),
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: starLike ? 44 : 50,
        height: starLike ? 44 : 50,
        decoration: BoxDecoration(
          color: starLike
              ? Colors.transparent
              : selected
              ? scheme.primary.withValues(alpha: 0.12)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(starLike ? 999 : 18),
          border: starLike
              ? null
              : Border.all(
                  color: selected ? scheme.primary : scheme.outlineVariant,
                  width: selected ? 1.45 : 1,
                ),
        ),
        child: Center(
          child: emoji != null
              ? Text(emoji!, style: const TextStyle(fontSize: 26))
              : Icon(
                  selected ? Icons.star_rounded : Icons.star_rounded,
                  size: starLike ? 34 : 27,
                  color: selected
                      ? const Color(0xFFFFC857)
                      : scheme.outlineVariant,
                ),
        ),
      ),
    );
  }
}

class FeedbackInlinePanel extends StatelessWidget {
  const FeedbackInlinePanel({
    required this.icon,
    required this.title,
    required this.message,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: AppSpacing.card,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: scheme.primary),
          AppSpacing.gapHorizontalSm,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[AppSpacing.gapHorizontalSm, trailing!],
        ],
      ),
    );
  }
}

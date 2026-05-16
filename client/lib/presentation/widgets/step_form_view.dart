import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/dto/dto.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import 'field_renderer.dart';

/// A step-by-step form experience where each field occupies the full screen.
///
/// After answering, the user taps "Next" and slides to the next field with a
/// smooth animation. A progress bar at the top shows how far along they are.
/// The last step shows the submit button.
class StepFormView extends StatefulWidget {
  const StepFormView({
    super.key,
    required this.formTitle,
    required this.fields,
    required this.answers,
    required this.onAnswerChanged,
    required this.onSubmit,
    required this.submitting,
  });

  final String formTitle;
  final List<FormFieldDto> fields;
  final Map<String, Object?> answers;
  final void Function(String fieldId, Object? value) onAnswerChanged;
  final VoidCallback onSubmit;
  final bool submitting;

  @override
  State<StepFormView> createState() => _StepFormViewState();
}

class _StepFormViewState extends State<StepFormView>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  int _currentPage = 0;

  /// Only answerable fields (not layout-only like dividers/section titles).
  late List<FormFieldDto> _answerableFields;

  @override
  void initState() {
    super.initState();
    _answerableFields = widget.fields
        .where((f) => _fieldSubmitsAnswer(f.type))
        .toList(growable: false);
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant StepFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _answerableFields = widget.fields
          .where((f) => _fieldSubmitsAnswer(f.type))
          .toList(growable: false);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= _answerableFields.length - 1;
  double get _progress =>
      _answerableFields.isEmpty
          ? 1.0
          : (_currentPage + 1) / _answerableFields.length;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    if (_answerableFields.isEmpty) {
      return Center(
        child: Text(l10n.t('noFieldsYet')),
      );
    }

    return Column(
      children: [
        // --- Progress bar ---
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.xs,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${_currentPage + 1} / ${_answerableFields.length}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.formTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: _progress),
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 6,
                    backgroundColor:
                        scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),

        // --- Page view ---
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            reverse: Directionality.of(context) == TextDirection.rtl,
            itemCount: _answerableFields.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final field = _answerableFields[index];
              return _FieldPage(
                field: field,
                index: index,
                total: _answerableFields.length,
                value: widget.answers[field.id],
                onChanged: (value) =>
                    widget.onAnswerChanged(field.id, value),
              );
            },
          ),
        ),

        // --- Navigation buttons ---
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppBreakpoints.narrowContentMax,
              ),
              child: Row(
                children: [
                  // Next / Submit button (leading = start side)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: _isLastPage
                          ? FilledButton.icon(
                              onPressed:
                                  widget.submitting ? null : widget.onSubmit,
                              icon: widget.submitting
                                  ? const SizedBox.square(
                                      dimension: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              label: Text(
                                widget.submitting
                                    ? l10n.t('submitting')
                                    : l10n.t('submitResponse'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : FilledButton.icon(
                              onPressed: _goNext,
                              icon: Icon(
                                l10n.textDirection == TextDirection.rtl
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                              ),
                              label: Text(
                                l10n.t('next'),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  // Back button (trailing = end side)
                  if (_currentPage > 0)
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _goBack,
                          icon: Icon(
                            l10n.textDirection == TextDirection.rtl
                                ? Icons.arrow_forward_rounded
                                : Icons.arrow_back_rounded,
                          ),
                          label: Text(l10n.t('back')),
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _goNext() {
    if (_isLastPage) return;
    HapticFeedback.selectionClick();
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _goBack() {
    if (_currentPage <= 0) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }
}

/// A single field page with centered content.
class _FieldPage extends StatelessWidget {
  const _FieldPage({
    required this.field,
    required this.index,
    required this.total,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final int index;
  final int total;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppBreakpoints.narrowContentMax,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Field label
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          field.label,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (field.description != null &&
                            field.description!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            field.description!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (field.isRequired) ...[
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            context.l10n.t('required'),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              // Field input
              FieldRenderer(
                index: index,
                field: field,
                values: <String, Object?>{field.id: value},
                onChanged: onChanged,
                previewOnly: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _fieldSubmitsAnswer(FieldType type) {
  return type != FieldType.sectionTitle &&
      type != FieldType.descriptionBlock &&
      type != FieldType.divider &&
      type != FieldType.termsAcceptance;
}

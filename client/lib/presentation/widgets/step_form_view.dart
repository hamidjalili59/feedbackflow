import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/dto/dto.dart';
import '../theme/app_breakpoints.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import 'field_renderer.dart';

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

class _StepFormViewState extends State<StepFormView> {
  late final PageController _pageController;
  late List<FormFieldDto> _answerableFields;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _answerableFields = widget.fields.where((f) => _fieldSubmitsAnswer(f.type)).toList(growable: false);
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant StepFormView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fields != widget.fields) {
      _answerableFields = widget.fields.where((f) => _fieldSubmitsAnswer(f.type)).toList(growable: false);
      if (_currentPage >= _answerableFields.length) _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isLastPage => _currentPage >= _answerableFields.length - 1;
  double get _progress => _answerableFields.isEmpty ? 1 : (_currentPage + 1) / _answerableFields.length;

  @override
  Widget build(BuildContext context) {
    if (_answerableFields.isEmpty) return const Center(child: Text('هنوز پرسشی تعریف نشده است.'));
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 16, 32, 6),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded, color: AppTheme.ink),
                    ),
                    Expanded(
                      child: Text(
                        'پرسش ${_currentPage + 1} از ${_answerableFields.length}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: const Color(0xFF737B9A),
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _progress),
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) => SizedBox(
                      height: 8,
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: Colors.white,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            reverse: Directionality.of(context) == TextDirection.rtl,
            itemCount: _answerableFields.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemBuilder: (context, index) {
              final field = _answerableFields[index];
              return _QuestionPage(
                field: field,
                index: index,
                value: widget.answers[field.id],
                onChanged: (value) => widget.onAnswerChanged(field.id, value),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 12, 32, 26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppBreakpoints.narrowContentMax),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: FilledButton(
                      onPressed: widget.submitting ? null : (_isLastPage ? widget.onSubmit : _goNext),
                      child: widget.submitting
                          ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                          : Text(_isLastPage ? 'ثبت پاسخ' : 'بعدی'),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: _currentPage > 0 ? _goBack : null,
                    child: Text('قبلی', style: TextStyle(color: _currentPage > 0 ? const Color(0xFF9AA1B8) : const Color(0xFFC4CAD8), fontWeight: FontWeight.w900)),
                  ),
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
    _pageController.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  void _goBack() {
    if (_currentPage <= 0) return;
    HapticFeedback.selectionClick();
    _pageController.previousPage(duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }
}

class _QuestionPage extends StatelessWidget {
  const _QuestionPage({required this.field, required this.index, required this.value, required this.onChanged});

  final FormFieldDto field;
  final int index;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: AppBreakpoints.narrowContentMax),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                field.label,
                textAlign: TextAlign.right,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppTheme.ink,
                  fontWeight: FontWeight.w900,
                  height: 1.55,
                  letterSpacing: -0.45,
                ),
              ),
              if ((field.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(field.description!, textAlign: TextAlign.right, style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF858BA6))),
              ],
              const SizedBox(height: 26),
              FieldRenderer(
                index: index,
                field: field,
                values: <String, Object?>{field.id: value},
                onChanged: onChanged,
                previewOnly: false,
                wrapInCard: false,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

bool _fieldSubmitsAnswer(FieldType type) {
  return switch (type) {
    FieldType.sectionTitle ||
    FieldType.descriptionBlock ||
    FieldType.divider ||
    FieldType.pageBreak ||
    FieldType.scoreDisplay ||
    FieldType.calculated ||
    FieldType.hidden ||
    FieldType.conditionalLogic ||
    FieldType.unknown => false,
    _ => true,
  };
}

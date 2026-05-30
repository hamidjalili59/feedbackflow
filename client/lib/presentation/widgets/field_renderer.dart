// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';

import '../../data/dto/dto.dart';
import '../../l10n/app_localizations.dart';
import '../common/field_type_ui.dart';
import 'feedback_field_kit.dart';

class FieldRenderer extends StatelessWidget {
  const FieldRenderer({
    required this.index,
    required this.field,
    required this.values,
    required this.onChanged,
    this.previewOnly = true,
    this.wrapInCard = true,
    super.key,
  });

  final int index;
  final FormFieldDto field;
  final Map<String, Object?> values;
  final ValueChanged<Object?> onChanged;
  final bool previewOnly;
  final bool wrapInCard;

  Object? get _value => values[field.id];

  @override
  Widget build(BuildContext context) {
    if (!_fieldSubmitsAnswer(field.type)) return _LayoutField(field: field);

    final input = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldInput(field: field, value: _value, onChanged: onChanged),
        if (previewOnly) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.t('previewOnly'),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
    if (!wrapInCard) return input;
    return FeedbackFieldCard(
      index: index + 1,
      icon: fieldTypeInfo(field.type).icon,
      title: field.label,
      description: field.description,
      isRequired: field.isRequired,
      child: input,
    );
  }
}

class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return switch (field.type) {
      FieldType.shortText ||
      FieldType.email ||
      FieldType.phone ||
      FieldType.location => _TextInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.longText => _LongTextInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.number || FieldType.decimal => _NumberInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.date => _DateInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.time => _TimeInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.dateTime => _DateTimeInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.singleChoice ||
      FieldType.quizQuestion => _SingleChoiceInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.emojiReaction => _FaceScaleInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.multipleChoice => _MultiChoiceInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.dropdown => _DropdownInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.ratingStars => _StarRatingInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.numericRating => _NumericRatingInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.slider || FieldType.nps => _SliderInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.likertScale => _FaceScaleInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.matrixSingleChoice => _MatrixSingleChoiceInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.matrixMultipleChoice => _MatrixMultipleChoiceInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.yesNo => _YesNoInput(value: value, onChanged: onChanged),
      FieldType.booleanSwitch => _BooleanSwitchInput(
        value: value,
        onChanged: onChanged,
      ),
      FieldType.consentCheckbox || FieldType.termsAcceptance => _ConsentInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.fileUpload || FieldType.imageUpload => _UploadPreview(
        field: field,
        icon:
            field.type == FieldType.imageUpload
                ? Icons.image_outlined
                : Icons.upload_file_rounded,
      ),
      FieldType.signature => _SignaturePreview(onChanged: onChanged),
      FieldType.ranking => _RankingInput(
        field: field,
        value: value,
        onChanged: onChanged,
      ),
      FieldType.calculated ||
      FieldType.scoreDisplay => _ReadOnlyComputedField(field: field),
      FieldType.hidden ||
      FieldType.conditionalLogic ||
      FieldType.sectionTitle ||
      FieldType.descriptionBlock ||
      FieldType.divider ||
      FieldType.pageBreak ||
      FieldType.unknown => const SizedBox.shrink(),
    };
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: _keyboardType(field.type),
      decoration: InputDecoration(
        labelText:
            field.placeholder ?? context.l10n.fieldType(field.type.toJson()),
        prefixIcon: Icon(_textIcon(field.type)),
      ),
      onChanged: onChanged,
    );
  }
}

class _LongTextInput extends StatelessWidget {
  const _LongTextInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      minLines: 4,
      maxLines: 8,
      decoration: InputDecoration(
        labelText: field.placeholder ?? context.l10n.t('writeLongAnswer'),
        alignLabelWithHint: true,
        prefixIcon: const Icon(Icons.notes_rounded),
      ),
      onChanged: onChanged,
    );
  }
}

class _NumberInput extends StatelessWidget {
  const _NumberInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value?.toString() ?? '',
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
        signed: true,
      ),
      decoration: InputDecoration(
        labelText:
            field.placeholder ??
            (field.type == FieldType.decimal
                ? context.l10n.t('decimalNumber')
                : context.l10n.t('number')),
        prefixIcon: const Icon(Icons.pin_rounded),
      ),
      onChanged: (value) => onChanged(num.tryParse(value) ?? value),
    );
  }
}

class _DateInput extends StatelessWidget {
  const _DateInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PickerPanel(
      icon: Icons.calendar_today_rounded,
      label:
          value?.toString() ??
          field.placeholder ??
          context.l10n.t('chooseDate'),
      onTap: () async {
        final now = DateTime.now();
        final selected = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
          initialDate: now,
        );
        if (selected != null) {
          onChanged(selected.toIso8601String().split('T').first);
        }
      },
    );
  }
}

class _TimeInput extends StatelessWidget {
  const _TimeInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PickerPanel(
      icon: Icons.schedule_rounded,
      label:
          value?.toString() ??
          field.placeholder ??
          context.l10n.t('chooseTime'),
      onTap: () async {
        final selected = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (selected != null) {
          onChanged(
            '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}',
          );
        }
      },
    );
  }
}

class _DateTimeInput extends StatelessWidget {
  const _DateTimeInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _PickerPanel(
      icon: Icons.event_available_rounded,
      label:
          value?.toString() ??
          field.placeholder ??
          context.l10n.t('chooseDateTime'),
      onTap: () async {
        final now = DateTime.now();
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(now.year - 5),
          lastDate: DateTime(now.year + 5),
          initialDate: now,
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (time == null) return;
        onChanged(
          DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          ).toIso8601String(),
        );
      },
    );
  }
}

class _PickerPanel extends StatelessWidget {
  const _PickerPanel({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            const Icon(Icons.expand_more_rounded),
          ],
        ),
      ),
    );
  }
}

class _SingleChoiceInput extends StatelessWidget {
  const _SingleChoiceInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final option in _options(field)) ...[
          Builder(
            builder: (context) {
              final selected = _sameOption(value, option);
              return FeedbackOptionChip(
                selected: selected,
                label: _localizedOptionLabel(context, option),
                icon:
                    field.type == FieldType.emojiReaction
                        ? Icons.mood_rounded
                        : selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                expand: field.type != FieldType.emojiReaction,
                onTap: () => onChanged(_optionValue(option)),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _MultiChoiceInput extends StatelessWidget {
  const _MultiChoiceInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected =
        value is List ? Set<Object?>.from(value as List) : <Object?>{};
    return Column(
      children: [
        for (final option in _options(field)) ...[
          FeedbackOptionChip(
            selected: selected.contains(_optionValue(option)),
            label: _localizedOptionLabel(context, option),
            icon:
                selected.contains(_optionValue(option))
                    ? Icons.done_rounded
                    : Icons.add_rounded,
            expand: true,
            onTap: () {
              final next = {...selected};
              final optionValue = _optionValue(option);
              next.contains(optionValue)
                  ? next.remove(optionValue)
                  : next.add(optionValue);
              onChanged(next.toList(growable: false));
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _DropdownInput extends StatelessWidget {
  const _DropdownInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final optionValues =
        _options(
          field,
        ).map((option) => _optionValue(option).toString()).toSet();
    final current =
        value == null || !optionValues.contains(value.toString())
            ? null
            : value.toString();
    return DropdownButtonFormField<String>(
      initialValue: current,
      decoration: InputDecoration(
        labelText: context.l10n.t('chooseOption'),
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined),
      ),
      items: [
        for (final option in _options(field))
          DropdownMenuItem<String>(
            value: _optionValue(option).toString(),
            child: Text(_localizedOptionLabel(context, option)),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

class _StarRatingInput extends StatelessWidget {
  const _StarRatingInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = value is num ? (value as num).toInt() : 0;
    final max = (field.config.max ?? 5).round().clamp(1, 10);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var rating = 1; rating <= max; rating++)
          FeedbackRatingButton(
            selected: rating <= current,
            icon:
                rating <= current
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
            onPressed: () => onChanged(rating),
          ),
      ],
    );
  }
}

class _NumericRatingInput extends StatelessWidget {
  const _NumericRatingInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = (field.config.min ?? 1).round();
    final max = (field.config.max ?? 5).round();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var rating = min; rating <= max; rating++)
          SizedBox(
            height: 42,
            child: ChoiceChip(
              selected: value == rating,
              label: Text('$rating', maxLines: 1),
              onSelected: (_) => onChanged(rating),
            ),
          ),
      ],
    );
  }
}

class _SliderInput extends StatelessWidget {
  const _SliderInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final min = field.config.min ?? (field.type == FieldType.nps ? 0 : 1);
    final max = field.config.max ?? (field.type == FieldType.nps ? 10 : 5);
    final step = field.config.step ?? 1;
    final divisions = step <= 0 ? null : ((max - min) / step).round();
    final current =
        value is num
            ? (value as num).toDouble().clamp(min, max).toDouble()
            : min;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(min.toStringAsFixed(min % 1 == 0 ? 0 : 1)),
            Expanded(
              child: Slider(
                min: min,
                max: max,
                divisions:
                    divisions != null && divisions > 0 ? divisions : null,
                value: current,
                label: current.toStringAsFixed(current % 1 == 0 ? 0 : 1),
                onChanged: onChanged,
              ),
            ),
            Text(max.toStringAsFixed(max % 1 == 0 ? 0 : 1)),
          ],
        ),
        Center(
          child: Text(
            '${context.l10n.t('selectedValue')}: ${current.toStringAsFixed(current % 1 == 0 ? 0 : 1)}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _FaceScaleInput extends StatelessWidget {
  const _FaceScaleInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = field.type == FieldType.likertScale
        ? (field.config.columns?.isNotEmpty == true ? field.config.columns! : _faceLikertOptions)
        : (_options(field).isNotEmpty ? _options(field) : _faceLikertOptions);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: Directionality.of(context) == TextDirection.rtl,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < options.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: _FaceOptionButton(
                    emoji: _emojiForIndex(i, options.length, options[i]),
                    label: _localizedOptionLabel(context, options[i]),
                    selected: _sameOption(value, options[i]),
                    onTap: () => onChanged(_optionValue(options[i])),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          value == null ? 'یک گزینه را انتخاب کنید' : _selectedFaceLabel(context, value, options),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _FaceOptionButton extends StatelessWidget {
  const _FaceOptionButton({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF31C779) : Colors.transparent;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          width: selected ? 58 : 50,
          height: selected ? 58 : 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? const Color(0xFFDDF8EA) : Colors.white,
            border: Border.all(color: selected ? color : const Color(0xFFE4E9F3), width: selected ? 3 : 1),
            boxShadow: selected
                ? [BoxShadow(blurRadius: 18, offset: const Offset(0, 8), color: color.withValues(alpha: 0.18))]
                : null,
          ),
          child: Text(emoji, style: TextStyle(fontSize: selected ? 32 : 28)),
        ),
      ),
    );
  }
}

class _MatrixSingleChoiceInput extends StatelessWidget {
  const _MatrixSingleChoiceInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final rowValues =
        value is Map
            ? Map<String, Object?>.from(value as Map)
            : <String, Object?>{};
    return _MatrixShell(
      rows: _rows(field),
      columns: _columns(field),
      cellBuilder:
          (row, column) => Radio<Object?>(
            value: _optionValue(column),
            groupValue: rowValues[row.id],
            onChanged:
                (selected) => onChanged({...rowValues, row.id: selected}),
          ),
    );
  }
}

class _MatrixMultipleChoiceInput extends StatelessWidget {
  const _MatrixMultipleChoiceInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final rowValues =
        value is Map
            ? Map<String, Object?>.from(value as Map)
            : <String, Object?>{};
    return _MatrixShell(
      rows: _rows(field),
      columns: _columns(field),
      cellBuilder: (row, column) {
        final selected =
            rowValues[row.id] is List
                ? Set<Object?>.from(rowValues[row.id] as List)
                : <Object?>{};
        final optionValue = _optionValue(column);
        return Checkbox(
          value: selected.contains(optionValue),
          onChanged: (_) {
            final next = {...selected};
            next.contains(optionValue)
                ? next.remove(optionValue)
                : next.add(optionValue);
            onChanged({...rowValues, row.id: next.toList(growable: false)});
          },
        );
      },
    );
  }
}

class _MatrixShell extends StatelessWidget {
  const _MatrixShell({
    required this.rows,
    required this.columns,
    required this.cellBuilder,
  });

  final List<FieldOptionDto> rows;
  final List<FieldOptionDto> columns;
  final Widget Function(FieldOptionDto row, FieldOptionDto column) cellBuilder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          const DataColumn(label: Text('')),
          for (final column in columns)
            DataColumn(
              label: Text(
                _localizedOptionLabel(context, column),
                style: theme.textTheme.labelLarge,
              ),
            ),
        ],
        rows: [
          for (final row in rows)
            DataRow(
              cells: [
                DataCell(
                  Text(
                    _localizedOptionLabel(context, row),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
                for (final column in columns)
                  DataCell(Center(child: cellBuilder(row, column))),
              ],
            ),
        ],
      ),
    );
  }
}

class _YesNoInput extends StatelessWidget {
  const _YesNoInput({required this.value, required this.onChanged});

  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        FeedbackOptionChip(
          label: context.l10n.t('yes'),
          selected: value == true,
          icon: Icons.thumb_up_alt_outlined,
          onTap: () => onChanged(true),
        ),
        FeedbackOptionChip(
          label: context.l10n.t('no'),
          selected: value == false,
          icon: Icons.thumb_down_alt_outlined,
          onTap: () => onChanged(false),
        ),
      ],
    );
  }
}

class _BooleanSwitchInput extends StatelessWidget {
  const _BooleanSwitchInput({required this.value, required this.onChanged});

  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FeedbackInlinePanel(
      icon: Icons.toggle_on_rounded,
      title:
          value == true
              ? context.l10n.t('enabled')
              : context.l10n.t('disabled'),
      message: context.l10n.t('useSwitch'),
      trailing: Switch(value: value == true, onChanged: onChanged),
    );
  }
}

class _ConsentInput extends StatelessWidget {
  const _ConsentInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    return FeedbackInlinePanel(
      icon: Icons.verified_user_outlined,
      title:
          field.type == FieldType.termsAcceptance
              ? context.l10n.t('termsAcceptance')
              : context.l10n.t('consentCheckbox'),
      message: field.description ?? field.label,
      trailing: Checkbox(value: value == true, onChanged: onChanged),
    );
  }
}

class _UploadPreview extends StatelessWidget {
  const _UploadPreview({required this.field, required this.icon});

  final FormFieldDto field;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final mime = field.config.acceptMimeTypes?.join(', ');
    final size = field.config.maxFileSizeMb;
    return FeedbackInlinePanel(
      icon: icon,
      title:
          field.type == FieldType.imageUpload
              ? context.l10n.t('imageUploadPreview')
              : context.l10n.t('fileUploadPreview'),
      message: [
        if (mime != null && mime.isNotEmpty)
          '${context.l10n.t('allowed')}: $mime',
        if (size != null) '${context.l10n.t('maxSize')}: ${size}MB',
        if (mime == null && size == null) context.l10n.t('uploadPickerShown'),
      ].join(' • '),
      trailing: OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.upload_rounded),
        label: Text(context.l10n.t('upload')),
      ),
    );
  }
}

class _SignaturePreview extends StatelessWidget {
  const _SignaturePreview({required this.onChanged});

  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => onChanged('preview_signature'),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Center(
          child: Text(
            context.l10n.t('tapAreaToSign'),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class _RankingInput extends StatelessWidget {
  const _RankingInput({
    required this.field,
    required this.value,
    required this.onChanged,
  });

  final FormFieldDto field;
  final Object? value;
  final ValueChanged<Object?> onChanged;

  @override
  Widget build(BuildContext context) {
    final configuredOptions = _options(field);
    final current =
        value is List
            ? List<Object?>.from(value as List)
            : configuredOptions.map(_optionValue).toList(growable: false);
    final byValue = {
      for (final option in configuredOptions)
        _optionValue(option).toString(): _localizedOptionLabel(context, option),
    };
    return Column(
      children: [
        for (var index = 0; index < current.length; index++)
          ListTile(
            dense: true,
            leading: CircleAvatar(child: Text('${index + 1}')),
            title: Text(
              byValue[current[index].toString()] ?? current[index].toString(),
            ),
            trailing: Wrap(
              children: [
                IconButton(
                  tooltip: context.l10n.t('moveUp'),
                  onPressed:
                      index == 0
                          ? null
                          : () {
                            final next = [...current];
                            final item = next.removeAt(index);
                            next.insert(index - 1, item);
                            onChanged(next);
                          },
                  icon: const Icon(Icons.keyboard_arrow_up_rounded),
                ),
                IconButton(
                  tooltip: context.l10n.t('moveDown'),
                  onPressed:
                      index == current.length - 1
                          ? null
                          : () {
                            final next = [...current];
                            final item = next.removeAt(index);
                            next.insert(index + 1, item);
                            onChanged(next);
                          },
                  icon: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ReadOnlyComputedField extends StatelessWidget {
  const _ReadOnlyComputedField({required this.field});

  final FormFieldDto field;

  @override
  Widget build(BuildContext context) {
    return FeedbackInlinePanel(
      icon:
          field.type == FieldType.scoreDisplay
              ? Icons.scoreboard_rounded
              : Icons.functions_rounded,
      title:
          field.type == FieldType.scoreDisplay
              ? context.l10n.t('scoreDisplay')
              : context.l10n.t('calculatedField'),
      message: context.l10n.t('computedByBackend'),
    );
  }
}

class _LayoutField extends StatelessWidget {
  const _LayoutField({required this.field});

  final FormFieldDto field;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (field.type == FieldType.sectionTitle) {
      return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(
          field.config.pageTitle ?? field.label,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
          ),
        ),
      );
    }
    if (field.type == FieldType.descriptionBlock) {
      return FeedbackInlinePanel(
        icon: Icons.info_outline_rounded,
        title: field.label,
        message: field.config.staticText ?? field.description ?? field.label,
      );
    }
    if (field.type == FieldType.divider) return const Divider(height: 40);
    if (field.type == FieldType.pageBreak) {
      return FeedbackInlinePanel(
        icon: Icons.auto_stories_rounded,
        title: field.label,
        message: context.l10n.t('pageBreakMessage'),
      );
    }
    if (field.type == FieldType.hidden ||
        field.type == FieldType.conditionalLogic) {
      return const SizedBox.shrink();
    }
    return const SizedBox.shrink();
  }
}

TextInputType _keyboardType(FieldType type) {
  return switch (type) {
    FieldType.email => TextInputType.emailAddress,
    FieldType.phone => TextInputType.phone,
    FieldType.number ||
    FieldType.decimal => const TextInputType.numberWithOptions(decimal: true),
    _ => TextInputType.text,
  };
}

IconData _textIcon(FieldType type) {
  return switch (type) {
    FieldType.email => Icons.alternate_email_rounded,
    FieldType.phone => Icons.phone_rounded,
    FieldType.location => Icons.location_on_outlined,
    _ => Icons.short_text_rounded,
  };
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

List<FieldOptionDto> _options(FormFieldDto field) {
  final options = field.config.options ?? field.config.rows;
  if (options != null && options.isNotEmpty) {
    return [...options]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  if (field.type == FieldType.emojiReaction) return _emojiOptions;
  if (field.type == FieldType.yesNo) return _yesNoOptions;
  return _defaultChoiceOptions;
}

List<FieldOptionDto> _rows(FormFieldDto field) {
  final rows = field.config.rows;
  if (rows != null && rows.isNotEmpty) {
    return [...rows]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  return const <FieldOptionDto>[
    FieldOptionDto(id: 'row_1', label: 'Row 1', value: 'row_1', orderIndex: 0),
    FieldOptionDto(id: 'row_2', label: 'Row 2', value: 'row_2', orderIndex: 1),
  ];
}

List<FieldOptionDto> _columns(FormFieldDto field) {
  final columns = field.config.columns ?? field.config.options;
  if (columns != null && columns.isNotEmpty) {
    return [...columns]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }
  return _likertOptions;
}

String _localizedOptionLabel(BuildContext context, FieldOptionDto option) {
  final id = option.id;
  if (id == 'option_1') return context.l10n.t('option1');
  if (id == 'option_2') return context.l10n.t('option2');
  if (id == 'option_3') return context.l10n.t('option3');
  if (id == 'row_1') return context.l10n.t('row1');
  if (id == 'row_2') return context.l10n.t('row2');
  if (id == 'row_3') return context.l10n.t('row3');
  if (id == 'column_1') return context.l10n.t('column1');
  if (id == 'column_2') return context.l10n.t('column2');
  if (id == 'column_3') return context.l10n.t('column3');
  if (id == 'yes') return context.l10n.t('yes');
  if (id == 'no') return context.l10n.t('no');
  if (id == 'love') return context.l10n.t('loveIt');
  if (id == 'happy') return context.l10n.t('good');
  if (id == 'neutral') return context.l10n.t('neutral');
  if (id == 'sad') return context.l10n.t('notGreat');
  if (id == 'strongly_disagree') return context.l10n.t('stronglyDisagree');
  if (id == 'disagree') return context.l10n.t('disagree');
  if (id == 'agree') return context.l10n.t('agree');
  if (id == 'strongly_agree') return context.l10n.t('stronglyAgree');
  return option.label;
}

Object? _optionValue(FieldOptionDto option) => option.value ?? option.id;

bool _sameOption(Object? value, FieldOptionDto option) =>
    value?.toString() == _optionValue(option).toString();


const _faceLikertOptions = <FieldOptionDto>[
  FieldOptionDto(id: 'very_bad', label: 'خیلی ناراضی', value: 'very_bad', orderIndex: 0),
  FieldOptionDto(id: 'bad', label: 'ناراضی', value: 'bad', orderIndex: 1),
  FieldOptionDto(id: 'neutral', label: 'معمولی', value: 'neutral', orderIndex: 2),
  FieldOptionDto(id: 'happy', label: 'خوشحال', value: 'happy', orderIndex: 3),
  FieldOptionDto(id: 'very_happy', label: 'خیلی خوشحال', value: 'very_happy', orderIndex: 4),
];

String _emojiForIndex(int index, int total, FieldOptionDto option) {
  final label = option.label;
  if (label.contains('😡') || label.contains('😠')) return '😡';
  if (label.contains('🙁') || label.contains('☹') || label.contains('😞')) return '🙁';
  if (label.contains('😐') || label.contains('😶')) return '😐';
  if (label.contains('😊') || label.contains('🙂') || label.contains('😃')) return '😊';
  if (label.contains('😍') || label.contains('😁')) return '🙂';
  const faces = ['😡', '🙁', '😐', '😊', '🙂'];
  if (total <= 1) return faces[2];
  final mapped = (index * (faces.length - 1) / (total - 1)).round().clamp(0, faces.length - 1);
  return faces[mapped];
}

String _selectedFaceLabel(BuildContext context, Object? value, List<FieldOptionDto> options) {
  for (final option in options) {
    if (_sameOption(value, option)) return _localizedOptionLabel(context, option);
  }
  return value?.toString() ?? '';
}

const _defaultChoiceOptions = <FieldOptionDto>[
  FieldOptionDto(
    id: 'option_1',
    label: 'Option 1',
    value: 'option_1',
    orderIndex: 0,
  ),
  FieldOptionDto(
    id: 'option_2',
    label: 'Option 2',
    value: 'option_2',
    orderIndex: 1,
  ),
];

const _yesNoOptions = <FieldOptionDto>[
  FieldOptionDto(id: 'yes', label: 'Yes', value: true, orderIndex: 0),
  FieldOptionDto(id: 'no', label: 'No', value: false, orderIndex: 1),
];

const _emojiOptions = <FieldOptionDto>[
  FieldOptionDto(id: 'love', label: '😍 Love it', value: 'love', orderIndex: 0),
  FieldOptionDto(id: 'happy', label: '🙂 Good', value: 'happy', orderIndex: 1),
  FieldOptionDto(
    id: 'neutral',
    label: '😐 Neutral',
    value: 'neutral',
    orderIndex: 2,
  ),
  FieldOptionDto(id: 'sad', label: '🙁 Not great', value: 'sad', orderIndex: 3),
];

const _likertOptions = <FieldOptionDto>[
  FieldOptionDto(
    id: 'strongly_disagree',
    label: 'Strongly disagree',
    value: 'strongly_disagree',
    orderIndex: 0,
  ),
  FieldOptionDto(
    id: 'disagree',
    label: 'Disagree',
    value: 'disagree',
    orderIndex: 1,
  ),
  FieldOptionDto(
    id: 'neutral',
    label: 'Neutral',
    value: 'neutral',
    orderIndex: 2,
  ),
  FieldOptionDto(id: 'agree', label: 'Agree', value: 'agree', orderIndex: 3),
  FieldOptionDto(
    id: 'strongly_agree',
    label: 'Strongly agree',
    value: 'strongly_agree',
    orderIndex: 4,
  ),
];

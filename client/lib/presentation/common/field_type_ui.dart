import 'package:flutter/material.dart';

import '../../data/dto/dto.dart';
import '../../l10n/app_localizations.dart';

enum FieldTypeCategory { essentials, choices, ratings, layout, advanced }

extension FieldTypeCategoryUi on FieldTypeCategory {
  String get label => switch (this) {
    FieldTypeCategory.essentials => 'Essentials',
    FieldTypeCategory.choices => 'Choices',
    FieldTypeCategory.ratings => 'Ratings',
    FieldTypeCategory.layout => 'Layout',
    FieldTypeCategory.advanced => 'Advanced',
  };

  IconData get icon => switch (this) {
    FieldTypeCategory.essentials => Icons.text_fields_rounded,
    FieldTypeCategory.choices => Icons.checklist_rounded,
    FieldTypeCategory.ratings => Icons.star_rate_rounded,
    FieldTypeCategory.layout => Icons.view_agenda_rounded,
    FieldTypeCategory.advanced => Icons.tune_rounded,
  };
}

class FieldTypeInfo {
  const FieldTypeInfo({
    required this.type,
    required this.label,
    required this.description,
    required this.icon,
    required this.category,
  });

  final FieldType type;
  final String label;
  final String description;
  final IconData icon;
  final FieldTypeCategory category;
}

const fieldTypeCatalog = <FieldTypeInfo>[
  FieldTypeInfo(
    type: FieldType.shortText,
    label: 'Short text',
    description: 'One-line answer',
    icon: Icons.short_text_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.longText,
    label: 'Long text',
    description: 'Paragraph answer',
    icon: Icons.notes_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.email,
    label: 'Email',
    description: 'Validated email answer',
    icon: Icons.alternate_email_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.phone,
    label: 'Phone',
    description: 'Phone number answer',
    icon: Icons.phone_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.number,
    label: 'Number',
    description: 'Whole number input',
    icon: Icons.pin_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.decimal,
    label: 'Decimal',
    description: 'Decimal number input',
    icon: Icons.numbers_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.date,
    label: 'Date',
    description: 'Calendar date',
    icon: Icons.calendar_today_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.time,
    label: 'Time',
    description: 'Time picker',
    icon: Icons.schedule_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.dateTime,
    label: 'Date and time',
    description: 'Date plus time',
    icon: Icons.event_rounded,
    category: FieldTypeCategory.essentials,
  ),
  FieldTypeInfo(
    type: FieldType.singleChoice,
    label: 'Single choice',
    description: 'Select one option',
    icon: Icons.radio_button_checked_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.multipleChoice,
    label: 'Multiple choice',
    description: 'Select many options',
    icon: Icons.check_box_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.dropdown,
    label: 'Dropdown',
    description: 'Compact choice list',
    icon: Icons.arrow_drop_down_circle_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.matrixSingleChoice,
    label: 'Matrix single choice',
    description: 'Rows and one choice per row',
    icon: Icons.grid_on_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.matrixMultipleChoice,
    label: 'Matrix multiple choice',
    description: 'Rows and many choices per row',
    icon: Icons.grid_view_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.yesNo,
    label: 'Yes / No',
    description: 'Binary answer',
    icon: Icons.thumbs_up_down_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.booleanSwitch,
    label: 'Switch',
    description: 'On/off answer',
    icon: Icons.toggle_on_rounded,
    category: FieldTypeCategory.choices,
  ),
  FieldTypeInfo(
    type: FieldType.ratingStars,
    label: 'Star rating',
    description: 'Rate with stars',
    icon: Icons.star_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.numericRating,
    label: 'Numeric rating',
    description: 'Numeric scale',
    icon: Icons.format_list_numbered_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.slider,
    label: 'Slider',
    description: 'Range slider',
    icon: Icons.tune_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.likertScale,
    label: 'Likert scale',
    description: 'Agreement scale',
    icon: Icons.view_week_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.nps,
    label: 'NPS',
    description: '0-10 promoter score',
    icon: Icons.sentiment_satisfied_alt_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.emojiReaction,
    label: 'Emoji reaction',
    description: 'Quick sentiment',
    icon: Icons.emoji_emotions_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.ranking,
    label: 'Ranking',
    description: 'Order options',
    icon: Icons.sort_rounded,
    category: FieldTypeCategory.ratings,
  ),
  FieldTypeInfo(
    type: FieldType.sectionTitle,
    label: 'Section title',
    description: 'Visual heading',
    icon: Icons.title_rounded,
    category: FieldTypeCategory.layout,
  ),
  FieldTypeInfo(
    type: FieldType.descriptionBlock,
    label: 'Description block',
    description: 'Static text block',
    icon: Icons.article_rounded,
    category: FieldTypeCategory.layout,
  ),
  FieldTypeInfo(
    type: FieldType.divider,
    label: 'Divider',
    description: 'Visual separator',
    icon: Icons.horizontal_rule_rounded,
    category: FieldTypeCategory.layout,
  ),
  FieldTypeInfo(
    type: FieldType.pageBreak,
    label: 'Page break',
    description: 'Split form pages',
    icon: Icons.layers_rounded,
    category: FieldTypeCategory.layout,
  ),
  FieldTypeInfo(
    type: FieldType.fileUpload,
    label: 'File upload',
    description: 'Attach files',
    icon: Icons.attach_file_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.imageUpload,
    label: 'Image upload',
    description: 'Attach images',
    icon: Icons.image_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.signature,
    label: 'Signature',
    description: 'Capture signature',
    icon: Icons.draw_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.location,
    label: 'Location',
    description: 'Capture location',
    icon: Icons.location_on_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.consentCheckbox,
    label: 'Consent checkbox',
    description: 'Required consent',
    icon: Icons.verified_user_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.termsAcceptance,
    label: 'Terms acceptance',
    description: 'Terms confirmation',
    icon: Icons.gavel_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.hidden,
    label: 'Hidden',
    description: 'Hidden value',
    icon: Icons.visibility_off_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.calculated,
    label: 'Calculated',
    description: 'Computed value',
    icon: Icons.functions_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.conditionalLogic,
    label: 'Conditional logic',
    description: 'Show/hide rules',
    icon: Icons.account_tree_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.scoreDisplay,
    label: 'Score display',
    description: 'Show computed score',
    icon: Icons.score_rounded,
    category: FieldTypeCategory.advanced,
  ),
  FieldTypeInfo(
    type: FieldType.quizQuestion,
    label: 'Quiz question',
    description: 'Scored quiz prompt',
    icon: Icons.quiz_rounded,
    category: FieldTypeCategory.advanced,
  ),
];

FieldTypeInfo fieldTypeInfo(FieldType type) {
  return fieldTypeCatalog.firstWhere(
    (item) => item.type == type,
    orElse: () => FieldTypeInfo(
      type: type,
      label: type == FieldType.unknown
          ? 'Unknown field'
          : _titleFromWire(type.toJson()),
      description: type == FieldType.unknown
          ? 'Unsupported field returned by the server'
          : type.toJson(),
      icon: Icons.extension_rounded,
      category: FieldTypeCategory.advanced,
    ),
  );
}

String _titleFromWire(String wire) {
  return wire
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

extension LocalizedFieldTypeCategoryUi on FieldTypeCategory {
  String localizedLabel(BuildContext context) => context.l10n.t(switch (this) {
    FieldTypeCategory.essentials => 'fieldCategory.essentials',
    FieldTypeCategory.choices => 'fieldCategory.choices',
    FieldTypeCategory.ratings => 'fieldCategory.ratings',
    FieldTypeCategory.layout => 'fieldCategory.layout',
    FieldTypeCategory.advanced => 'fieldCategory.advanced',
  });
}

extension LocalizedFieldTypeInfo on FieldTypeInfo {
  String localizedLabel(BuildContext context) =>
      context.l10n.fieldType(type.toJson());
  String localizedDescription(BuildContext context) =>
      context.l10n.t('fieldDesc.${type.toJson()}');
}

bool fieldTypeUsesOptions(FieldType type) {
  return switch (type) {
    FieldType.singleChoice ||
    FieldType.multipleChoice ||
    FieldType.dropdown ||
    FieldType.ranking ||
    FieldType.quizQuestion => true,
    _ => false,
  };
}

bool fieldTypeUsesMatrix(FieldType type) {
  return type == FieldType.matrixSingleChoice ||
      type == FieldType.matrixMultipleChoice;
}

bool fieldTypeUsesRange(FieldType type) {
  return switch (type) {
    FieldType.number ||
    FieldType.decimal ||
    FieldType.ratingStars ||
    FieldType.numericRating ||
    FieldType.slider ||
    FieldType.nps => true,
    _ => false,
  };
}

bool fieldTypeIsInformational(FieldType type) {
  return switch (type) {
    FieldType.sectionTitle ||
    FieldType.descriptionBlock ||
    FieldType.divider ||
    FieldType.pageBreak ||
    FieldType.scoreDisplay ||
    FieldType.hidden ||
    FieldType.calculated ||
    FieldType.conditionalLogic ||
    FieldType.unknown => true,
    _ => false,
  };
}

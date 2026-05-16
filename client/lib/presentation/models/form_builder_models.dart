import '../../data/dto/dto.dart';

int _draftSeed = 0;
String _newDraftId() => 'draft_${DateTime.now().microsecondsSinceEpoch}_${_draftSeed++}';

enum FormTemplateType {
  blank,
  feedbackSurvey,
  quiz,
  registration,
  consent,
  riskAssessment,
}

class FormTemplatePreset {
  const FormTemplatePreset({
    required this.type,
    required this.name,
    required this.subtitle,
    required this.defaultTitle,
    required this.defaultDescription,
    required this.scoringMode,
    required this.visibilityMode,
    required this.allowAnonymousAnswers,
    required this.oneSubmissionPerUser,
    required this.answersEditableAfterSubmission,
    required this.guestsCanAnswer,
    required this.fields,
  });

  final FormTemplateType type;
  final String name;
  final String subtitle;
  final String defaultTitle;
  final String defaultDescription;
  final ScoringMode scoringMode;
  final VisibilityMode visibilityMode;
  final bool allowAnonymousAnswers;
  final bool oneSubmissionPerUser;
  final bool answersEditableAfterSubmission;
  final bool guestsCanAnswer;
  final List<DraftFormField> fields;
}

class FormTemplateCatalog {
  const FormTemplateCatalog._();

  static List<FormTemplatePreset> get presets => <FormTemplatePreset>[
        const FormTemplatePreset(
          type: FormTemplateType.blank,
          name: 'فرم خالی',
          subtitle: 'از ابتدا با فیلدهای دلخواه شروع کنید.',
          defaultTitle: 'فرم بدون عنوان',
          defaultDescription: '',
          scoringMode: ScoringMode.none,
          visibilityMode: VisibilityMode.private,
          allowAnonymousAnswers: false,
          oneSubmissionPerUser: true,
          answersEditableAfterSubmission: false,
          guestsCanAnswer: false,
          fields: <DraftFormField>[],
        ),
        FormTemplatePreset(
          type: FormTemplateType.feedbackSurvey,
          name: 'نظرسنجی بازخورد',
          subtitle: 'NPS، امتیازدهی و بازخورد آزاد.',
          defaultTitle: 'نظرسنجی بازخورد',
          defaultDescription: 'به ما کمک کنید بفهمیم چه چیزهایی خوب کار می‌کند و چه چیزهایی نیاز به بهبود دارد.',
          scoringMode: ScoringMode.satisfaction,
          visibilityMode: VisibilityMode.organization,
          allowAnonymousAnswers: true,
          oneSubmissionPerUser: false,
          answersEditableAfterSubmission: false,
          guestsCanAnswer: false,
          fields: <DraftFormField>[
            DraftFormField.seed(type: FieldType.nps, label: 'چقدر احتمال دارد ما را پیشنهاد کنید؟', isRequired: true, scoringEnabled: true),
            DraftFormField.seed(type: FieldType.ratingStars, label: 'تجربه کلی شما', isRequired: true, scoringEnabled: true),
            DraftFormField.seed(type: FieldType.longText, label: 'چه چیزی را باید بهتر کنیم؟', placeholder: 'ایده‌های خود را بنویسید...', isRequired: false),
          ],
        ),
        FormTemplatePreset(
          type: FormTemplateType.quiz,
          name: 'آزمون',
          subtitle: 'سؤال‌ها با امتیازدهی گزینه‌ای.',
          defaultTitle: 'سنجش دانش',
          defaultDescription: 'به هر سؤال پاسخ دهید و امتیاز خود را ثبت کنید.',
          scoringMode: ScoringMode.quiz,
          visibilityMode: VisibilityMode.organization,
          allowAnonymousAnswers: false,
          oneSubmissionPerUser: true,
          answersEditableAfterSubmission: false,
          guestsCanAnswer: false,
          fields: <DraftFormField>[
            DraftFormField.seed(type: FieldType.shortText, label: 'نام دانش‌آموز', isRequired: true),
            DraftFormField.seed(
              type: FieldType.singleChoice,
              label: 'کدام پاسخ درست است؟',
              isRequired: true,
              options: <String>['گزینه الف', 'گزینه ب', 'گزینه ج'],
              scoringEnabled: true,
            ),
            DraftFormField.seed(type: FieldType.longText, label: 'پاسخ خود را توضیح دهید', isRequired: false),
          ],
        ),
        FormTemplatePreset(
          type: FormTemplateType.registration,
          name: 'ثبت‌نام',
          subtitle: 'اطلاعات تماس و ترجیحات را جمع‌آوری کنید.',
          defaultTitle: 'فرم ثبت‌نام',
          defaultDescription: 'به ما بگویید چگونه با شما تماس بگیریم.',
          scoringMode: ScoringMode.none,
          visibilityMode: VisibilityMode.publicLink,
          allowAnonymousAnswers: false,
          oneSubmissionPerUser: false,
          answersEditableAfterSubmission: true,
          guestsCanAnswer: true,
          fields: <DraftFormField>[
            DraftFormField.seed(type: FieldType.shortText, label: 'نام کامل', isRequired: true),
            DraftFormField.seed(type: FieldType.email, label: 'آدرس ایمیل', isRequired: true),
            DraftFormField.seed(type: FieldType.phone, label: 'شماره تلفن', isRequired: false),
            DraftFormField.seed(type: FieldType.dropdown, label: 'جلسه ترجیحی', options: <String>['صبح', 'بعدازظهر', 'عصر'], isRequired: true),
          ],
        ),
        FormTemplatePreset(
          type: FormTemplateType.consent,
          name: 'رضایت‌نامه',
          subtitle: 'شرایط، تأیید رضایت و امضا.',
          defaultTitle: 'فرم رضایت‌نامه',
          defaultDescription: 'لطفاً مطالعه کنید و رضایت خود را تأیید کنید.',
          scoringMode: ScoringMode.none,
          visibilityMode: VisibilityMode.private,
          allowAnonymousAnswers: false,
          oneSubmissionPerUser: true,
          answersEditableAfterSubmission: false,
          guestsCanAnswer: false,
          fields: <DraftFormField>[
            DraftFormField.seed(type: FieldType.descriptionBlock, label: 'لطفاً پیش از ادامه، شرایط را مطالعه کنید.', isRequired: false),
            DraftFormField.seed(type: FieldType.termsAcceptance, label: 'شرایط و مقررات را می‌پذیرم', isRequired: true),
            DraftFormField.seed(type: FieldType.consentCheckbox, label: 'با پردازش پاسخ خود موافقم', isRequired: true),
            DraftFormField.seed(type: FieldType.signature, label: 'امضا', isRequired: true),
          ],
        ),
        FormTemplatePreset(
          type: FormTemplateType.riskAssessment,
          name: 'ارزیابی ریسک',
          subtitle: 'اسلایدرهای وزن‌دار و بررسی‌های بله/خیر.',
          defaultTitle: 'ارزیابی ریسک',
          defaultDescription: 'شاخص‌های ریسک را ثبت کنید و امتیاز وزن‌دار محاسبه کنید.',
          scoringMode: ScoringMode.riskAssessment,
          visibilityMode: VisibilityMode.organization,
          allowAnonymousAnswers: false,
          oneSubmissionPerUser: false,
          answersEditableAfterSubmission: true,
          guestsCanAnswer: false,
          fields: <DraftFormField>[
            DraftFormField.seed(type: FieldType.yesNo, label: 'آیا ریسک ایمنی فوری وجود دارد؟', isRequired: true, scoringEnabled: true),
            DraftFormField.seed(type: FieldType.slider, label: 'سطح اثرگذاری', isRequired: true, scoringEnabled: true),
            DraftFormField.seed(type: FieldType.multipleChoice, label: 'عوامل ریسک مشاهده‌شده', options: <String>['فرآیند', 'افراد', 'فناوری', 'محیط'], isRequired: false, scoringEnabled: true),
            DraftFormField.seed(type: FieldType.longText, label: 'یادداشت‌های کاهش ریسک', isRequired: false),
          ],
        ),
      ];

  static FormTemplatePreset byType(FormTemplateType type) => presets.firstWhere((preset) => preset.type == type);
}

class DraftFormField {
  const DraftFormField({
    required this.draftId,
    required this.type,
    required this.label,
    this.description,
    this.placeholder,
    required this.isRequired,
    required this.options,
    this.min,
    this.max,
    this.step,
    this.maxLength,
    required this.scoringEnabled,
    required this.maxScore,
    required this.weight,
  });

  factory DraftFormField.forType(FieldType type) {
    return DraftFormField.seed(type: type, label: defaultLabelForFieldType(type));
  }

  factory DraftFormField.seed({
    required FieldType type,
    required String label,
    String? description,
    String? placeholder,
    bool isRequired = false,
    List<String>? options,
    double? min,
    double? max,
    double? step,
    int? maxLength,
    bool scoringEnabled = false,
    double maxScore = 1,
    double weight = 1,
  }) {
    final defaults = _defaultsForFieldType(type);
    return DraftFormField(
      draftId: _newDraftId(),
      type: type,
      label: label,
      description: description,
      placeholder: placeholder ?? defaults.placeholder,
      isRequired: isRequired && !fieldTypeIsInformational(type),
      options: options ?? defaults.options,
      min: min ?? defaults.min,
      max: max ?? defaults.max,
      step: step ?? defaults.step,
      maxLength: maxLength ?? defaults.maxLength,
      scoringEnabled: scoringEnabled && fieldTypeCanScore(type),
      maxScore: maxScore,
      weight: weight,
    );
  }

  final String draftId;
  final FieldType type;
  final String label;
  final String? description;
  final String? placeholder;
  final bool isRequired;
  final List<String> options;
  final double? min;
  final double? max;
  final double? step;
  final int? maxLength;
  final bool scoringEnabled;
  final double maxScore;
  final double weight;

  DraftFormField copyWith({
    String? draftId,
    FieldType? type,
    String? label,
    String? description,
    String? placeholder,
    bool? isRequired,
    List<String>? options,
    double? min,
    double? max,
    double? step,
    int? maxLength,
    bool? scoringEnabled,
    double? maxScore,
    double? weight,
  }) {
    return DraftFormField(
      draftId: draftId ?? this.draftId,
      type: type ?? this.type,
      label: label ?? this.label,
      description: description ?? this.description,
      placeholder: placeholder ?? this.placeholder,
      isRequired: isRequired ?? this.isRequired,
      options: options ?? this.options,
      min: min ?? this.min,
      max: max ?? this.max,
      step: step ?? this.step,
      maxLength: maxLength ?? this.maxLength,
      scoringEnabled: scoringEnabled ?? this.scoringEnabled,
      maxScore: maxScore ?? this.maxScore,
      weight: weight ?? this.weight,
    );
  }

  DraftFormField changeType(FieldType nextType) {
    final next = DraftFormField.forType(nextType);
    final currentLabel = label.trim();
    final shouldKeepLabel = currentLabel.isNotEmpty && currentLabel != defaultLabelForFieldType(type);
    return next.copyWith(
      draftId: draftId,
      label: shouldKeepLabel ? currentLabel : defaultLabelForFieldType(nextType),
      description: description,
      isRequired: isRequired && !fieldTypeIsInformational(nextType),
      scoringEnabled: scoringEnabled && fieldTypeCanScore(nextType),
      maxScore: maxScore,
      weight: weight,
    );
  }

  CreateFormFieldRequest toCreateRequest({required int orderIndex}) {
    return CreateFormFieldRequest(
      type: type,
      label: _nonBlank(label, defaultLabelForFieldType(type)),
      description: _blankToNull(description),
      placeholder: _blankToNull(placeholder),
      isRequired: isRequired && !fieldTypeIsInformational(type),
      orderIndex: orderIndex,
      config: _buildConfig(),
      validation: _buildValidation(),
      scoringConfig: _buildScoringConfig(),
    );
  }

  FieldConfigDto? _buildConfig() {
    if (fieldTypeUsesOptions(type)) {
      return FieldConfigDto(options: _optionDtos(options.isEmpty ? _defaultsForFieldType(type).options : options));
    }
    if (fieldTypeUsesMatrix(type)) {
      return FieldConfigDto(
        rows: _optionDtos(options.isEmpty ? const <String>['ردیف ۱', 'ردیف ۲', 'ردیف ۳'] : options),
        columns: _optionDtos(const <String>['ستون ۱', 'ستون ۲', 'ستون ۳']),
      );
    }
    if (fieldTypeUsesRange(type)) {
      return FieldConfigDto(min: min, max: max, step: step);
    }
    if (type == FieldType.fileUpload) {
      return const FieldConfigDto(acceptMimeTypes: <String>['application/pdf', 'image/png', 'image/jpeg'], maxFileSizeMb: 10);
    }
    if (type == FieldType.imageUpload) {
      return const FieldConfigDto(acceptMimeTypes: <String>['image/png', 'image/jpeg', 'image/webp'], maxFileSizeMb: 10);
    }
    if (type == FieldType.sectionTitle) {
      return FieldConfigDto(pageTitle: _nonBlank(label, 'بخش'), staticText: _blankToNull(description));
    }
    if (type == FieldType.descriptionBlock || type == FieldType.termsAcceptance || type == FieldType.consentCheckbox) {
      return FieldConfigDto(staticText: _nonBlank(description ?? label, label));
    }
    if (type == FieldType.hidden) {
      return FieldConfigDto(defaultValue: _blankToNull(description));
    }
    return null;
  }

  FieldValidationDto? _buildValidation() {
    if (type == FieldType.email) {
      return FieldValidationDto(regex: r'^[^@\s]+@[^@\s]+\.[^@\s]+$', requiredMessage: isRequired ? 'آدرس ایمیل را وارد کنید.' : null);
    }
    if (type == FieldType.shortText || type == FieldType.longText) {
      return FieldValidationDto(maxLength: maxLength, requiredMessage: isRequired ? 'این فیلد ضروری است.' : null);
    }
    if (fieldTypeUsesRange(type) || type == FieldType.number || type == FieldType.decimal) {
      return FieldValidationDto(minNumber: min, maxNumber: max, requiredMessage: isRequired ? 'یک مقدار انتخاب کنید.' : null);
    }
    if (type == FieldType.multipleChoice || type == FieldType.matrixMultipleChoice || type == FieldType.ranking) {
      return FieldValidationDto(minItems: isRequired ? 1 : null, requiredMessage: isRequired ? 'حداقل یک گزینه انتخاب کنید.' : null);
    }
    return isRequired ? const FieldValidationDto(requiredMessage: 'این فیلد ضروری است.') : null;
  }

  FieldScoringConfigDto? _buildScoringConfig() {
    if (!scoringEnabled) return null;
    if (fieldTypeUsesOptions(type)) {
      final scores = <String, double>{};
      final ids = _optionIds(options.isEmpty ? _defaultsForFieldType(type).options : options);
      for (var index = 0; index < ids.length; index++) {
        scores[ids[index]] = index == 0 ? 1.0 : 0.0;
      }
      return FieldScoringConfigDto(enabled: true, maxScore: maxScore, weight: weight, optionScores: scores);
    }
    if (type == FieldType.yesNo || type == FieldType.booleanSwitch) {
      return FieldScoringConfigDto(enabled: true, maxScore: maxScore, weight: weight, optionScores: const <String, double>{'yes': 1, 'no': 0});
    }
    if (fieldTypeUsesRange(type)) {
      return FieldScoringConfigDto(enabled: true, maxScore: maxScore == 1 ? (max ?? 10) : maxScore, weight: weight);
    }
    return FieldScoringConfigDto(enabled: true, maxScore: maxScore, weight: weight);
  }
}

class _FieldDefaults {
  const _FieldDefaults({required this.options, this.placeholder, this.min, this.max, this.step, this.maxLength});

  final List<String> options;
  final String? placeholder;
  final double? min;
  final double? max;
  final double? step;
  final int? maxLength;
}

_FieldDefaults _defaultsForFieldType(FieldType type) {
  if (type == FieldType.shortText) return const _FieldDefaults(options: <String>[], placeholder: 'پاسخ کوتاه', maxLength: 255);
  if (type == FieldType.longText) return const _FieldDefaults(options: <String>[], placeholder: 'پاسخ بلند', maxLength: 2000);
  if (type == FieldType.email) return const _FieldDefaults(options: <String>[], placeholder: 'name@example.com');
  if (type == FieldType.phone) return const _FieldDefaults(options: <String>[], placeholder: '+49 ...');
  if (type == FieldType.number || type == FieldType.decimal) return const _FieldDefaults(options: <String>[], min: 0, max: 100, step: 1);
  if (type == FieldType.ratingStars || type == FieldType.numericRating) return const _FieldDefaults(options: <String>[], min: 1, max: 5, step: 1);
  if (type == FieldType.nps) return const _FieldDefaults(options: <String>[], min: 0, max: 10, step: 1);
  if (type == FieldType.slider) return const _FieldDefaults(options: <String>[], min: 0, max: 100, step: 1);
  if (type == FieldType.emojiReaction) return const _FieldDefaults(options: <String>['😡', '😕', '😐', '🙂', '😍']);
  if (fieldTypeUsesOptions(type)) return const _FieldDefaults(options: <String>['گزینه ۱', 'گزینه ۲', 'گزینه ۳']);
  if (type == FieldType.fileUpload || type == FieldType.imageUpload) return const _FieldDefaults(options: <String>[], placeholder: 'یک فایل بارگذاری کنید');
  return const _FieldDefaults(options: <String>[]);
}

bool fieldTypeUsesOptions(FieldType type) {
  return type == FieldType.singleChoice ||
      type == FieldType.multipleChoice ||
      type == FieldType.dropdown ||
      type == FieldType.ranking ||
      type == FieldType.quizQuestion ||
      type == FieldType.likertScale ||
      type == FieldType.emojiReaction;
}

bool fieldTypeUsesMatrix(FieldType type) {
  return type == FieldType.matrixSingleChoice || type == FieldType.matrixMultipleChoice;
}

bool fieldTypeUsesRange(FieldType type) {
  return type == FieldType.number ||
      type == FieldType.decimal ||
      type == FieldType.ratingStars ||
      type == FieldType.numericRating ||
      type == FieldType.slider ||
      type == FieldType.nps;
}

bool fieldTypeIsInformational(FieldType type) {
  return type == FieldType.sectionTitle ||
      type == FieldType.descriptionBlock ||
      type == FieldType.divider ||
      type == FieldType.pageBreak ||
      type == FieldType.scoreDisplay ||
      type == FieldType.hidden ||
      type == FieldType.calculated ||
      type == FieldType.conditionalLogic ||
      type == FieldType.unknown;
}

bool fieldTypeCanScore(FieldType type) {
  return !fieldTypeIsInformational(type) && type != FieldType.fileUpload && type != FieldType.imageUpload && type != FieldType.signature && type != FieldType.location;
}

List<FieldOptionDto> _optionDtos(List<String> labels) {
  final clean = labels.where((label) => label.trim().isNotEmpty).toList(growable: false);
  return <FieldOptionDto>[
    for (var index = 0; index < clean.length; index++)
      FieldOptionDto(id: _optionId(clean[index], index), label: clean[index].trim(), value: _optionId(clean[index], index), orderIndex: index),
  ];
}

List<String> _optionIds(List<String> labels) {
  return <String>[
    for (var index = 0; index < labels.length; index++) _optionId(labels[index], index),
  ];
}

String _optionId(String label, int index) {
  final normalized = label.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_').replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'option_${index + 1}' : normalized;
}

String defaultLabelForFieldType(FieldType type) {
  return type.toJson().split('_').where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
}

String readableWireValue(String value) {
  return value.split('_').where((part) => part.isNotEmpty).map((part) => '${part[0].toUpperCase()}${part.substring(1)}').join(' ');
}

String _nonBlank(String value, String fallback) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? fallback : trimmed;
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

from pathlib import Path

renderer = Path('lib/presentation/widgets/field_renderer.dart').read_text(encoding='utf-8')
workspace = Path('lib/features/forms/presentation/form_detail_screen.dart').read_text(encoding='utf-8')

required_tokens = [
    'final FormFieldDto field',
    'FieldType.singleChoice',
    'FieldType.multipleChoice',
    'FieldType.dropdown',
    'FieldType.ratingStars',
    'FieldType.numericRating',
    'FieldType.slider',
    'FieldType.nps',
    'FieldType.likertScale',
    'FieldType.matrixSingleChoice',
    'FieldType.matrixMultipleChoice',
    'FieldType.yesNo',
    'FieldType.booleanSwitch',
    'FieldType.consentCheckbox',
    'FieldType.fileUpload',
    'FieldType.imageUpload',
    'FieldType.signature',
    'FieldType.ranking',
    'FieldType.sectionTitle',
    'FieldType.descriptionBlock',
    'FieldType.divider',
    '_MatrixSingleChoiceInput',
    '_MatrixMultipleChoiceInput',
    '_RankingInput',
    '_UploadPreview',
]
missing = [token for token in required_tokens if token not in renderer]
if missing:
    raise SystemExit(f'[FAIL] preview renderer is missing: {missing}')

if "import '../../domain/entities/field_entity.dart'" in renderer:
    raise SystemExit('[FAIL] preview renderer still uses domain FormFieldEntity instead of full DTO config')

if 'FormDtoMapper.detailToEntity' in workspace:
    raise SystemExit('[FAIL] preview still maps DTO fields to reduced domain entities')

if 'FieldRenderer(\n                    index: index,' not in workspace:
    raise SystemExit('[FAIL] workspace preview does not pass field index to the rich renderer')

print('[OK] rich field preview renderer checks passed')

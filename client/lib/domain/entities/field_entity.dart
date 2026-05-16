class FormFieldEntity {
  const FormFieldEntity({
    required this.id,
    required this.formId,
    required this.type,
    required this.label,
    required this.isRequired,
    required this.orderIndex,
    this.description,
    this.placeholder,
  });

  final String id;
  final String formId;
  final String type;
  final String label;
  final String? description;
  final String? placeholder;
  final bool isRequired;
  final int orderIndex;
}

import 'dart:convert';

import '../settings/app_settings_store.dart';

class FormAnswerDraft {
  const FormAnswerDraft({
    required this.answers,
    required this.currentPage,
    required this.totalQuestions,
    required this.updatedAt,
  });

  final Map<String, Object?> answers;
  final int currentPage;
  final int totalQuestions;
  final DateTime updatedAt;

  double get completion {
    if (totalQuestions <= 0) return 0;
    final answered = answers.values.where(_hasAnswer).length;
    return (answered / totalQuestions).clamp(0, 1);
  }

  Map<String, Object?> toJson() => {
    'answers': answers.map((key, value) => MapEntry(key, _jsonSafe(value))),
    'current_page': currentPage,
    'total_questions': totalQuestions,
    'updated_at': updatedAt.toIso8601String(),
  };

  static FormAnswerDraft? fromJson(Map<String, Object?> json) {
    final answersJson = json['answers'];
    if (answersJson is! Map) return null;
    return FormAnswerDraft(
      answers: answersJson.map((key, value) => MapEntry('$key', value)),
      currentPage: _int(json['current_page']),
      totalQuestions: _int(json['total_questions']),
      updatedAt:
          DateTime.tryParse('${json['updated_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class FormAnswerDraftStore {
  const FormAnswerDraftStore(this._settingsStore);

  final AppSettingsStore _settingsStore;

  static String formKey(String formId, {String? childId}) {
    final audience = (childId == null || childId.trim().isEmpty)
        ? 'self'
        : childId.trim();
    return 'feedbackflow.answer_draft.form.$formId.$audience';
  }

  static String publicKey(String publicToken, {String? respondentMode}) {
    final mode = (respondentMode == null || respondentMode.trim().isEmpty)
        ? 'default'
        : respondentMode.trim();
    return 'feedbackflow.answer_draft.public.$publicToken.$mode';
  }

  Future<FormAnswerDraft?> read(String key) async {
    final raw = await _settingsStore.readValue(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) {
        return FormAnswerDraft.fromJson(decoded);
      }
      if (decoded is Map) {
        return FormAnswerDraft.fromJson(
          decoded.map((key, value) => MapEntry('$key', value)),
        );
      }
    } catch (_) {
      await clear(key);
    }
    return null;
  }

  Future<void> save({
    required String key,
    required Map<String, Object?> answers,
    required int currentPage,
    required int totalQuestions,
  }) async {
    final draft = FormAnswerDraft(
      answers: Map<String, Object?>.from(answers),
      currentPage: currentPage,
      totalQuestions: totalQuestions,
      updatedAt: DateTime.now(),
    );
    await _settingsStore.writeValue(key, jsonEncode(draft.toJson()));
  }

  Future<void> clear(String key) => _settingsStore.deleteValue(key);
}

bool _hasAnswer(Object? value) {
  if (value == null) return false;
  if (value is String) return value.trim().isNotEmpty;
  if (value is Iterable) return value.isNotEmpty;
  if (value is Map) return value.isNotEmpty;
  return true;
}

Object? _jsonSafe(Object? value) {
  if (value is DateTime) return value.toIso8601String();
  if (value is Map) {
    return value.map((key, value) => MapEntry('$key', _jsonSafe(value)));
  }
  if (value is Iterable) return value.map(_jsonSafe).toList(growable: false);
  return value;
}

int _int(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

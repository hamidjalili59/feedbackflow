import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as rp;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../core/security/token_store.dart';
import '../data/api/feedback_flow_api_client.dart';
import '../data/dto/dto.dart';
import '../data/local/app_database.dart';
import '../data/repositories/activities_repository.dart';
import '../data/repositories/analytics_repository.dart';
import '../data/repositories/audit_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/fields_repository.dart';
import '../data/repositories/forms_repository.dart';
import '../data/repositories/organizations_repository.dart';
import '../data/repositories/permissions_repository.dart';
import '../data/repositories/public_forms_repository.dart';
import '../data/repositories/scoring_repository.dart';
import '../data/repositories/submissions_repository.dart';
import '../data/repositories/users_repository.dart';
import '../presentation/common/friendly_api_error_message.dart';
import '../presentation/models/form_builder_models.dart';
import 'dependencies.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
AppDependencies appDependencies(Ref ref) {
  throw UnimplementedError(
    'AppDependencies must be overridden in ProviderScope.',
  );
}

@Riverpod(keepAlive: true)
AuthTokenStore tokenStore(Ref ref) =>
    ref.watch(appDependenciesProvider).tokenStore;

@Riverpod(keepAlive: true)
AppDatabase database(Ref ref) => ref.watch(appDependenciesProvider).database;

@Riverpod(keepAlive: true)
FeedbackFlowApiClient apiClient(Ref ref) =>
    ref.watch(appDependenciesProvider).apiClient;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).authRepository;

@Riverpod(keepAlive: true)
FormsRepository formsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).formsRepository;

@Riverpod(keepAlive: true)
FieldsRepository fieldsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).fieldsRepository;

@Riverpod(keepAlive: true)
PublicFormsRepository publicFormsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).publicFormsRepository;

@Riverpod(keepAlive: true)
ActivitiesRepository activitiesRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).activitiesRepository;

@Riverpod(keepAlive: true)
AnalyticsRepository analyticsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).analyticsRepository;

@Riverpod(keepAlive: true)
AuditRepository auditRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).auditRepository;

@Riverpod(keepAlive: true)
OrganizationsRepository organizationsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).organizationsRepository;

@Riverpod(keepAlive: true)
PermissionsRepository permissionsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).permissionsRepository;

@Riverpod(keepAlive: true)
ScoringRepository scoringRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).scoringRepository;

@Riverpod(keepAlive: true)
SubmissionsRepository submissionsRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).submissionsRepository;

@Riverpod(keepAlive: true)
UsersRepository usersRepository(Ref ref) =>
    ref.watch(appDependenciesProvider).usersRepository;

@Riverpod(keepAlive: true)
class LocaleController extends _$LocaleController {
  @override
  Locale build() => const Locale('fa');

  void setLocale(Locale locale) => state = locale;
}

@Riverpod(keepAlive: true)
class ThemeController extends _$ThemeController {
  @override
  ThemeMode build() => ThemeMode.system;

  void setThemeMode(ThemeMode mode) => state = mode;

  void cycle() {
    state = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
  }
}

class AuthSession {
  const AuthSession({required this.user, this.effectivePermissions});

  final UserDetailDto user;
  final EffectivePermissionsDto? effectivePermissions;
}

@Riverpod(keepAlive: true)
class AuthController extends _$AuthController {
  @override
  Future<AuthSession?> build() async {
    final tokenStore = ref.watch(tokenStoreProvider);
    final accessToken = await tokenStore.readAccessToken();
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      final me = await ref.watch(authRepositoryProvider).getMe();
      return AuthSession(
        user: me.user,
        effectivePermissions: me.effectivePermissions,
      );
    } catch (_) {
      await tokenStore.clear();
      return null;
    }
  }

  Future<void> login({required String phone, required String password}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final response = await ref
          .read(authRepositoryProvider)
          .login(
            request: LoginRequest(phone: phone, password: password),
          );
      await ref
          .read(tokenStoreProvider)
          .saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
      _invalidateSessionScopedProviders();
      return AuthSession(user: response.user);
    });
  }

  Future<void> guestLogin({
    String? organizationId,
    String? organizationSlug,
    String? publicToken,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final response = await ref
          .read(authRepositoryProvider)
          .guestLogin(
            request: GuestLoginRequest(
              organizationId: organizationId,
              organizationSlug: organizationSlug,
              publicToken: publicToken,
              displayName: displayName,
            ),
          );
      await ref
          .read(tokenStoreProvider)
          .saveTokens(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
          );
      _invalidateSessionScopedProviders();
      return AuthSession(user: response.user);
    });
  }

  Future<void> logout() async {
    final tokenStore = ref.read(tokenStoreProvider);
    final refreshToken = await tokenStore.readRefreshToken();
    if (refreshToken != null && refreshToken.isNotEmpty) {
      try {
        await ref
            .read(authRepositoryProvider)
            .logout(request: LogoutRequest(refreshToken: refreshToken));
      } catch (_) {
        // Local logout must still succeed when the server rejects an expired token.
      }
    }
    await tokenStore.clear();
    _invalidateSessionScopedProviders();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile(UpdateUserProfileRequest request) async {
    final current = state.asData?.value;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<AuthSession?>(() async {
      final user = await ref
          .read(usersRepositoryProvider)
          .updateMyProfile(request: request);
      ref.invalidate(dashboardExperienceProvider);
      return AuthSession(
        user: user,
        effectivePermissions: current?.effectivePermissions,
      );
    });
  }

  void _invalidateSessionScopedProviders() {
    invalidateSessionScopedProviders(ref);
  }
}

const sessionScopedProviderDebugNames = <String>{
  'dashboardExperienceProvider',
  'mySurveysProvider',
  'surveyCalendarProvider',
  'metricTimeseriesProvider',
  'dashboardAnalyticsProvider',
  'activitiesProvider',
  'auditLogsProvider',
  'effectivePermissionsProvider',
  'formsControllerProvider',
  'formDetailProvider',
  'formAnswerAccessProvider',
  'formAssignmentsProvider',
  'formAnalyticsProvider',
  'submissionsProvider',
  'submissionDetailProvider',
  'metricDefinitionsProvider',
  'audienceSegmentsProvider',
  'audienceGroupsProvider',
};

void invalidateSessionScopedProviders(Ref ref) {
  ref.invalidate(dashboardExperienceProvider);
  ref.invalidate(mySurveysProvider);
  ref.invalidate(surveyCalendarProvider);
  ref.invalidate(metricTimeseriesProvider);
  ref.invalidate(dashboardAnalyticsProvider);
  ref.invalidate(activitiesProvider);
  ref.invalidate(auditLogsProvider);
  ref.invalidate(effectivePermissionsProvider);
  ref.invalidate(formsControllerProvider);
  ref.invalidate(formDetailProvider);
  ref.invalidate(formAnswerAccessProvider);
  ref.invalidate(formAssignmentsProvider);
  ref.invalidate(formAnalyticsProvider);
  ref.invalidate(submissionsProvider);
  ref.invalidate(submissionDetailProvider);
  ref.invalidate(metricDefinitionsProvider);
  ref.invalidate(audienceSegmentsProvider);
  ref.invalidate(audienceGroupsProvider);
}

String? _currentSessionUserId(Ref ref) {
  return ref.watch(
    authControllerProvider.select((state) => state.asData?.value?.user.id),
  );
}

@Riverpod(keepAlive: true)
class FormsController extends _$FormsController {
  String _search = '';
  String _category = '';
  String _tag = '';
  String _sortBy = 'updated_at';
  SortOrder _sortOrder = SortOrder.desc;
  int _page = 1;
  static const int _pageSize = 10;

  @override
  Future<ListResponse<FormSummaryDto>> build() {
    _currentSessionUserId(ref);
    return _load();
  }

  Future<ListResponse<FormSummaryDto>> _load() async {
    try {
      return await ref
          .read(formsRepositoryProvider)
          .listForms(
            page: _page,
            pageSize: _pageSize,
            search: _search.trim().isEmpty ? null : _search.trim(),
            category: _category.trim().isEmpty ? null : _category.trim(),
            tags: _tag.trim().isEmpty ? null : _tag.trim(),
            sortBy: _sortBy,
            sortOrder: _sortOrder,
          );
    } catch (e) {
      // Re-throw so AsyncValue transitions to error state properly.
      // This ensures the UI shows ErrorPanel instead of staying in loading.
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<void> applyFilters({
    String? search,
    String? category,
    String? tag,
    String? sortBy,
    SortOrder? sortOrder,
  }) async {
    _search = search ?? _search;
    _category = category ?? _category;
    _tag = tag ?? _tag;
    _sortBy = sortBy ?? _sortBy;
    _sortOrder = sortOrder ?? _sortOrder;
    _page = 1;
    await refresh();
  }

  Future<void> goToPage(int page) async {
    _page = page < 1 ? 1 : page;
    await refresh();
  }
}

@Riverpod(keepAlive: true)
Future<FormDetailDto> formDetail(Ref ref, String formId) {
  _currentSessionUserId(ref);
  return ref.watch(formsRepositoryProvider).getForm(id: formId);
}

@Riverpod(keepAlive: true)
Future<PublicFormDto> publicForm(Ref ref, String publicToken) {
  return ref
      .watch(publicFormsRepositoryProvider)
      .getPublicForm(publicToken: publicToken);
}

final dashboardExperienceProvider =
    rp.FutureProvider.family<DashboardResponseDto2, DashboardQueryInput>((
      ref,
      query,
    ) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getDashboardExperience(query: query);
    });

final surveyCalendarProvider =
    rp.FutureProvider.family<CalendarResponseDto2, CalendarQueryInput>((
      ref,
      query,
    ) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getSurveyCalendar(period: query.period, childId: query.childId);
    });

final mySurveysProvider =
    rp.FutureProvider.family<List<SurveyCardDto2>, String?>((ref, status) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getMySurveys(status: status, limit: 30);
    });

final metricTimeseriesProvider =
    rp.FutureProvider.family<TimeseriesResponseDto2, String>((ref, metricKey) {
      return ref
          .watch(analyticsRepositoryProvider)
          .getAnalyticsTimeseries(
            metric: metricKey,
            period: 'this_month',
            compare: 'previous_period',
            granularity: 'month',
          );
    });

final metricDefinitionsProvider =
    rp.FutureProvider<ListResponse<MetricDefinitionDto2>>((ref) {
      return ref
          .watch(analyticsRepositoryProvider)
          .listMetrics(page: 1, pageSize: 50);
    });

final audienceSegmentsProvider =
    rp.FutureProvider<ListResponse<AudienceSegmentDto2>>((ref) {
      return ref
          .watch(analyticsRepositoryProvider)
          .listAudienceSegments(page: 1, pageSize: 50);
    });

final audienceGroupsProvider =
    rp.FutureProvider.family<ListResponse<AudienceGroupOptionDto2>, String?>((
      ref,
      groupType,
    ) {
      return ref
          .watch(analyticsRepositoryProvider)
          .listAudienceGroups(page: 1, pageSize: 100, groupType: groupType);
    });

final formAssignmentsProvider =
    rp.FutureProvider.family<List<FormAssignmentDto2>, String>((ref, formId) {
      return ref
          .watch(analyticsRepositoryProvider)
          .listFormAssignments(id: formId);
    });

final formAnswerAccessProvider =
    rp.FutureProvider.family<FormAnswerAccessDto2, String>((ref, formId) {
      _currentSessionUserId(ref);
      return ref.watch(formsRepositoryProvider).getFormAnswerAccess(id: formId);
    });

@Riverpod(keepAlive: true)
Future<DashboardAnalyticsDto> dashboardAnalytics(Ref ref) {
  return ref.watch(analyticsRepositoryProvider).getDashboardAnalytics();
}

@Riverpod(keepAlive: true)
Future<ListResponse<ActivitySummaryDto>> activities(Ref ref) {
  return ref
      .watch(activitiesRepositoryProvider)
      .listActivities(page: 1, pageSize: 30);
}

@Riverpod(keepAlive: true)
Future<ListResponse<AuditLogDto>> auditLogs(Ref ref) {
  return ref
      .watch(auditRepositoryProvider)
      .listAuditLogs(page: 1, pageSize: 30);
}

@Riverpod(keepAlive: true)
Future<EffectivePermissionsDto> effectivePermissions(Ref ref) {
  return ref.watch(permissionsRepositoryProvider).getEffectivePermissions();
}

@Riverpod(keepAlive: true)
Future<ListResponse<ScoreTemplateDto>> scoreTemplates(Ref ref) {
  return ref
      .watch(scoringRepositoryProvider)
      .listScoreTemplates(page: 1, pageSize: 30);
}

@Riverpod(keepAlive: true)
Future<FormAnalyticsDto> formAnalytics(Ref ref, String formId) {
  return ref.watch(analyticsRepositoryProvider).getFormAnalytics(id: formId);
}

@Riverpod(keepAlive: true)
Future<ListResponse<SubmissionSummaryDto>> submissions(Ref ref, String formId) {
  _currentSessionUserId(ref);
  return ref
      .watch(submissionsRepositoryProvider)
      .listSubmissions(id: formId, page: 1, pageSize: 30);
}

@Riverpod(keepAlive: true)
Future<SubmissionDetailDto> submissionDetail(Ref ref, String submissionId) {
  _currentSessionUserId(ref);
  return ref
      .watch(submissionsRepositoryProvider)
      .getSubmission(id: submissionId);
}

@Riverpod(keepAlive: true)
class CreateFormController extends _$CreateFormController {
  @override
  CreateFormState build() => CreateFormState.initial(
    languageCode: ref.watch(localeControllerProvider).languageCode,
  );

  void reset() => state = CreateFormState.initial(
    languageCode: ref.read(localeControllerProvider).languageCode,
  );

  void selectTemplate(FormTemplateType type) {
    state = CreateFormState.fromTemplate(
      FormTemplateCatalog.byType(
        type,
        languageCode: ref.read(localeControllerProvider).languageCode,
      ),
    );
  }

  void changeTitle(String title) {
    state = state.copyWith(
      title: title,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeDescription(String description) {
    state = state.copyWith(
      description: description,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeCategory(String category) {
    state = state.copyWith(
      category: category,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void setTags(List<String> tags) {
    state = state.copyWith(
      tags: tags,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeVisibility(VisibilityMode visibilityMode) {
    state = state.copyWith(
      visibilityMode: visibilityMode,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeScoring(ScoringMode scoringMode) {
    state = state.copyWith(
      scoringMode: scoringMode,
      fields: scoringMode == ScoringMode.none
          ? [
              for (final field in state.fields)
                field.copyWith(scoringEnabled: false),
            ]
          : state.fields,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeSettings({
    bool? allowAnonymousAnswers,
    bool? oneSubmissionPerUser,
    bool? answersEditableAfterSubmission,
    bool? guestsCanAnswer,
  }) {
    state = state.copyWith(
      allowAnonymousAnswers: allowAnonymousAnswers,
      oneSubmissionPerUser: oneSubmissionPerUser,
      answersEditableAfterSubmission: answersEditableAfterSubmission,
      guestsCanAnswer: guestsCanAnswer,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void addField(FieldType type) {
    state = state.copyWith(
      fields: [...state.fields, DraftFormField.forType(type)],
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void changeField(DraftFormField field) {
    state = state.copyWith(
      fields: [
        for (final item in state.fields)
          item.draftId == field.draftId ? field : item,
      ],
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void removeField(String draftId) {
    state = state.copyWith(
      fields: state.fields
          .where((field) => field.draftId != draftId)
          .toList(growable: false),
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  void moveField(int oldIndex, int newIndex) {
    final fields = [...state.fields];
    var targetIndex = newIndex;
    if (targetIndex > oldIndex) targetIndex -= 1;
    if (oldIndex < 0 || oldIndex >= fields.length) return;
    if (targetIndex < 0 || targetIndex > fields.length) return;
    final field = fields.removeAt(oldIndex);
    fields.insert(targetIndex, field);
    state = state.copyWith(
      fields: fields,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );
  }

  Future<FormDetailDto?> submit() async {
    if (!state.canSubmit) {
      state = state.copyWith(
        errorMessage: 'titleRequired',
        errorCode: ErrorCode.validationError,
      );
      return null;
    }

    state = state.copyWith(
      isSubmitting: true,
      errorMessage: null,
      errorCode: null,
      createdForm: null,
      partialCreate: false,
    );

    FormDetailDto? createdForm;
    try {
      createdForm = await ref
          .read(formsRepositoryProvider)
          .createForm(request: state.toCreateFormRequest());

      for (var index = 0; index < state.fields.length; index++) {
        await ref
            .read(fieldsRepositoryProvider)
            .createFormField(
              id: createdForm.id,
              request: state.fields[index].toCreateRequest(orderIndex: index),
            );
      }

      final hydratedForm = await ref
          .read(formsRepositoryProvider)
          .getForm(id: createdForm.id);
      state = state.copyWith(
        isSubmitting: false,
        createdForm: hydratedForm,
        errorMessage: null,
        errorCode: null,
        partialCreate: false,
      );
      ref.invalidate(formsControllerProvider);
      return hydratedForm;
    } catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        createdForm: createdForm,
        partialCreate: createdForm != null,
        errorMessage: createdForm == null
            ? FriendlyApiErrorMessage.from(error)
            : 'partialFieldsFailed: ${FriendlyApiErrorMessage.from(error)}',
        errorCode: _errorCodeFrom(error),
      );
      if (createdForm != null) ref.invalidate(formsControllerProvider);
      return null;
    }
  }
}

class CreateFormState {
  const CreateFormState({
    required this.selectedTemplate,
    required this.title,
    required this.description,
    required this.category,
    required this.tags,
    required this.scoringMode,
    required this.visibilityMode,
    required this.allowAnonymousAnswers,
    required this.oneSubmissionPerUser,
    required this.answersEditableAfterSubmission,
    required this.guestsCanAnswer,
    required this.fields,
    required this.isSubmitting,
    this.errorMessage,
    this.errorCode,
    this.createdForm,
    this.partialCreate = false,
  });

  factory CreateFormState.initial({String languageCode = 'fa'}) {
    final template = FormTemplateCatalog.byType(
      FormTemplateType.feedbackSurvey,
      languageCode: languageCode,
    );
    return CreateFormState.fromTemplate(template);
  }

  factory CreateFormState.fromTemplate(FormTemplatePreset template) {
    return CreateFormState(
      selectedTemplate: template.type,
      title: template.defaultTitle,
      description: template.defaultDescription,
      category: '',
      tags: const <String>[],
      scoringMode: template.scoringMode,
      visibilityMode: template.visibilityMode,
      allowAnonymousAnswers: template.allowAnonymousAnswers,
      oneSubmissionPerUser: template.oneSubmissionPerUser,
      answersEditableAfterSubmission: template.answersEditableAfterSubmission,
      guestsCanAnswer: template.guestsCanAnswer,
      fields: [...template.fields],
      isSubmitting: false,
    );
  }

  final FormTemplateType selectedTemplate;
  final String title;
  final String description;
  final String category;
  final List<String> tags;
  final ScoringMode scoringMode;
  final VisibilityMode visibilityMode;
  final bool allowAnonymousAnswers;
  final bool oneSubmissionPerUser;
  final bool answersEditableAfterSubmission;
  final bool guestsCanAnswer;
  final List<DraftFormField> fields;
  final bool isSubmitting;
  final String? errorMessage;
  final ErrorCode? errorCode;
  final FormDetailDto? createdForm;
  final bool partialCreate;

  bool get canSubmit => title.trim().isNotEmpty && !isSubmitting;

  CreateFormState copyWith({
    FormTemplateType? selectedTemplate,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    ScoringMode? scoringMode,
    VisibilityMode? visibilityMode,
    bool? allowAnonymousAnswers,
    bool? oneSubmissionPerUser,
    bool? answersEditableAfterSubmission,
    bool? guestsCanAnswer,
    List<DraftFormField>? fields,
    bool? isSubmitting,
    Object? errorMessage = _sentinel,
    Object? errorCode = _sentinel,
    Object? createdForm = _sentinel,
    bool? partialCreate,
  }) {
    return CreateFormState(
      selectedTemplate: selectedTemplate ?? this.selectedTemplate,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      scoringMode: scoringMode ?? this.scoringMode,
      visibilityMode: visibilityMode ?? this.visibilityMode,
      allowAnonymousAnswers:
          allowAnonymousAnswers ?? this.allowAnonymousAnswers,
      oneSubmissionPerUser: oneSubmissionPerUser ?? this.oneSubmissionPerUser,
      answersEditableAfterSubmission:
          answersEditableAfterSubmission ?? this.answersEditableAfterSubmission,
      guestsCanAnswer: guestsCanAnswer ?? this.guestsCanAnswer,
      fields: fields ?? this.fields,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      errorCode: identical(errorCode, _sentinel)
          ? this.errorCode
          : errorCode as ErrorCode?,
      createdForm: identical(createdForm, _sentinel)
          ? this.createdForm
          : createdForm as FormDetailDto?,
      partialCreate: partialCreate ?? this.partialCreate,
    );
  }

  CreateFormRequest toCreateFormRequest() {
    return CreateFormRequest(
      title: title.trim(),
      description: description.trim().isEmpty ? null : description.trim(),
      category: category.trim().isEmpty ? null : category.trim(),
      tags: tags,
      settings: FormSettingsDto(
        allowAnonymousAnswers: allowAnonymousAnswers,
        oneSubmissionPerUser: oneSubmissionPerUser,
        answersEditableAfterSubmission: answersEditableAfterSubmission,
        submissionMode: allowAnonymousAnswers
            ? SubmissionMode.anonymousSubmission
            : answersEditableAfterSubmission
            ? SubmissionMode.editableSubmission
            : oneSubmissionPerUser
            ? SubmissionMode.singleSubmission
            : SubmissionMode.multipleSubmissions,
        answerVisibility: allowAnonymousAnswers
            ? AnswerVisibility.anonymous
            : AnswerVisibility.visibleToCreator,
        guestsCanAnswer: guestsCanAnswer,
        metadata: const <String, Object?>{},
      ),
      visibility: FormVisibilityDto(
        mode: visibilityMode,
        canSee: const <AudienceRuleDto>[],
        canAnswer: const <AudienceRuleDto>[],
        cannotSee: const <AudienceRuleDto>[],
        cannotAnswer: const <AudienceRuleDto>[],
        guestCanAnswer: guestsCanAnswer,
        anonymousAllowed: allowAnonymousAnswers,
        metadata: const <String, Object?>{},
      ),
      scoringMode: scoringMode,
      scoringConfig: const <String, Object?>{},
    );
  }
}

const Object _sentinel = Object();

ErrorCode? _errorCodeFrom(Object error) =>
    FriendlyApiErrorMessage.errorCodeOf(error);

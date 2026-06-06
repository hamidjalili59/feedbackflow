import '../core/api/dio_factory.dart';
import '../core/settings/app_settings_store.dart';
import '../core/security/token_store.dart';
import '../data/api/feedback_flow_api_client.dart';
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

class AppDependencies {
  AppDependencies._({
    required this.tokenStore,
    required this.settingsStore,
    required this.database,
    required this.apiClient,
    required this.authRepository,
    required this.formsRepository,
    required this.publicFormsRepository,
    required this.activitiesRepository,
    required this.analyticsRepository,
    required this.auditRepository,
    required this.fieldsRepository,
    required this.organizationsRepository,
    required this.permissionsRepository,
    required this.scoringRepository,
    required this.submissionsRepository,
    required this.usersRepository,
  });

  final AuthTokenStore tokenStore;
  final AppSettingsStore settingsStore;
  final AppDatabase database;
  final FeedbackFlowApiClient apiClient;
  final AuthRepository authRepository;
  final FormsRepository formsRepository;
  final PublicFormsRepository publicFormsRepository;
  final ActivitiesRepository activitiesRepository;
  final AnalyticsRepository analyticsRepository;
  final AuditRepository auditRepository;
  final FieldsRepository fieldsRepository;
  final OrganizationsRepository organizationsRepository;
  final PermissionsRepository permissionsRepository;
  final ScoringRepository scoringRepository;
  final SubmissionsRepository submissionsRepository;
  final UsersRepository usersRepository;

  factory AppDependencies.create({required String baseUrl}) {
    final tokenStore = ApiDioFactory.defaultTokenStore();
    final dio = ApiDioFactory.create(baseUrl: baseUrl, tokenStore: tokenStore);
    final apiClient = FeedbackFlowApiClient(dio);
    return AppDependencies._(
      tokenStore: tokenStore,
      settingsStore: createSettingsStore(),
      database: AppDatabase(),
      apiClient: apiClient,
      authRepository: DioAuthRepository(apiClient),
      formsRepository: DioFormsRepository(apiClient),
      publicFormsRepository: DioPublicFormsRepository(apiClient),
      activitiesRepository: DioActivitiesRepository(apiClient),
      analyticsRepository: DioAnalyticsRepository(apiClient),
      auditRepository: DioAuditRepository(apiClient),
      fieldsRepository: DioFieldsRepository(apiClient),
      organizationsRepository: DioOrganizationsRepository(apiClient),
      permissionsRepository: DioPermissionsRepository(apiClient),
      scoringRepository: DioScoringRepository(apiClient),
      submissionsRepository: DioSubmissionsRepository(apiClient),
      usersRepository: DioUsersRepository(apiClient),
    );
  }
}

import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/forms/presentation/create_form_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/forms/presentation/form_detail_screen.dart';
import '../features/forms/presentation/forms_list_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/public_forms/presentation/public_form_screen.dart';
import '../features/shell/presentation/splash_screen.dart';
import 'providers.dart';

part 'router.g.dart';

@Riverpod(keepAlive: true)
Raw<GoRouter> router(Ref ref) {
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // Deep link auth guard: if user lands on a protected route without
      // being logged in, redirect to login with a redirect param so they
      // come back after authentication.
      final path = state.matchedLocation;
      final publicPaths = {'/', '/login', '/public'};
      final isPublic =
          publicPaths.contains(path) ||
          path.startsWith('/public/') ||
          path.startsWith('/login');
      if (!isPublic) {
        // Check auth synchronously from the provider cache.
        final auth = ref.read(authControllerProvider);
        final isLoggedIn = auth.asData?.value != null;
        if (!isLoggedIn) {
          return '/login?redirect=${Uri.encodeComponent(path)}';
        }
      }
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          redirectLocation: state.uri.queryParameters['redirect'],
          noticeKey: state.uri.queryParameters['notice'],
        ),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(
          initialChildId: state.uri.queryParameters['child_id'],
        ),
      ),
      GoRoute(
        path: '/forms',
        builder: (context, state) => const FormsListScreen(),
      ),
      GoRoute(
        path: '/forms/new',
        builder: (context, state) => const CreateFormScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/forms/:id',
        builder: (context, state) => FormDetailScreen(
          formId: state.pathParameters['id']!,
          initialSection: FormWorkspaceSection.builder,
          reviewSubmissionId: state.uri.queryParameters['submission_id'],
        ),
      ),
      GoRoute(
        path: '/forms/:id/:section',
        builder: (context, state) => FormDetailScreen(
          formId: state.pathParameters['id']!,
          initialSection: formWorkspaceSectionFromWire(
            state.pathParameters['section'],
          ),
          reviewSubmissionId: state.uri.queryParameters['submission_id'],
        ),
      ),
      GoRoute(
        path: '/public/:token',
        builder: (context, state) => PublicFormScreen(
          publicToken: state.pathParameters['token']!,
          initialRespondentMode: _publicFormRespondentMode(state),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}

String? _publicFormRespondentMode(GoRouterState state) {
  final mode = state.uri.queryParameters['respondent_mode'];
  if (mode != null && mode.trim().isNotEmpty) return mode.trim();
  final anonymous = state.uri.queryParameters['anonymous'];
  if (anonymous == '1' || anonymous == 'true') return 'anonymous';
  return null;
}

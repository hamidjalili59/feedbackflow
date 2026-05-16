# FeedbackFlow Flutter Client

Flutter client built against the backend OpenAPI contract. The OpenAPI file is the source of truth for endpoint paths, operation IDs, DTO names, enum JSON values, request bodies, response envelopes, authentication, pagination, and errors.

## Stack

- Flutter / Dart
- Dio
- Riverpod with `riverpod_generator`
- Drift for local data models
- Freezed + json_serializable for DTO/domain serialization
- go_router
- flutter_secure_storage

Bloc has been removed from this client. There is no `presentation/bloc` directory and no `bloc` / `flutter_bloc` dependency.

## Run

```bash
flutter clean
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter run --dart-define=API_BASE_URL=http://localhost:3000
```

For active development, use the generator in watch mode:

```bash
dart run build_runner watch --delete-conflicting-outputs
```

## Riverpod generator structure

- `lib/app/providers.dart` contains `@Riverpod` provider declarations for dependencies, repositories, auth state, form list/detail state, public form state, and create-form logic.
- `lib/app/providers.g.dart` is generated output. It is included only so the project does not show missing `part` errors before your first local build; regenerate it with build_runner.
- `lib/app/router.dart` declares the `routerProvider` with `@Riverpod` and `Raw<GoRouter>`.
- UI screens are `ConsumerWidget` / `ConsumerStatefulWidget` and read/write state through generated Riverpod providers.

## API compatibility

Form creation follows the contract:

1. `createForm` creates the form shell with `CreateFormRequest`.
2. `createFormField` attaches each field with `CreateFormFieldRequest`.

UI form templates are local presets only. They do not send a non-contract field such as `form_type`.

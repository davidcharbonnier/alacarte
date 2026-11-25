# apps/client — Flutter Mobile/Web Client

## Purpose

Flutter application for the À la carte rating platform. Cross-platform client targeting Android, Web, and Linux desktop. Provides item browsing, rating, sharing, user settings, and offline-capable experience.

## Ownership

- Code: `apps/client/`
- Docs: `docs/client/`
- Release tag: `client-v*`
- Package name: `alc_client`

## Local Contracts

- Framework: Flutter 3.32+, Riverpod (state management), GoRouter (routing)
- Auth: Google Sign-In → JWT stored in `flutter_secure_storage`; sign-in works on Android only (web and desktop are a known gap)
- HTTP: Dio (default adapter); parallel requests via `Future.wait()`
- i18n: Flutter built-in l10n with `.arb` files (English, French)
- Caching: Service-level singleton caching, 5-minute expiry
- Offline: connectivity-aware providers; fullscreen offline screen blocks the app (no offline data)
- Platform targets: Android, Web, Linux (UI work only, no sign-in); iOS/macOS/Windows (future)
- Code style: `dart format`, Effective Dart conventions
- Environment: `.env` file in `apps/client/`
- CHANGELOG in `apps/client/CHANGELOG.md`

## Work Guidance

- Architecture layers: models → services → providers → screens/widgets
- Models follow `RateableItem` interface; `DynamicItem` for schema-driven items
- Providers use Riverpod; service classes call `DioClient` → go via `ApiService` base
- Screen structure: `screens/auth/`, `screens/home/`, `screens/items/`, `screens/rating/`, `screens/settings/`, `screens/common/`, `screens/initialization/`
- Widgets split by domain: `widgets/items/`, `widgets/forms/`, `widgets/rating/`, `widgets/settings/`, `widgets/common/`
- Form rendering: `DynamicForm` widget reads `ItemSchema` fields and builds the inputs itself
- Route config: `routes/app_router.dart` uses GoRouter with async initialization guards
- Localization: `l10n/app_*.arb` → `flutter gen-l10n` generates to `flutter_gen/gen_l10n/`
- Token storage: `TokenStorage` in `services/token_storage.dart`
- Platform-specific config in `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/`

## Verification

- `flutter test` — runs widget tests
- Test file: `test/widget_test.dart`

## Child DOX Index

No children. Flat structure under `apps/client/`.
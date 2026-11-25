# À la carte Client

> **See also:** Full client documentation is available at [/docs/client/README.md](/docs/client/README.md).

Flutter application for the À la carte rating platform - mobile, web, and desktop.

## Quick Start

```bash
cd apps/client
# create .env first (see "Environment Variables" below; APP_VERSION is required)
flutter pub get
flutter run -d android  # Google sign-in works on Android only; -d chrome / -d linux are for UI work
```

## Key Features

- **Google OAuth Authentication** - Secure login with Google accounts
- **Multi-Item Rating System** - Rate cheese, gin, and more
- **Privacy Controls** - Granular sharing settings
- **Offline Support** - Fullscreen offline / server-unreachable screen with auto-retry
- **Internationalization** - Complete French/English support
- **Community Statistics** - Aggregate rating data
- **Smart Caching** - 5-minute service-level cache for instant navigation

## Common Tasks

### Adding a New Item Type
See [Adding New Item Types - Frontend Section](/docs/guides/adding-new-item-types.md#step-4-verify-in-client-app)


### Running the App
```bash
# Android (Google sign-in works here; emulator: API_BASE_URL=http://10.0.2.2:8080)
flutter run -d android

# UI work only (no Google sign-in): web or Linux
flutter run -d chrome
flutter run -d linux
```

### Generating Localizations
```bash
# After modifying .arb files
flutter gen-l10n
```

### Running Tests
```bash
flutter test
```

## 📚 Full Documentation

Complete client documentation available at [/docs/client/](/docs/client/)

### Client-Specific Docs
- [Setup Guides](/docs/client/setup/) - Android and OAuth setup
- [Architecture](/docs/client/architecture/) - Router and form patterns
- [Features](/docs/client/features/) - Notifications, settings, etc.

### Cross-App Features
- [Authentication System](/docs/features/authentication.md) - OAuth integration
- [Privacy Model](/docs/features/privacy-model.md) - Privacy settings
- [Rating System](/docs/features/rating-system.md) - Rating CRUD
- [Filtering System](/docs/features/filtering-system.md) - Search and filters
- [Offline Handling](/docs/features/offline-handling.md) - Connectivity
- [Internationalization](/docs/features/internationalization.md) - i18n system

## Technology Stack

- **Framework:** Flutter 3.32+
- **State Management:** Riverpod
- **Routing:** GoRouter with async initialization
- **Localization:** Flutter built-in i18n with .arb files
- **HTTP:** Dio (default adapter)
- **Storage:** SharedPreferences for local data
- **Caching:** Service-level singleton caching (5-minute expiry)
- **Performance:** parallel requests with `Future.wait()`

## Project Structure

```
apps/client/
├── lib/
│   ├── models/          # Data models (RateableItem interface)
│   ├── providers/       # Riverpod state management
│   ├── services/        # API services with caching
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable components
│   ├── routes/          # GoRouter configuration
│   ├── config/          # App configuration
│   ├── utils/           # Helpers and extensions
│   └── l10n/            # Localization files (.arb)
├── docs/                # (moved to /docs/client/)
└── pubspec.yaml
```

## Environment Variables

Create `.env` file:

```bash
API_BASE_URL=http://localhost:8080
GOOGLE_CLIENT_ID=your-web-client-id
APP_VERSION=1.0.0-dev
```

## Platform Support

- ⚠️ **Linux Desktop** - UI development only (no Google sign-in)
- ⚠️ **Web** - PWA build exists, but Google sign-in on web is a known gap, see [authentication](/docs/client/authentication-system.md)
- ✅ **Android** - Native mobile app
- 🔄 **iOS** - Future support
- 🔄 **macOS** - Future support
- 🔄 **Windows** - Future support

## License

Private - All Rights Reserved

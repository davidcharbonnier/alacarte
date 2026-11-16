# À la carte Client

> **See also:** Full client documentation is available at [/docs/client/README.md](/docs/client/README.md).

Flutter application for the À la carte rating platform - mobile, web, and desktop.

## Quick Start

```bash
cd apps/client
flutter pub get
flutter run -d linux  # or -d chrome, -d android
```

## Key Features

- **Google OAuth Authentication** - Secure login with Google accounts
- **Multi-Item Rating System** - Rate cheese, gin, and more
- **Privacy Controls** - Granular sharing settings
- **Offline Support** - Full offline functionality with sync
- **Internationalization** - Complete French/English support
- **Strategy Pattern Forms** - Extensible form system
- **Community Statistics** - Aggregate rating data
- **Smart Caching** - 5-minute service-level cache for instant navigation

## Common Tasks

### Adding a New Item Type
See [Adding New Item Types - Frontend Section](/docs/guides/adding-new-item-types.md#phase-2-frontend-implementation-50-min)


### Running the App
```bash
# Desktop (recommended for development)
flutter run -d linux

# Web
flutter run -d chrome

# Android
flutter run -d android
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

- **Framework:** Flutter 3.27+
- **State Management:** Riverpod
- **Routing:** GoRouter with async initialization
- **Localization:** Flutter built-in i18n with .arb files
- **HTTP:** Dio with HTTP/2 support
- **Storage:** SharedPreferences for local data
- **Caching:** Service-level singleton caching (5-minute expiry)
- **Performance:** HTTP/2 multiplexing via Cloud Run

## Project Structure

```
apps/client/
├── lib/
│   ├── models/          # Data models (RateableItem interface)
│   ├── providers/       # Riverpod state management
│   ├── services/        # API services with caching
│   ├── screens/         # UI screens
│   ├── widgets/         # Reusable components
│   ├── forms/           # Form strategies
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

- ✅ **Linux Desktop** - Primary development platform
- ✅ **Web** - Production target (PWA)
- ✅ **Android** - Native mobile app
- 🔄 **iOS** - Future support
- 🔄 **macOS** - Future support
- 🔄 **Windows** - Future support

## License

Private - All Rights Reserved

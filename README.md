# EverGreen

Enterprise-grade Flutter mobile application with Clean Architecture.

## Features

- 🔐 **Authentication**: JWT-based login/registration with secure token storage
- 📱 **Dashboard**: Personalized dashboard with user info and activity
- 👤 **Profile Management**: View and edit user profile
- ⚙️ **Settings**: App preferences and account management
- 🌐 **Real-time Updates**: WebSocket support for live data
- 📬 **Push Notifications**: Firebase-based notifications

## Architecture

This project follows **Clean Architecture** with a **feature-first** folder structure:

```
lib/
├── app.dart                    # App widget
├── main_dev.dart              # Dev entry point
├── main_staging.dart          # Staging entry point
├── main_prod.dart             # Production entry point
├── core/                      # Core functionality
│   ├── config/               # Environment configuration
│   ├── errors/               # Error handling & failures
│   ├── network/              # API client, interceptors
│   ├── router/               # Navigation (go_router)
│   ├── storage/              # Secure storage
│   ├── theme/                # App theme & colors
│   ├── utils/                # Validators, helpers
│   └── widgets/              # Core widgets
├── features/                  # Feature modules
│   ├── auth/
│   │   ├── data/            # Repositories implementation
│   │   ├── domain/          # Models, repositories, use cases
│   │   └── presentation/    # Screens, providers, widgets
│   ├── dashboard/
│   ├── profile/
│   └── settings/
└── shared/                    # Shared components
    ├── providers/            # Global state providers
    └── widgets/              # Reusable widgets
```

## Tech Stack

- **State Management**: flutter_riverpod
- **Navigation**: go_router
- **HTTP Client**: Dio
- **Real-time**: web_socket_channel
- **Secure Storage**: flutter_secure_storage
- **Functional Programming**: fpdart
- **Code Generation**: freezed, json_serializable
- **Push Notifications**: firebase_messaging

## Getting Started

### Prerequisites

- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Installation

1. Install dependencies:
   ```bash
   flutter pub get
   ```

2. Run code generation:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

3. Run the app:
   ```bash
   # Development
   flutter run -t lib/main_dev.dart

   # Staging
   flutter run -t lib/main_staging.dart

   # Production
   flutter run -t lib/main_prod.dart
   ```

### Deploying the website

Build the web app with a base path matching where the host serves it. For a
custom domain or a site served from the domain root:

```bash
flutter build web --release --base-href /
```

For a GitHub Pages project site, use the repository name as the path:

```bash
flutter build web --release --base-href /<repository-name>/
```

For Vercel, use `/` as the base path (the repository name is not part of the
Vercel site URL), publish `build/web`, and configure a single-page-app fallback
to `index.html` for app routes. The build environment must have Flutter
installed before running the build command.

The static host must serve `index.html` for app routes such as `/services` and
`/contact` (while serving existing asset files normally). Without that
single-page-app fallback, direct links and page refreshes on those routes return
a host-level 404.

## Environment Configuration

The app supports three environments:
- **Development**: `main_dev.dart` - Debug logging enabled, mock APIs
- **Staging**: `main_staging.dart` - Testing environment
- **Production**: `main_prod.dart` - Production APIs, analytics enabled

## Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test
```

## License

This project is proprietary and confidential.

# SendAGift Mobile

Flutter client for the SendAGift platform (companion to `send-agift-backend` and `send-agift-frontend`).

## Getting started

```bash
cp .env.example .env   # point API_BASE_URL at your backend
flutter pub get
flutter run
```

## Project structure

Feature-first layout:

```
lib/
  app/                # App widget, root shell (bottom nav)
  core/
    config/            # Environment/config (AppConfig)
    network/           # ApiClient (Dio), token storage, providers
    router/            # go_router route definitions
    theme/              # Colors, ThemeData
    errors/             # Shared exception types
    widgets/            # Shared/reusable widgets
  features/
    auth/
    home/
    products/
    cart/
    orders/
    profile/
      data/             # API/repository implementations
      domain/           # Models, repository interfaces
      presentation/
        screens/
        widgets/
```

Each feature is self-contained (data/domain/presentation) so features can grow independently.

## Stack

- **State management:** `flutter_riverpod`
- **Routing:** `go_router` (with a `StatefulShellRoute` bottom-nav shell)
- **Networking:** `dio`, wrapped in `ApiClient`
- **Secure storage:** `flutter_secure_storage` for auth tokens
- **Env config:** `flutter_dotenv`

This is the initial scaffold — screens are placeholders and auth/data layers are not yet wired to the backend.

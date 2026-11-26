# Teamly Flutter

Starter mobile app for migrating Teamly from React to Flutter.

## Included
- Material 3 UI and bottom navigation
- Login and register screens (UI starter)
- Dashboard, projects, tasks, team, and AI assistant screens
- Dio API client and secure token storage
- Riverpod and GoRouter setup
- Example API service methods

## Run
1. Install Flutter SDK.
2. Run `flutter pub get`.
3. Update `lib/core/config/app_config.dart` with your FastAPI base URL.
4. Run `flutter run`.

## Backend connection
The app expects the existing FastAPI backend. Confirm actual routes, request bodies,
response schemas, and authentication format against the backend source before enabling
production calls. The API methods in this starter are examples based on the documented
Teamly routes and may need adjustment.

For Android emulator, a common local API address is `http://10.0.2.2:8000`.
For a physical device, use your computer's LAN IP address and ensure both devices
are on the same network.

## Important
This is a Flutter starter/migration scaffold, not a verified one-to-one port of every
feature in the original repository. The original GitHub source could not be cloned in
this session, so backend compatibility has not been tested. Email and Gemini secrets
must remain on the FastAPI backend, never inside the Flutter app.

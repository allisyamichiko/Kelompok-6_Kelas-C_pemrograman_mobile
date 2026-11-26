import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';

final appRouter = GoRouter(
  initialLocation: '/welcome',
  routes: [
    GoRoute(
      path: '/welcome',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/auth',
      builder: (context, state) {
        final mode = state.uri.queryParameters['mode'] ?? 'login';
        final prompt = state.uri.queryParameters['prompt'] ?? '';
        return AuthScreen(initialMode: mode, promptMessage: prompt);
      },
    ),
    GoRoute(
      path: '/app',
      builder: (context, state) => const MainShell(),
    ),
  ],
);

import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/generator_2d_screen.dart';
import '../screens/viewer_3d_screen.dart';
import '../screens/theme_lab_screen.dart';

/// Central route table. Using path-based routing (not hash) works fine on
/// GitHub Pages as long as you deploy a 404.html fallback (see guide.html) —
/// or switch to `setUrlStrategy` hash mode if you don't want a 404.html.
///
/// [initialLocation] lets main.dart hand back the "real" deep-linked path
/// recovered from the 404.html redirect trick (see main.dart + web/404.html).
/// Deep links straight into /generator or /viewer3d fall back to /dashboard
/// on a cold load since those screens need in-memory state that only exists
/// once you've generated a plan.
GoRouter buildAppRouter(String initialLocation) {
  const deepLinkSafe = {'/', '/loading', '/dashboard', '/theme-lab'};
  final safeLocation = deepLinkSafe.contains(initialLocation) ? initialLocation : '/dashboard';

  return GoRouter(
    initialLocation: safeLocation,
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/loading', builder: (context, state) => const LoadingScreen()),
      GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
      GoRoute(path: '/generator', builder: (context, state) => const Generator2DScreen()),
      GoRoute(path: '/viewer3d', builder: (context, state) => const Viewer3DScreen()),
      GoRoute(path: '/theme-lab', builder: (context, state) => const ThemeLabScreen()),
    ],
  );
}

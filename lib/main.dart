import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive works fully offline on Flutter Web via IndexedDB — no server needed.
  await Hive.initFlutter();

  // Clean path-based URLs (no "#/") instead of GoRouter's default hash
  // routing. NOTE: if you deploy under a sub-path on GitHub Pages
  // (yourname.github.io/repo-name/) you MUST also add a 404.html that
  // redirects back to index.html — see guide.html, Section 2.
  usePathUrlStrategy();

  // Completes the 404.html deep-link redirect loop: if 404.html stashed
  // the originally-requested path in sessionStorage, jump straight there
  // once the app boots (so a hard refresh on /generator still lands on
  // /generator instead of always resetting to /).
  final redirect = html.window.sessionStorage.remove('pc_redirect');
  final initialLocation = (redirect != null && redirect.isNotEmpty) ? redirect : '/';

  runApp(ProviderScope(child: PlanCraftApp(initialLocation: initialLocation)));
}

class PlanCraftApp extends ConsumerWidget {
  final String initialLocation;
  const PlanCraftApp({super.key, this.initialLocation = '/'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(currentSchemeProvider);
    return MaterialApp.router(
      title: 'PlanCraft Pro AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(accent: scheme.primary),
      routerConfig: buildAppRouter(initialLocation),
    );
  }
}

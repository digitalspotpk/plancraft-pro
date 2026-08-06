import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/app_router.dart';
import 'core/app_theme.dart';
import 'providers/theme_provider.dart';

void main() {
  runZonedGuarded<void>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Container(
        color: const Color(0xFF05050A),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: Text(
          'RENDER ERROR:\n${details.exceptionAsString()}',
          style: const TextStyle(color: Color(0xFFFF4D6D), fontSize: 12, fontFamily: 'monospace'),
        ),
      );
    };
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _showFatalOnDom('FLUTTER ERROR: ${details.exceptionAsString()}');
    };

    await Hive.initFlutter();
    usePathUrlStrategy();

    String initialLocation = '/';
    try {
      final redirect = html.window.sessionStorage.remove('pc_redirect');
      if (redirect != null && redirect.isNotEmpty) initialLocation = redirect;
    } catch (_) {}

    runApp(ProviderScope(
      child: PlanCraftApp(router: buildAppRouter(initialLocation)),
    ));
  }, (error, stack) {
    _showFatalOnDom('FATAL: $error');
    if (kDebugMode) {
      // ignore: avoid_print
      print('$error\n$stack');
    }
  });
}

void _showFatalOnDom(String message) {
  try {
    var el = html.document.getElementById('fatal-error-box');
    if (el == null) {
      el = html.DivElement()
        ..id = 'fatal-error-box'
        ..style.position = 'fixed'
        ..style.inset = '0'
        ..style.zIndex = '99999'
        ..style.background = '#05050A'
        ..style.color = '#FF4D6D'
        ..style.fontFamily = 'monospace'
        ..style.fontSize = '12px'
        ..style.padding = '20px'
        ..style.whiteSpace = 'pre-wrap'
        ..style.overflow = 'auto';
      html.document.body?.append(el);
    }
    el.text = ((el.text ?? '') + '\n' + message).trim();
  } catch (_) {}
}

class PlanCraftApp extends ConsumerWidget {
  final GoRouter router;
  const PlanCraftApp({super.key, required this.router});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = ref.watch(currentSchemeProvider);
    return MaterialApp.router(
      title: 'PlanCraft Pro AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(accent: scheme.primary),
      routerConfig: router,
    );
  }
}

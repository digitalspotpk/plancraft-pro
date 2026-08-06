import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/app_theme.dart';

/// One entry of the "10 color schemes" used by Theme Lab.
class ColorScheme10 {
  final String name;
  final Color primary;
  final Color secondary;
  const ColorScheme10(this.name, this.primary, this.secondary);
}

const List<ColorScheme10> kColorSchemes = [
  ColorScheme10('Neon Cyan', AppColors.cyan, AppColors.purple),
  ColorScheme10('Violet Dream', AppColors.purple, Color(0xFFFF3EA5)),
  ColorScheme10('Cyber Pink', Color(0xFFFF3EA5), AppColors.cyan),
  ColorScheme10('Mint Circuit', Color(0xFF39FFB0), Color(0xFF3E8BFF)),
  ColorScheme10('Solar Flare', Color(0xFFFFD23E), Color(0xFFFF6B3E)),
  ColorScheme10('Ocean Pulse', Color(0xFF3E8BFF), AppColors.cyan),
  ColorScheme10('Magma', Color(0xFFFF6B3E), Color(0xFFFF3E6B)),
  ColorScheme10('Toxic Lime', Color(0xFFB6FF3E), Color(0xFF39FFB0)),
  ColorScheme10('Rose Static', Color(0xFFFF3E6B), AppColors.purple),
  ColorScheme10('Arctic Glass', Color(0xFF7CFFF5), Color(0xFF3E8BFF)),
];

/// Holds the currently-active accent scheme index. Persisted to Hive so the
/// chosen theme survives a page refresh (still 100% offline — Hive on web
/// uses IndexedDB under the hood).
class ThemeIndexNotifier extends StateNotifier<int> {
  ThemeIndexNotifier() : super(0) {
    _restore();
  }

  static const _boxName = 'settingsBox';
  static const _key = 'schemeIndex';

  Future<void> _restore() async {
    final box = await Hive.openBox(_boxName);
    state = (box.get(_key, defaultValue: 0) as int).clamp(0, kColorSchemes.length - 1);
  }

  Future<void> setIndex(int i) async {
    state = i;
    final box = await Hive.openBox(_boxName);
    await box.put(_key, i);
  }
}

final themeIndexProvider =
    StateNotifierProvider<ThemeIndexNotifier, int>((ref) => ThemeIndexNotifier());

final currentSchemeProvider = Provider<ColorScheme10>((ref) {
  final idx = ref.watch(themeIndexProvider);
  return kColorSchemes[idx];
});

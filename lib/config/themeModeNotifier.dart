// main.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/main.dart';

// ------------------------------
// 전역 테마 상태
// ------------------------------

// light / dark / system
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

// light / dark / mint (커스텀 색 테마용)
final ValueNotifier<String> customThemeNotifier =
ValueNotifier<String>("light");

// ------------------------------
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // ------------------------------
  // 저장된 기본 light/dark/system 불러오기
  // ------------------------------
  final savedMode = prefs.getString('themeMode'); // system/light/dark
  if (savedMode != null) {
    switch (savedMode) {
      case 'light':
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 'dark':
        themeModeNotifier.value = ThemeMode.dark;
        break;
      case 'system':
      default:
        themeModeNotifier.value = ThemeMode.system;
        break;
    }
  }

  // ------------------------------
  // 저장된 customTheme(light/dark/mint) 불러오기
  // ------------------------------
  final savedCustomTheme = prefs.getString('customTheme');
  if (savedCustomTheme != null) {
    // 필요하면 여기서 값 검증해도 됨 (예: ['light','dark','mint'] 안에 있을 때만 대입)
    customThemeNotifier.value = savedCustomTheme;
  }

  runApp(MyApp());
}

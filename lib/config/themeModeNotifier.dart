// main.dart
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 전체에서 쓰는 전역 테마 상태
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 저장된 테마 불러오기 (system / light / dark)
  final prefs = await SharedPreferences.getInstance();
  final saved = prefs.getString('themeMode');
  if (saved != null) {
    switch (saved) {
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

  runApp( MyApp() );
}

import 'package:shared_preferences/shared_preferences.dart';

Future<void> resetPrefs() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();   // 전체 삭제 (모든 key 삭제)
  await prefs.reload();  // 혹시 캐시 남아있을까봐 강제 리로드
}
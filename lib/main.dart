import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 아이콘용
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/my/my_page.dart';
import 'package:saykoreanapp_f/pages/start/start_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';

// ─────────────────────────────────────────────
// 전역 네비게이터 키
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// 현재 라우트명 구하기
String? currentRouteName() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return null;
  return ModalRoute.of(nav.context)?.settings.name;
}

// 안전한 페이지 이동 함수
void goNamed(String routeName) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  final current = currentRouteName();
  if (current == routeName) return;
  nav.pushNamedAndRemoveUntil(routeName, (route) => false);
}
// ─────────────────────────────────────────────

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      initialRoute: "/",

      builder: (context, child) {
        final name = currentRouteName() ?? '';
        // 특정 화면(로그인/회원가입/시작)은 푸터 숨기기
        final hide = {'/', '/login', '/signup', '/find'}.contains(name);

        return Scaffold(
          body: child,
          bottomNavigationBar: hide ? null : const _FooterBar(),
          backgroundColor: const Color(0xFFFFF9F0),
        );
      },

      routes: {
        "/" : (context) => StartPage(),
        "/home" : (context) => HomePage(),
        "/login" : (context) => LoginPage(),
        "/signup" : (context) => SignupPage(),
        "/find" : (context) => FindPage(),
        "/info" : (context) => MyPage(),
        "/update" : (context) => MyInfoUpdatePage(),
        "/game": (context) => GamePage(),
        "/study": (context) => Study(),
        "/test": (context) => Test(),
        "/ranking": (context) => Ranking(),
      },
    );
  }
}

// ─────────────────────────────────────────────
// 푸터 바
class _FooterBar extends StatelessWidget {
  static const Color _bgTop    = Color(0xFFFFF9F0); // 크림
  static const Color _bgBottom = Color(0xFFFFF1E8); // 옅은 핑크
  static const Color _active   = Color(0xFFFFAAA5); // 코랄핑크
  static const Color _inactive = Color(0x80FFAAA5); // 비활성(50%)

  const _FooterBar();

  Widget _btn({
    required String label,
    required String svg,
    required String routeName,
    required bool active,
  }) {
    final color = active ? _active : _inactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => goNamed(routeName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30, width: 30,
                child: SvgPicture.asset(
                  svg,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = currentRouteName() ?? '';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: Container(
              height: 76,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_bgTop, _bgBottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 18,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _btn(label: '홈',   svg: 'assets/icons/home.svg',
                      routeName: '/home',    active: current == '/home'),
                  _btn(label: '내정보',svg: 'assets/icons/user.svg',
                      routeName: '/info',    active: current == '/info'),
                  _btn(label: '학습',  svg: 'assets/icons/study.svg',
                      routeName: '/study',   active: current == '/study'),
                  _btn(label: '시험',  svg: 'assets/icons/test.svg',
                      routeName: '/test',    active: current == '/test'),
                  _btn(label: '순위',  svg: 'assets/icons/rank.svg',
                      routeName: '/ranking', active: current == '/ranking'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

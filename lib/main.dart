import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 아이콘용
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/pages/start/start_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';
import 'package:saykoreanapp_f/pages/test/testList.dart';
import 'package:saykoreanapp_f/pages/friends/friends.dart';


// ─────────────────────────────────────────────
// 전역 네비게이터 키
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// 현재 라우트명 구하기
String? currentRouteName() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return null;
  return ModalRoute.of(nav.context)?.settings.name;
}

// 안전한 페이지 이동 함수 (arguments 지원)
void goNamed(String routeName, {Object? arguments, bool replaceAll = false}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  final current = currentRouteName();
  if (current == routeName && arguments == null) return;

  if (replaceAll) {
    nav.pushNamedAndRemoveUntil(routeName, (route) => false, arguments: arguments);
  } else {
    nav.pushNamed(routeName, arguments: arguments);
  }
}

// any → int? 안전 변환
int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
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

      // 인자(Arguments) 필요한 라우트는 여기서 처리
      onGenerateRoute: (settings) {
        if (settings.name == '/testList') {
          final studyNo = _toInt(settings.arguments);
          return MaterialPageRoute(
            builder: (_) => (studyNo == null)
                ? const _RouteArgErrorPage(message: "studyNo 인자가 필요해요.")
                : TestListPage(studyNo: studyNo),
            settings: settings,
          );
        }

        if (settings.name == '/test') {
          final testNo = _toInt(settings.arguments);
          return MaterialPageRoute(
            builder: (_) => (testNo == null)
                ? const _RouteArgErrorPage(message: "testNo 인자가 필요해요.")
                : TestPage(testNo: testNo),
            settings: settings,
          );
        }

        // null 리턴하면 아래 routes로 위임됨
        return null;
      },

      // 인자 불필요한 정적 라우트들
      routes: {
        "/"       : (context) => StartPage(),
        "/home"   : (context) => HomePage(),
        "/login"  : (context) => LoginPage(),
        "/signup" : (context) => SignupPage(),
        "/find"   : (context) => FindPage(),
        "/info"   : (context) => Mypage(),
        "/update" : (context) => MyInfoUpdatePage(),
        "/game"   : (context) => GamePage(),
        "/study"  : (context) => StudyPage(),
        "/ranking": (context) => Ranking(),
        "/friends": (context) => FriendsPage(myUserNo: 1),
      },

      // 공통 레이아웃 (푸터 표시/숨김)
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
    );
  }
}

/// 인자 누락/잘못 전달 시 보여줄 간단한 에러 페이지
class _RouteArgErrorPage extends StatelessWidget {
  final String message;
  const _RouteArgErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("오류")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("뒤로가기"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────
// 푸터 바
class _FooterBar extends StatelessWidget {
  static const Color _mint = Color(0xFFA8E6CF); // 민트
  static const Color _bgTop    = Color(0xFFFFF9F0); // 크림
  static const Color _bgBottom = Color(0xFFFFF1E8); // 옅은 핑크
  static const Color _active   = Color(0x80FFAAA5); // 코랄핑크
  static const Color _inactive = Color(0x80FFAAA5); // 비활성(50%)
  static const Color _textColor = Color(0xFF6B4E42); // 텍스트 컬러 브라운

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
                      routeName: '/',    active: current == '/'),
                  _btn(label: '내정보',svg: 'assets/icons/user.svg',
                      routeName: '/info',    active: current == '/info'),
                  _btn(label: '학습',  svg: 'assets/icons/study.svg',
                      routeName: '/study',   active: current == '/study'),
                  _btn(label: '시험',  svg: 'assets/icons/test.svg',
                      routeName: '/testList',    active: current == '/testList'),
                  _btn(label: '순위',  svg: 'assets/icons/rank.svg',
                      routeName: '/ranking', active: current == '/ranking'),
                  _btn(
                    label: '친구', svg: 'assets/icons/friends.svg', // ← 이건 네가 원하는 SVG 파일 경로
                    routeName: '/friends', active: current == '/friends',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

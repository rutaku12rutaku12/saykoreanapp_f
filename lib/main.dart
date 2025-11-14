import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 아이콘용
import 'package:saykoreanapp_f/api/dio_client.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/friends/friends.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/pages/start/start_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 성공 목록 / 테스트 목록 페이지
import 'package:saykoreanapp_f/pages/study/successList.dart';
import 'package:saykoreanapp_f/pages/test/testList.dart';

// ─────────────────────────────────────────────

// 전역 네비게이터 키
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// 현재 라우트명 구하기
String? currentRouteName() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return null;
  return ModalRoute.of(nav.context)?.settings.name;
}

// 안전한 페이지 이동 함수 (하단 탭용)
void goNamed(String routeName, {Object? arguments}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  final current = currentRouteName();
  if (current == routeName && arguments == null) return;
  nav.pushNamedAndRemoveUntil(routeName, (route) => false, arguments: arguments);
}

// any → int? 변환 유틸
int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

// ─────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  await DioClient().init();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      initialRoute: "/",

      // 인자 필요한 라우트는 여기서 처리
      onGenerateRoute: (settings) {
        if (settings.name == "/testList") {
          final studyNo = _toInt(settings.arguments);

          return MaterialPageRoute(
            builder: (_) => (studyNo == null)
                ? const _RouteArgErrorPage(message: "studyNo가 필요합니다.")
                : TestListPage(studyNo: studyNo),
            settings: settings,
          );
        }

        // 다른 라우트는 기존처럼 routes에서 처리
        return null;
      },
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
        "/"       : (context) => StartPage(),
        "/home"   : (context) => HomePage(),
        "/login"  : (context) => LoginPage(),
        "/signup" : (context) => SignupPage(),
        "/find"   : (context) => FindPage(),
        "/info"   : (context) => Mypage(),
        "/update" : (context) => MyInfoUpdatePage(),
        "/game"   : (context) => GamePage(),
        "/study"  : (context) => StudyPage(),
        // "/test"   : (context) => TestPage(testNo: testNo),
        "/ranking": (context) => Ranking(),
        "/friends": (context) => FriendsPage(myUserNo: 1),

        // 필요하면 성공 목록도 이름으로 이동
        "/successList": (context) => SuccessListPage(),
      },
    );
  }
}

// ─────────────────────────────────────────────
// 인자 누락 시 에러 페이지
class _RouteArgErrorPage extends StatelessWidget {
  final String message;
  const _RouteArgErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("오류")),
      body: Center(child: Text(message)),
    );
  }
}

// ─────────────────────────────────────────────
// 푸터 바 (네가 쓰던 버전 그대로)
// ─────────────────────────────────────────────
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

  // 시험 버튼 전용 위젯 (저장된 studyNo 읽어서 /testList로 이동)
  Widget _testBtn({required bool active}) {
    final color = active ? _active : _inactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final studies = prefs.getStringList('studies') ?? [];

          if (studies.isEmpty) {
            // 아직 완수한 주제가 없다면 안내 + 원하는 곳으로 보내기
            final ctx = appNavigatorKey.currentContext;
            if (ctx != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('아직 완수한 주제가 없어요. 먼저 학습을 완료해 주세요 😊'),
                ),
              );
            }
            // 필요하면 여기서 /study나 /successList로 이동
            // goNamed('/study');
            return;
          }

          // 리스트의 마지막 값을 "가장 최근에 완료한 주제"로 사용
          final lastStr = studies.last;
          final studyNo = int.tryParse(lastStr);

          if (studyNo == null) {
            final ctx = appNavigatorKey.currentContext;
            if (ctx != null) {
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(
                  content: Text('저장된 주제 번호가 올바르지 않아요. 다시 학습을 완료해 주세요.'),
                ),
              );
            }
            return;
          }

         // studyNo 인자 전달
          goNamed('/testList', arguments: studyNo);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 30, width: 30,
                child: SvgPicture.asset(
                  'assets/icons/test.svg',
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '시험',
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
                      routeName: '/',    active: current == '/start'),
                  _btn(label: '내정보',svg: 'assets/icons/user.svg',
                      routeName: '/info',    active: current == '/info'),
                  _btn(label: '학습',  svg: 'assets/icons/study.svg',
                      routeName: '/study',   active: current == '/study'),
                  // 시험 버튼만 매개변수가 필요하기 때문에 특별 처리
                  _testBtn(active: current == '/testList'),
                  _btn(label: '순위',  svg: 'assets/icons/rank.svg',
                      routeName: '/ranking', active: current == '/ranking'),
                  _btn(
                    label: '친구', svg: 'assets/icons/friends.svg',
                    routeName: '/friends', active: current == '/friends',),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart'; // SVG 아이콘용

import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';
import 'package:saykoreanapp_f/pages/game/game_list_page.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/pages/start/start_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 채팅 관련
import 'package:saykoreanapp_f/pages/chatting/chat_list_wrapper_page.dart';
import 'package:saykoreanapp_f/pages/chatting/chat_page.dart';

// 완수한 학습 목록 페이지
import 'package:saykoreanapp_f/pages/study/successList.dart';
// 테스트 목록 페이지
import 'package:saykoreanapp_f/pages/test/testList.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 전역 네비게이터 키
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
// ─────────────────────────────────────────────────────────────────────────────

// 현재 라우트명 구하기
// bottom tab에서 활성 탭 표시용으로 사용
String? currentRouteName() {
  final nav = appNavigatorKey.currentState; // 현재 네비게이터 상태
  if (nav == null) return null; // 아직 빌드가 안됐다면 null 처리
  return ModalRoute.of(nav.context)?.settings.name; // 현재 route 이름 반환
}

// ─────────────────────────────────────────────────────────────────────────────

// 안전한 페이지 이동 함수 (하단 탭용)
void goNamed(String routeName, {Object? arguments}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  final current = currentRouteName(); // 현재 화면 이름
  if (current == routeName && arguments == null) return; // 같은 페이지면 무시

  // 새로운 route로 이동
  nav.pushNamedAndRemoveUntil(
    routeName,
    (route) => false,
    arguments: arguments,
  );
}

// ─────────────────────────────────────────────────────────────────────────────

// any 타입을 int?로 안전하게 변환하는 유틸
int? _toInt(dynamic v) {
  if (v is int) return v; // 이미 int면 그대로
  if (v is num) return v.toInt(); // num이면 toInt()
  if (v is String) return int.tryParse(v); // String이면 파싱
  return null; // 그 외는 null
}

// ─────────────────────────────────────────────────────────────────────────────
// 앱 진입점
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  runApp(MyApp());
}


// ─────────────────────────────────────────────────────────────────────────────
// 최상위 위젯
// ─────────────────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // debug 표시 없애기
      debugShowCheckedModeBanner: false,
      navigatorKey: appNavigatorKey,
      initialRoute: "/",

      // 인자 필요한 라우트는 여기서 처리
      onGenerateRoute: (settings) {
        // testList는 studyNo 인자가 필요함
        if (settings.name == "/testList") {
          final studyNo = _toInt(settings.arguments);

          return MaterialPageRoute(
            builder: (_) => (studyNo == null)
            // 인자 없으면 에러 페이지로
                ? const _RouteArgErrorPage(message: "studyNo가 필요합니다.")
                // 정상이라면 TestListPage 표시
                : TestListPage(),
            settings: settings,
          );
        }


        // 개별 채팅방
        if (settings.name == '/chatRoom') {
          final args = settings.arguments as Map<String, dynamic>;
          final roomNo = args['roomNo'] as int;
          final friendName = args['friendName'] as String;
          final myUserNo = args['myUserNo'] as int;

          return MaterialPageRoute(
            builder: (_) => ChatPage(
              roomNo: roomNo,
              friendName: friendName,
              myUserNo: myUserNo,
            ),
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

      // ───────────────────────────────────────────────────────────────────────
      // 이름 기반 정적 라우트 매핑
      routes: {
        "/": (context) => StartPage(), // 시작화면
        "/home": (context) => HomePage(), // 홈
        "/login": (context) => LoginPage(), // 로그인
        "/signup": (context) => SignupPage(), // 회원가입
        "/find": (context) => FindPage(), // 계정/비번 찾기
        "/info": (context) => MyPage(), // 내정보(마이페이지)
        "/update": (context) => MyInfoUpdatePage(), // 내정보 수정
        "/game": (context) => GameListPage(), // 게임 목록 페이지
        "/study": (context) => StudyPage(), // 학습
        // "/test"   : (context) => TestPage(testNo: testNo),
        "/ranking": (context) => Ranking(), // 순위
        "/chat": (context) => FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            final prefs = snap.data!;
            final userNo = prefs.getInt("myUserNo");

            if (userNo == null) return LoginPage();

            return ChatListWrapperPage(myUserNo: userNo);
          },
        ),

        // 필요하면 성공 목록도 이름으로 이동 ( 완수한 학습 목록 )
        "/successList": (context) => SuccessListPage(),
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 인자 누락 시 에러 페이지
// ─────────────────────────────────────────────────────────────────────────────
class _RouteArgErrorPage extends StatelessWidget {
  final String message;

  const _RouteArgErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("오류")), // 상단 바
      body: Center(child: Text(message)), // 전달된 에러 메세지 표시
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 하단 푸터바
// ─────────────────────────────────────────────────────────────────────────────
class _FooterBar extends StatelessWidget {
  static const Color _bgTop = Color(0xFFFFF9F0); // 크림
  static const Color _bgBottom = Color(0xFFFFF1E8); // 옅은 핑크
  static const Color _active = Color(0xFFFFAAA5); // 코랄핑크
  static const Color _inactive = Color(0x80FFAAA5); // 비활성 탭 (50%)

  const _FooterBar();

  // 공통 탭 버튼 위젯
  Widget _btn({
    required String label, // 텍스트
    required String svg, // SVG 경로
    required String routeName, // 이동할 라우트 이름
    required bool active, // 선택 여부
  }) {
    final color = active ? _active : _inactive; // 상태에 따른 색상 선택
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque, // 빈 영역도 터치되도록

        onTap: () async { // * 은주 수정함
          if (routeName == '/chat') {
            final prefs = await SharedPreferences.getInstance();
            final myUserNo = prefs.getInt('myUserNo');

            if (myUserNo == null) {
              goNamed('/login');
              return;
            }

            goNamed('/chat', arguments: myUserNo);
          } else {
            goNamed(routeName);
          }
        },// 탭 클릭 시 페이지 이동
        //-------------------------------------FooterBar에서 userNo 이 전달되지 않아서 오류남

        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              // 아이콘 영역
              SizedBox(
                height: 30,
                width: 30,
                child: SvgPicture.asset(
                  svg,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                ),
              ),
              const SizedBox(height: 6),

              // 아이콘 아래 텍스트
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

  // 시험 버튼 전용 위젯
  // sharedPreferences에서 studies 리스트 읽
  Widget _testBtn({required bool active}) {
    final color = active ? _active : _inactive;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () async {
          final prefs = await SharedPreferences.getInstance();
          final studies = prefs.getStringList('studies') ?? [];

          if (studies.isEmpty) {
            // 아직 완수한 주제가 없을 때
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


          // 변환 실패시 안내
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
                height: 30,
                width: 30,
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
    // 현재 routeName을 기준으로 어떤 탭이 활성이지 판단
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
                  _btn(
                    label: '홈',
                    svg: 'assets/icons/home.svg',
                    routeName: '/', // 홈 화면으로 이동
                    active: current == '/home',
                  ),
                  _btn(
                    label: '내정보',
                    svg: 'assets/icons/user.svg',
                    routeName: '/info',
                    active: current == '/info',
                  ),
                  _btn(
                    label: '학습',
                    svg: 'assets/icons/study.svg',
                    routeName: '/study',
                    active: current == '/study',
                  ),

                  // 시험 (완수한 주제 기준)
                  _testBtn(active: current == '/testList'),

                  // 게임 버튼
                  _btn(
                    label: '게임',
                    svg: 'assets/icons/game.svg',
                    routeName: '/game',
                    active: current == '/game',
                  ),

                  _btn(
                    label: '순위',
                    svg: 'assets/icons/rank.svg',
                    routeName: '/ranking',
                    active: current == '/ranking',
                  ),
                  _btn(
                    label: '채팅',
                    svg: 'assets/icons/friends.svg',
                    routeName: '/chat',
                    active: current == '/chat',
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

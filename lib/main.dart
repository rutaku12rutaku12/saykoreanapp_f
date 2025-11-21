import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_client.dart';

import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/game/game_list_page.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/setting/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/pages/auth/start_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/test/loading.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';
import 'package:saykoreanapp_f/pages/test/test_mode_page.dart';
import 'package:saykoreanapp_f/utils/if_login.dart';
import 'package:saykoreanapp_f/utils/recaptcha_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saykoreanapp_f/pages/chatting/chat_list_wrapper_page.dart';
import 'package:saykoreanapp_f/pages/chatting/chat_page.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';
import 'package:saykoreanapp_f/pages/test/testList.dart';
import 'package:saykoreanapp_f/pages/store/store.dart';

// -------------------- 전역 상태 -------------------- //
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

String? currentRouteName() {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return null;
  return ModalRoute.of(nav.context)?.settings.name;
}

void goNamed(String routeName, {Object? arguments}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;
  final current = currentRouteName();
  if (current == routeName && arguments == null) return;

  nav.pushNamedAndRemoveUntil(
    routeName,
        (route) => false,
    arguments: arguments,
  );
}

// -------------------- 민트 테마 -------------------- //
final ThemeData mintTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFE7FFF6),
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF2F7A69),
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFFFFFFF),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE7FFF6),
    foregroundColor: Color(0xFF2F7A69),
    elevation: 0,
  ),
);

// -------------------- 메인 함수 -------------------- //
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const String androidSiteKey =
      "6LeHHw8sAAAAAAqE6e3b2hu7w9azw3_3udTKbHcp";

  try {
    RecaptchaClient client = await Recaptcha.fetchClient(androidSiteKey);
    RecaptchaManager.setClient(client);
  } catch (e) {
    print("reCAPTCHA error: $e");
  }

  runApp(MyApp());
}

// -------------------- 최상위 앱 -------------------- //
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                home: const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ),
              );
            }

            final prefs = snap.data!;
            final customTheme = prefs.getString("themeMode"); // "mint"

            // 기본 MaterialApp 만들기
            final baseApp = MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              initialRoute: "/",
              themeMode: mode,
              theme: ThemeData(
                useMaterial3: true,
                brightness: Brightness.light,
                scaffoldBackgroundColor: const Color(0xFFFFF9F0),
                colorScheme: ColorScheme.fromSeed(
                  seedColor: const Color(0xFF6B4E42),
                  brightness: Brightness.light,
                ),
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFFFF9F0),
                  foregroundColor: Color(0xFF6B4E42),
                  elevation: 0,
                ),
              ),
              darkTheme: _darkTheme(),
              builder: (context, child) {
                final name = currentRouteName() ?? '';
                final hide = {'/', '/login', '/signup', '/find'}
                    .contains(name);

                return Scaffold(
                  body: child,
                  bottomNavigationBar: hide ? null : const _FooterBar(),
                  backgroundColor:
                  Theme.of(context).scaffoldBackgroundColor,
                );
              },
              onGenerateRoute: _onGenerateRoute,
              routes: _routes,
            );

            // ⭐ 민트 테마면 baseApp 전체를 덮어씌움
            if (customTheme == "mint") {
              return Theme(data: mintTheme, child: baseApp);
            }

            // 기본 라이트/다크 사용
            return baseApp;
          },
        );
      },
    );
  }
}

// -------------------- 다크 테마 정의 -------------------- //
ThemeData _darkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF1E1816),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4E42),
      brightness: Brightness.dark,
    ).copyWith(
      surface: const Color(0xFF261E1B),
      surfaceContainerHighest: const Color(0xFF2D2421),
      surfaceContainerHigh: const Color(0xFF29201D),
      surfaceContainer: const Color(0xFF231B19),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1816),
      foregroundColor: Color(0xFFF7E0B4),
      elevation: 0,
      centerTitle: true,
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF261E1B),
      elevation: 1,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1E1816),
      selectedItemColor: Color(0xFFF7E0B4),
      unselectedItemColor: Color(0xFFB0A3A0),
      type: BottomNavigationBarType.fixed,
    ),
  );
}

// -------------------- 라우트 -------------------- //
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  if (settings.name == "/testList") {
    final studyNo = int.tryParse(settings.arguments.toString());

    return MaterialPageRoute(
      builder: (_) => (studyNo == null)
          ? const _RouteArgErrorPage(message: "studyNo가 필요합니다.")
          : IfLogin(child: TestModePage()),
    );
  }

  if (settings.name == '/chatRoom') {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      builder: (_) => IfLogin(
        child: ChatPage(
          roomNo: args['roomNo'],
          friendName: args['friendName'],
          myUserNo: args['myUserNo'],
        ),
      ),
    );
  }

  return null;
}

final Map<String, WidgetBuilder> _routes = {
  "/": (context) => StartPage(),
  "/login": (context) => LoginPage(),
  "/signup": (context) => SignupPage(),
  "/find": (context) => FindPage(),

  "/home": (context) => IfLogin(child: HomePage()),
  "/store": (context) => StorePage(),
  "/info": (context) => IfLogin(child: MyPage()),
  "/update": (context) => IfLogin(child: MyInfoUpdatePage()),
  "/game": (context) => IfLogin(child: GameListPage()),
  "/study": (context) => IfLogin(child: StudyPage()),
  "/ranking": (context) => IfLogin(child: Ranking()),
  "loading": (context) => IfLogin(child: LoadingPage()),
  "/chat": (context) => IfLogin(
    child: FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final prefs = snap.data!;
        final userNo = prefs.getInt("myUserNo");
        if (userNo == null) return LoginPage();
        return ChatListWrapperPage(myUserNo: userNo);
      },
    ),
  ),
  "/successList": (context) => IfLogin(child: SuccessListPage()),
};

// -------------------- 에러 페이지 -------------------- //
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

// -------------------- 푸터바 -------------------- //
class _FooterBar extends StatelessWidget {
  static const Color _bgTop = Color(0xFFFFF9F0);
  static const Color _bgBottom = Color(0xFFFFF1E8);
  static const Color _active = Color(0xFFFFAAA5);
  static const Color _inactive = Color(0x80FFAAA5);

  const _FooterBar();

  @override
  Widget build(BuildContext context) {
    final current = currentRouteName() ?? '';

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
              children: [
                _item("홈", "assets/icons/home.svg", "/home",
                    current == "/home"),
                _item("내정보", "assets/icons/user.svg", "/info",
                    current == "/info"),
                _item("학습", "assets/icons/study.svg", "/study",
                    current == "/study"),
                _item("스토어", "assets/icons/store_icon.svg", "/store",
                    current == "/store"),
                _item("시험", "assets/icons/test.svg", "/testList",
                    current == "/testList"),
                _item("게임", "assets/icons/game.svg", "/game",
                    current == "/game"),
                _item("순위", "assets/icons/rank.svg", "/ranking",
                    current == "/ranking"),
                _item("채팅", "assets/icons/friends.svg", "/chat",
                    current == "/chat"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
      String label, String svg, String route, bool active) {
    final c = active ? _active : _inactive;

    return Expanded(
      child: GestureDetector(
        onTap: () => goNamed(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(svg,
                height: 28,
                colorFilter: ColorFilter.mode(c, BlendMode.srcIn)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: c))
          ],
        ),
      ),
    );
  }
}

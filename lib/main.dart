import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha.dart';

import 'package:saykoreanapp_f/utils/recaptcha_manager.dart';
import 'package:saykoreanapp_f/utils/if_login.dart';

import 'package:saykoreanapp_f/pages/auth/start_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';

import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/pages/setting/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/study/study.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';

import 'package:saykoreanapp_f/pages/test/test_mode_page.dart';
import 'package:saykoreanapp_f/pages/test/loading.dart';
import 'package:saykoreanapp_f/pages/test/ranking.dart';

import 'package:saykoreanapp_f/pages/game/game_list_page.dart';
import 'package:saykoreanapp_f/pages/store/store.dart';

import 'package:saykoreanapp_f/pages/chatting/chat_list_wrapper_page.dart';
import 'package:saykoreanapp_f/pages/chatting/chat_page.dart';
import 'package:saykoreanapp_f/pages/test/testResult.dart';


import 'package:saykoreanapp_f/api/resetPrefs.dart';

import 'package:easy_localization/easy_localization.dart';

// ─────────────────────────────────────────────────────────────
// 전역 상태
// ─────────────────────────────────────────────────────────────

// 다크/라이트/시스템 테마 모드
final ValueNotifier<ThemeMode> themeModeNotifier =
ValueNotifier<ThemeMode>(ThemeMode.system);

// 민트 / 기본 색상 테마
// - 'default' : 기본 라이트 테마
// - 'mint'    : 민트 테마
final ValueNotifier<String> themeColorNotifier =
ValueNotifier<String>('default');

// 현재 라우트 이름 추적용
final ValueNotifier<String?> currentRouteNotifier =
ValueNotifier<String?>(null);

// 전역 네비게이터 키
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();


@immutable
class AppColors extends ThemeExtension<AppColors> {
  final Color iconTileBg;   // 네모 박스 배경색
  final Color iconTileIcon; // 그 안의 아이콘 색

  const AppColors({
    required this.iconTileBg,
    required this.iconTileIcon,
  });

  @override
  AppColors copyWith({
    Color? iconTileBg,
    Color? iconTileIcon,
  }) {
    return AppColors(
      iconTileBg: iconTileBg ?? this.iconTileBg,
      iconTileIcon: iconTileIcon ?? this.iconTileIcon,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      iconTileBg: Color.lerp(iconTileBg, other.iconTileBg, t)!,
      iconTileIcon: Color.lerp(iconTileIcon, other.iconTileIcon, t)!,
    );
  }
}


// 라우트 변화를 감지하는 Observer
class AppRouteObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    if (route is PageRoute) {
      currentRouteNotifier.value = route.settings.name;
    } else {
      currentRouteNotifier.value = null;
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    _update(route);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    _update(previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _update(newRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    _update(previousRoute);
  }
}

// ─────────────────────────────────────────────────────────────
// ThemeMode <-> String 변환 + setter
// ─────────────────────────────────────────────────────────────

ThemeMode _themeModeFromString(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    case 'system':
    default:
      return ThemeMode.system;
  }
}

String _themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
    default:
      return 'system';
  }
}

// 어디서든 호출해서 다크/라이트/시스템 변경
Future<void> setThemeMode(ThemeMode mode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('themeMode', _themeModeToString(mode));
  themeModeNotifier.value = mode;
}

// 민트 / 기본 색상 변경 (ex. 'mint' 또는 'default')
Future<void> setThemeColor(String color) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('themeColor', color);
  themeColorNotifier.value = color;
}

// ─────────────────────────────────────────────────────────────
// Theme 정의
// ─────────────────────────────────────────────────────────────

ThemeData _lightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFFFF9F0),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6B4E42),
      brightness: Brightness.light,
    ).copyWith(
      // 아이콘 네모 박스용
      secondaryContainer: const Color(0xFFFFE5CF),  // 네모 배경
      onSecondaryContainer: const Color(0xFF6B4E42), // 아이콘 색
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFF9F0),
      foregroundColor: Color(0xFF6B4E42),
      elevation: 0,
      centerTitle: true,
    ),
  );
}
// 민트 테마 (배경: 더 연한 민트)
final ThemeData mintTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  // 전체 배경을 훨씬 더 연한 민트로
  scaffoldBackgroundColor: const Color(0xFFE7FFF6), // 아주 연한 민트

  // 포인트 컬러는 기존 #A8E6CF 그대로 사용
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFFA8E6CF),
    brightness: Brightness.light,
  ).copyWith(
    surface: const Color(0xFFFFFFFF),
    surfaceContainer: const Color(0xFFF4FFFA),      // 거의 흰색에 가까운 연한 민트
    surfaceContainerHigh: const Color(0xFFE7FFF6),  // 배경이랑 비슷한 톤
    surfaceContainerHighest: const Color(0xFFD3F8EA),
    // 아이콘 네모 박스용 (민트 버전)
    secondaryContainer: const Color(0xFFD3F8EA),   // 연민트 네모
    onSecondaryContainer: const Color(0xFF2F7A69), // 진한 민트 아이콘
  ),



  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFE7FFF6), // 앱바도 연한 민트
    foregroundColor: Color(0xFF2F7A69),
    elevation: 0,
    centerTitle: true,
  ),

  cardTheme: const CardThemeData(
    // 전체 배경이 E7FFF6 이라서, 카드만 살~짝 진한 민트
    color: Color(0xFFF4FFFA),
    elevation: 1,
    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(18)),
    ),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFE7FFF6), // 하단 바도 연한 민트
    selectedItemColor: Color(0xFF2F7A69),
    unselectedItemColor: Color(0x802F7A69),
    type: BottomNavigationBarType.fixed,
  ),
);

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

// ─────────────────────────────────────────────────────────────
// main()
// ─────────────────────────────────────────────────────────────

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // // !!!!!!!!!!!! 앱 시작 전에 SharedPreferences 전체 초기화 !!!!!!!!!!!!!
  // await resetPrefs();

  // reCAPTCHA 초기화
  const String androidSiteKey = "6LeHHw8sAAAAAAqE6e3b2hu7w9azw3_3udTKbHcp";
  try {
    final client = await Recaptcha.fetchClient(androidSiteKey);
    RecaptchaManager.setClient(client);
  } catch (e) {
    print("reCAPTCHA error: $e");
  }

  // SharedPreferences에서 themeMode / themeColor 로드
  final prefs = await SharedPreferences.getInstance();

  final savedMode = prefs.getString('themeMode'); // 'light' | 'dark' | 'system'
  themeModeNotifier.value = _themeModeFromString(savedMode);

  final savedThemeColor = prefs.getString('themeColor'); // 'default' | 'mint'
  if (savedThemeColor != null) {
    themeColorNotifier.value = savedThemeColor;
  }

  // 🌍 다국어 초기화
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
        Locale('es'),
        Locale('zh', 'CN'),
      ],
      path: 'assets/i18n', // ← JSON 폴더 경로
      fallbackLocale: const Locale('ko'),
      child: MyApp(),      // ← 여기 감싸야 함
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// MyApp
// ─────────────────────────────────────────────────────────────

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, mode, _) {
        return ValueListenableBuilder<String>(
          valueListenable: themeColorNotifier,
          builder: (context, themeColor, __) {
            final bool isMint = themeColor == 'mint';
            final ThemeData lightTheme =
            isMint ? mintTheme : _lightTheme();

            final app = MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: appNavigatorKey,
              initialRoute: "/",

              // 🌍 다국어 적용
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,

              themeMode: mode,
              theme: lightTheme,
              darkTheme: _darkTheme(),
              navigatorObservers: [
                AppRouteObserver(),
              ],
              builder: (context, child) {
                return ValueListenableBuilder<String?>(
                  valueListenable: currentRouteNotifier,
                  builder: (context, routeName, _) {
                    final name = routeName ?? '';
                    final hide = {'/', '/login', '/signup', '/find'}.contains(name);

                    return Scaffold(
                      body: child,
                      bottomNavigationBar:
                      hide ? null : _FooterBar(currentRoute: name),
                      backgroundColor:
                      Theme.of(context).scaffoldBackgroundColor,
                    );
                  },
                );
              },

              // 여기 두 개만 남기기
              onGenerateRoute: _onGenerateRoute,
              routes: _routes,
            );
            return app;
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 라우터
// ─────────────────────────────────────────────────────────────
Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
  if (settings.name == "/testList") {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => IfLogin(child: const TestModePage()),
    );
  }

  if (settings.name == '/chatRoom') {
    final args = settings.arguments as Map<String, dynamic>;
    return MaterialPageRoute(
      settings: settings,
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
  "/loading": (context) => IfLogin(child: LoadingPage()),
  "/testresult": (context) => IfLogin(child: TestResultPage()),
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

// ─────────────────────────────────────────────────────────────
// 에러 페이지
// ─────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────
// 푸터바
// ─────────────────────────────────────────────────────────────
class _FooterBar extends StatelessWidget {
  final String currentRoute;

  const _FooterBar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final current = currentRoute;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint';
    final isHome = current == '/home';

    // 모드/테마별 색 결정
    late final Color bgTop;
    late final Color bgBottom;
    late final Color activeColor;
    late final Color inactiveColor;

    if (isDark) {
      bgTop = scheme.surfaceContainerHigh;
      bgBottom = scheme.surface;
      activeColor = scheme.primary;
      inactiveColor = scheme.primary.withOpacity(0.5);
    } else if (isMint) {
      bgTop = const Color(0xFFE7FFF6);
      bgBottom = const Color(0xFFD3F8EA);
      activeColor = const Color(0xFF2F7A69);
      inactiveColor = const Color(0x802F7A69);
    } else {
      bgTop = const Color(0xFFFFF9F0);
      bgBottom = const Color(0xFFFFF1E8);
      activeColor = const Color(0xFFFFAAA5);
      inactiveColor = const Color(0x80FFAAA5);
    }

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 76,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [bgTop, bgBottom],
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 18,
                  offset: Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                _item(
                  "홈",
                  "assets/icons/home.svg",
                  "/home",
                  current == "/home",
                  activeColor,
                  inactiveColor,
                ),
                _item(
                  "학습",
                  "assets/icons/study.svg",
                  "/study",
                  current == "/study",
                  activeColor,
                  inactiveColor,
                ),
                _item(
                  "스토어",
                  "assets/icons/store_icon.svg",
                  "/store",
                  current == "/store",
                  activeColor,
                  inactiveColor,
                ),
                _item(
                  "시험",
                  "assets/icons/test.svg",
                  "/testList",
                  current == "/testList",
                  activeColor,
                  inactiveColor,
                ),
                _item(
                  "게임",
                  "assets/icons/game.svg",
                  "/game",
                  current == "/game",
                  activeColor,
                  inactiveColor,
                ),
                _item(
                  "채팅",
                  "assets/icons/friends.svg",
                  "/chat",
                  current == "/chat",
                  activeColor,
                  inactiveColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(
      String label,
      String svg,
      String route,
      bool active,
      Color activeColor,
      Color inactiveColor,
      ) {
    final c = active ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => goNamed(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svg,
              height: 28,
              colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


  Widget _item(
      String label,
      String svg,
      String route,
      bool active,
      Color activeColor,
      Color inactiveColor,
      ) {
    final c = active ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => goNamed(route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              svg,
              height: 28,
              colorFilter: ColorFilter.mode(c, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }


// ─────────────────────────────────────────────────────────────
// 네비게이션 헬퍼
// ─────────────────────────────────────────────────────────────

void goNamed(String routeName, {Object? arguments}) {
  final nav = appNavigatorKey.currentState;
  if (nav == null) return;

  nav.pushNamedAndRemoveUntil(
    routeName,
        (route) => false,
    arguments: arguments,
  );
}
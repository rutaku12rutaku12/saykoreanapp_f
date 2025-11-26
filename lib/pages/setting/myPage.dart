// lib/pages/setting/myPage.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/setting/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/genre.dart';
import 'package:saykoreanapp_f/pages/setting/language.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ✅ 공통 UI (헤더/푸터 패딩 + 테마 상태)
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyPageState();
  }
}

class _MyPageState extends State<MyPage> {
  final dio = Dio();

  // 상태값
  String nickName = "";
  String userDate = "";
  dynamic attendDay;
  dynamic maxStreak;
  bool isLoading = true;

  bool _isDark = false;
  bool _isMint = false;

  bool? isLogin;

  @override
  void initState() {
    super.initState();
    _initThemeFromPrefs();
    loginCheck();
  }

  Future<void> _initThemeFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('themeMode');
    final savedColor = prefs.getString('themeColor');

    setState(() {
      _isDark = (savedMode == 'dark');
      _isMint = (savedColor == 'mint');
    });
  }

  Future<void> _toggleDark(bool value) async {
    setState(() {
      _isDark = value;
      if (value) _isMint = false;
    });

    if (value) {
      await setThemeMode(ThemeMode.dark);
      await setThemeColor('default');
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> _toggleMint(bool value) async {
    setState(() {
      _isMint = value;
      if (value) _isDark = false;
    });

    if (value) {
      await setThemeMode(ThemeMode.light);
      await setThemeColor('mint');
    } else {
      await setThemeColor('default');
    }
  }

  // 로그인 상태 확인
  void loginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null && token.isNotEmpty) {
      setState(() {
        isLogin = true;
      });
      onInfo(token);
      findAttend();
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  // 회원 정보 요청
  void onInfo(token) async {
    try {
      final response = await ApiClient.dio.get(
        "/saykorean/info",
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          nickName = response.data['nickName'] ?? '';
          userDate = response.data['userDate'] ?? '';
          isLoading = false;
        });
      } else if (response.statusCode == 400) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() {
          nickName = "정보 로드 실패";
          userDate = "API 오류";
          isLoading = false;
        });
      }
    } catch (e) {
      print("로그인 확인 오류: $e");
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    }
  }

  // 출석 조회 메소드
  void findAttend() async {
    try {
      final response = await ApiClient.dio.get(
        '/saykorean/attend',
        options: Options(validateStatus: (status) => true),
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> attendList = response.data;
        print("출석 리스트: $attendList");

        int calculatedCurrentStreak = 0;

        if (attendList.isNotEmpty) {
          final dates = attendList
              .map((item) => DateTime.parse(item['attendDay']))
              .toList()
            ..sort((a, b) => b.compareTo(a));

          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          final lastAttendDate = DateTime(
            dates[0].year,
            dates[0].month,
            dates[0].day,
          );

          final daysSinceLastAttend =
              todayDate.difference(lastAttendDate).inDays;

          if (daysSinceLastAttend <= 1) {
            calculatedCurrentStreak = 1;

            for (int i = 1; i < dates.length; i++) {
              final currentDate =
              DateTime(dates[i].year, dates[i].month, dates[i].day);
              final prevDate = DateTime(
                dates[i - 1].year,
                dates[i - 1].month,
                dates[i - 1].day,
              );

              final diffDays = prevDate.difference(currentDate).inDays;

              if (diffDays == 1) {
                calculatedCurrentStreak += 1;
              } else {
                break;
              }
            }
          } else {
            calculatedCurrentStreak = 0;
          }
        }

        setState(() {
          attendDay = attendList.length;
          maxStreak = calculatedCurrentStreak;
        });

        print("현재 연속 출석일수: $calculatedCurrentStreak");
      }
    } catch (e) {
      print("출석 조회 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    if (isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(
          child: CircularProgressIndicator(
            color: scheme.primary,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "마이페이지",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      body: SafeArea(
        // 🔥 FooterSafeArea 로 전체 스크롤 영역 감싸서 푸터랑 겹치지 않게
        child: FooterSafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SKPageHeader(
                  title: "내 계정",
                  subtitle: "프로필과 학습 환경을 한 곳에서 관리해요.",
                ),
                const SizedBox(height: 20),

                // 사용자 정보 카드
                _buildUserCard(theme, scheme),

                const SizedBox(height: 24),

                // 계정 설정
                const _SectionTitle("계정 설정"),
                const SizedBox(height: 8),
                _SettingCard(
                  icon: Icons.person_outline,
                  title: "정보 수정",
                  subtitle: "닉네임, 전화번호, 비밀번호 등을 변경할 수 있어요.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyInfoUpdatePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 학습 설정
                const _SectionTitle("학습 설정"),
                const SizedBox(height: 8),
                _SettingCard(
                  icon: Icons.category_outlined,
                  title: "장르 설정",
                  subtitle: "관심 있는 학습 주제를 선택해요.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const GenrePage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 10),
                _SettingCard(
                  icon: Icons.language_outlined,
                  title: "언어 설정",
                  subtitle: "앱에서 사용할 학습 언어를 바꿔요.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LanguagePage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),

                // 학습 기록
                const _SectionTitle("학습 기록"),
                const SizedBox(height: 8),
                _SettingCard(
                  icon: Icons.emoji_events_outlined,
                  title: "완수한 주제 목록",
                  subtitle: "지금까지 끝낸 학습 주제를 다시 확인해요.",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SuccessListPage(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24), // 🔥 밑에 여유를 좀 더 줘서 푸터와 간격 확보
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------- 위젯 조각들 ------------------- //

  Widget _buildUserCard(ThemeData theme, ColorScheme scheme) {
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint'; // 🔥 민트 모드 확인

    // 기본 카드 배경
    Color cardColor = scheme.surface;
    Color titleColor =
        theme.appBarTheme.foregroundColor ?? const Color(0xFF6B4E42);
    Color labelColor = theme.textTheme.bodySmall?.color ??
        scheme.onSurface.withOpacity(0.7);

    if (isMint && !isDark) {
      // 🔥 민트 모드 : 카드 흰색 + 제목/아이콘 민트
      cardColor = Colors.white;
      titleColor = const Color(0xFF2F7A69);
      labelColor = const Color(0xFF4E8476);
    } else if (isDark) {
      cardColor = scheme.surfaceContainer;
      titleColor = scheme.onSurface;
      labelColor = scheme.onSurface.withOpacity(0.7);
    }

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outline.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 닉네임
            Row(
              children: [
                Icon(Icons.person, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "닉네임",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              nickName.isNotEmpty ? nickName : "정보 없음",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 16),

            // 가입일자
            Row(
              children: [
                Icon(Icons.calendar_today, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "가입일자",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              userDate.isNotEmpty ? userDate : "정보 없음",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 16),

            // 총 출석 일수
            Row(
              children: [
                Icon(Icons.calendar_month, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "총 출석 일수",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              attendDay != null ? "${attendDay}일" : "정보 없음",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),

            const SizedBox(height: 16),

            // 현재 연속 출석 일수
            Row(
              children: [
                Icon(Icons.trending_up, color: titleColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "현재 연속 출석 일수",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              maxStreak != null ? "${maxStreak}일" : "정보 없음",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 작은 컴포넌트들
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint'; // 🔥

    Color color = scheme.onSurface.withOpacity(0.7);
    if (isMint && !isDark) {
      color = const Color(0xFF4E8476);
    }

    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        fontSize: 13,
        color: color,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint'; // 🔥 현재 테마 색상

    // ─────────────────────────────
    // 기본값 (연핑크 테마)
    // ─────────────────────────────
    Color titleColor =
        theme.appBarTheme.foregroundColor ?? const Color(0xFF6B4E42);
    Color subtitleColor =
        theme.textTheme.bodySmall?.color ?? const Color(0xFF9C7C68);
    Color cardColor = Colors.white;
    Color iconBg = const Color(0xFFFFF0EC);      // 💗 연핑크 톤 배경
    Color iconColor = const Color(0xFFEB6A73);   // 💗 살짝 진한 핑크
    Color arrowColor = const Color(0xFFFFAAA5);  // 💗 화살표도 연핑크

    // ─────────────────────────────
    // 민트 테마
    // ─────────────────────────────
    if (isMint && !isDark) {
      cardColor = Colors.white;
      titleColor = const Color(0xFF2F7A69);
      subtitleColor = const Color(0xFF4E8476);
      iconBg = const Color(0xFFE7FFF6);
      iconColor = const Color(0xFF2F7A69);
      arrowColor = const Color(0x802F7A69);
    }
    // ─────────────────────────────
    // 다크 테마
    // ─────────────────────────────
    else if (isDark) {
      cardColor = scheme.surfaceContainer;
      titleColor = scheme.onSurface;
      subtitleColor = scheme.onSurface.withOpacity(0.7);
      iconBg = scheme.secondaryContainer;
      iconColor = scheme.onSecondaryContainer;
      arrowColor = scheme.outline;
    }

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: scheme.outline.withOpacity(0.12),
          ),
        ),
        child: Row(
          children: [
            // 아이콘 네모
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: titleColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: arrowColor,
            ),
          ],
        ),
      ),
    );
  }
}


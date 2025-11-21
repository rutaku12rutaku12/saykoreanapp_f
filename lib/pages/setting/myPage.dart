import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/setting/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/genre.dart';
import 'package:saykoreanapp_f/pages/setting/language.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';
import 'package:shared_preferences/shared_preferences.dart';

// themeModeNotifier, app 전역 정의된 main.dart import
import 'package:saykoreanapp_f/main.dart';

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

  bool _isDark = false; // 다크 모드 스위치
  bool _isMint = false; // 민트 모드 스위치

  bool? isLogin;

  @override
  void initState() {
    super.initState();
    _initThemeFromGlobal();
    loginCheck();
  }

  Future<void> _initThemeFromGlobal() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getString('themeMode'); // light/dark/system
    final savedColor = prefs.getString('themeColor'); // default/mint

    setState(() {
      _isDark = (savedMode == 'dark');
      _isMint = (savedColor == 'mint');
    });
  }

  Future<void> _toggleDark(bool value) async {
    setState(() {
      _isDark = value;
      if (value) {
        _isMint = false; // 다크 켜면 민트 OFF
      }
    });

    if (value) {
      // 다크 모드 ON
      await setThemeMode(ThemeMode.dark); // main.dart 전역 함수
      await setThemeColor('default'); // 다크일 때는 민트 색상 OFF
    } else {
      // 다크 모드 OFF → 라이트 모드
      await setThemeMode(ThemeMode.light);
    }
  }

  Future<void> _toggleMint(bool value) async {
    setState(() {
      _isMint = value;
      if (value) {
        _isDark = false; // 민트 켜면 다크 OFF
      }
    });

    if (value) {
      // 민트 ON → 라이트 + 민트 색상
      await setThemeMode(ThemeMode.light);
      await setThemeColor('mint');
    } else {
      // 민트 OFF → 기본 라이트 색상
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
          MaterialPageRoute(builder: (context) => LoginPage()),
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
            MaterialPageRoute(builder: (context) => LoginPage()),
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
          MaterialPageRoute(builder: (context) => LoginPage()),
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
        List<dynamic> attendList = response.data;
        print("출석 리스트: $attendList");

        int calculatedCurrentStreak = 0;

        if (attendList.isNotEmpty) {
          // 날짜만 추출하고 정렬 (최신순)
          final dates = attendList
              .map((item) => DateTime.parse(item['attendDay']))
              .toList()
            ..sort((a, b) => b.compareTo(a)); // 내림차순 정렬 (최신날짜가 앞에)

          final today = DateTime.now();
          final todayDate = DateTime(today.year, today.month, today.day);

          // 가장 최근 출석일
          final lastAttendDate = DateTime(
              dates[0].year,
              dates[0].month,
              dates[0].day
          );

          // 마지막 출석이 오늘이거나 어제인 경우에만 연속 계산
          final daysSinceLastAttend = todayDate.difference(lastAttendDate).inDays;

          if (daysSinceLastAttend <= 1) {
            calculatedCurrentStreak = 1;

            // 역순으로 현재 연속 출석일 계산
            for (int i = 1; i < dates.length; i++) {
              final currentDate = DateTime(dates[i].year, dates[i].month, dates[i].day);
              final prevDate = DateTime(dates[i - 1].year, dates[i - 1].month, dates[i - 1].day);

              final diffDays = prevDate.difference(currentDate).inDays;

              if (diffDays == 1) {
                calculatedCurrentStreak += 1;
              } else {
                break; // 연속이 끊기면 중단
              }
            }
          } else {
            // 오늘/어제 출석하지 않았으면 연속 0
            calculatedCurrentStreak = 0;
          }
        }

        setState(() {
          attendDay = attendList.length;
          maxStreak = calculatedCurrentStreak; // 현재 연속 출석일수
        });

        print("현재 연속 출석일수: $calculatedCurrentStreak");
      }
    } catch (e) {
      print("출석 조회 오류: $e");
    }
  }



  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFFFF9F0),
        body: Center(
          child: CircularProgressIndicator(
            color: brown,
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
        title: const Text(
          "마이페이지",
          style: TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: brown),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 타이틀
              const Text(
                "내 계정",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "프로필과 학습 환경을 한 곳에서 관리해요.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
              const SizedBox(height: 20),

              // 사용자 정보 카드
              _buildUserCard(),

              const SizedBox(height: 24),

              // 계정 설정
              const _SectionTitle("계정 설정"),
              const SizedBox(height: 8),
              _SettingCard(
                icon: Icons.person_outline,
                title: "정보 수정",
                subtitle: "닉네임, 이메일, 비밀번호 등을 변경할 수 있어요.",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MyInfoUpdatePage(),
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

              // 앱 설정 (다크 모드 + 민트 모드)
              const _SectionTitle("앱 설정"),
              const SizedBox(height: 8),

              // 다크 모드
              _buildDarkToggleCard(brown),

              const SizedBox(height: 10),

              // 민트 모드
              _buildMintToggleCard(),

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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------- 위젯 조각들 ------------------- //
  Widget _buildUserCard() {
    const brown = Color(0xFF6B4E42);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 닉네임
          Row(
            children: const [
              Icon(Icons.person, color: brown, size: 20),
              SizedBox(width: 8),
              Text(
                "닉네임",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            nickName.isNotEmpty ? nickName : "정보 없음",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),

          const SizedBox(height: 16),

          // 가입일자
          Row(
            children: const [
              Icon(Icons.calendar_today, color: brown, size: 20),
              SizedBox(width: 8),
              Text(
                "가입일자",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            userDate.isNotEmpty ? userDate : "정보 없음",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),

          const SizedBox(height: 16),

          // 총 출석 일수
          Row(
            children: const [
              Icon(Icons.calendar_month, color: brown, size: 20),
              SizedBox(width: 8),
              Text(
                "총 출석 일수",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            attendDay != null ? "${attendDay}일" : "정보 없음",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),

          const SizedBox(height: 16),

          // 현재 연속 출석 일수 (아직 null이라 임시)
          Row(
            children: const [
              Icon(Icons.trending_up, color: brown, size: 20),
              SizedBox(width: 8),
              Text(
                "현재 연속 출석 일수",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            maxStreak != null ? "${maxStreak}일" : "정보 없음",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: brown,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDarkToggleCard(Color brown) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isDark ? Icons.dark_mode : Icons.light_mode,
              color: scheme.onSecondaryContainer,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "다크 모드",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "눈에 편한 어두운 테마로 전환해요.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9C7C68),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isDark,
            activeColor: brown,
            onChanged: (value) {
              _toggleDark(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMintToggleCard() {
    final scheme = Theme.of(context).colorScheme;
    const mintDeep = Color(0xFF2F7A69);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // 아이콘 박스
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.palette_rounded,
              color: scheme.onSecondaryContainer,
              size: 22,
            ),
          ),

          const SizedBox(width: 14),

          // 텍스트
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "민트 테마",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: mintDeep,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "시원하고 편안한 민트 컬러 테마.",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6AA89D),
                  ),
                ),
              ],
            ),
          ),

          // 실제 동작하는 스위치
          Switch(
            value: _isMint,
            activeColor: mintDeep,
            onChanged: (value) {
              _toggleMint(value);
            },
          ),
        ],
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
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        color: Color(0xFF9C7C68),
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
    const brown = Color(0xFF6B4E42);
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.brown.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // 아이콘 네모
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: scheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: scheme.onSecondaryContainer,
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
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: brown,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9C7C68),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFB89C8A),
            ),
          ],
        ),
      ),
    );
  }
}

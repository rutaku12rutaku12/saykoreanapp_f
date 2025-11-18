import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/genre.dart';
import 'package:saykoreanapp_f/pages/setting/language.dart';
import 'package:saykoreanapp_f/pages/study/successList.dart';
import 'package:shared_preferences/shared_preferences.dart';

// themeModeNotifier 가 정의된 파일 import (예: main.dart)
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

  // 1. 상태변수
  String nickName = "";
  String userDate = "";
  bool isLoading = true;

  bool _isDark = false; // 다크 모드 여부

  // 2. 해당 페이지 열렸을때 실행되는 함수
  @override
  void initState() {
    super.initState();
    _initThemeFromGlobal();
    loginCheck();
  }

  void _initThemeFromGlobal() {
    final mode = themeModeNotifier.value;
    setState(() {
      _isDark = (mode == ThemeMode.dark);
    });
  }

  Future<void> _toggleTheme(bool value) async {
    setState(() {
      _isDark = value;
    });

    // 전역 테마 변경 → 전체 앱 테마 변경
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;

    // (옵션) SharedPreferences에 저장해서 앱 재실행 후에도 유지하고 싶으면:
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('themeMode', value ? 'dark' : 'light');
  }

  // 3. 로그인 상태를 확인하는 함수
  bool? isLogin; // Dart 문법 중에 타입? 은 null 포함할 수 있다는 뜻
  void loginCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token != null && token.isNotEmpty) {
      setState(() {
        isLogin = true;
        print("로그인 중");
        onInfo(token);
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  // 4. 로그인된 (회원) 정보 요청, 로그인 중일때 실행
  void onInfo(token) async {
    try {
      final response = await ApiClient.dio.get(
        "/saykorean/info",
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      print("응답 상태: ${response.statusCode}");
      print("응답 데이터: ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        setState(() {
          nickName = response.data['nickName'] ?? '';
          userDate = response.data['userDate'] ?? '';
          isLoading = false;
        });
      } else if (response.statusCode == 400) {
        print("인증 실패 - 로그인 페이지로 이동");
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      } else {
        print("기타 오류 : ${response.statusCode}");
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

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);
    final bg = Theme.of(context).scaffoldBackgroundColor;

    // 로딩 중일 때
    if (isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(
          child: CircularProgressIndicator(
            // 색은 고정 브라운 유지
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
              // 상단 인사/타이틀 영역
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

              // 사용자 정보 표시 카드
              Container(
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 1. 계정 설정 카드
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

              // 2. 학습 설정 카드들
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

              // 앱 설정 - 다크 모드
              const _SectionTitle("앱 설정"),
              const SizedBox(height: 8),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        color: const Color(0xFFFFE5CF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isDark ? Icons.dark_mode : Icons.light_mode,
                        color: brown,
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
                              color: brown,
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
                      onChanged: _toggleTheme,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. 학습 기록 / 완수 목록
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
}

// ─────────────────────────────────────────────
// 작은 컴포넌트들
// ─────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return const Text(
      "",
    );
  }
}

class _SettingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);

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
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE5CF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: brown, size: 22),
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
            )
          ],
        ),
      ),
    );
  }
}

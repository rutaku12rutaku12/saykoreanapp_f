// lib/pages/home/home_page.dart
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? myUserNo;
  bool isLogin = false;

  // 이미지 파일 (StartPage와 동일)
  static const _bgWave = 'assets/img/bgImg.png';
  static const _mascot = 'assets/img/mascot_pair.png';

  @override
  void initState() {
    super.initState();
    loadUserInfo(); //
  }

  void loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final no = prefs.getInt('myUserNo');
    final token = prefs.getString('token');


    print("HomePage에서 가져온 userNo = $no");

    setState(() {
      myUserNo = no;
      isLogin = token != null && token.isNotEmpty;
    });
  }

  void LogOut() async {
    try {
      final response = await ApiClient.dio.get(
        '/saykorean/logout',
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('myUserNo');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    // 로딩 중일 때
    if (myUserNo == null) {
      return Scaffold(
        backgroundColor: bg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // ⭐ StartPage와 동일한 UI 구조
    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── 상단 물결 배경 (PNG)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: Image.asset(
              _bgWave,
              fit: BoxFit.cover,
            ),
          ),

          // 커스텀 페인터 물결
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: CustomPaint(painter: _WavePainter()),
          ),

          // 하단 물결
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.18,
            child: CustomPaint(painter: _BottomPinkWavePainter()),
          ),

          // ── 메인 컨텐츠 영역
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 타이틀: "재밌는 한국어"
                    _TitleFancy(),

                    const SizedBox(height: 16),

                    // 마스코트
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: Image.asset(
                        _mascot,
                        fit: BoxFit.contain,
                      ),
                    ),



                    const SizedBox(height: 32),

                    // ⭐ 로그아웃 버튼 (StartPage 버튼 스타일 그대로)
                    if (isLogin)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFEEE9),
                            foregroundColor: const Color(0xFF6B4E42),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onPressed: () async {
                            // 확인 다이얼로그
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('로그아웃'),
                                content: Text('정말 로그아웃 하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('로그아웃'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              LogOut();
                            }
                          },
                          child: Text('로그아웃'),
                        ),
                      ),

                    const SizedBox(height: 10),

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ⭐⭐⭐ StartPage에서 복사한 위젯들 (여기부터 필수!)
// ─────────────────────────────────────────────────────────────────────────────

// 상단 타이틀 "재밌는 한국어" 꾸밈
class _TitleFancy extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const cGreen = Color(0xFFA8E6CF); // 민트-블루
    const cPink = Color(0xFFFFAAA5); // 코랄-핑크
    const cBrown = Color(0xFF6B4E42); // 갈색 텍스트

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        children: [
          _shadowSpan('재', cGreen),
          _shadowSpan('밌', cPink),
          _shadowSpan('는 ', cBrown),
          const TextSpan(
            text: '한국어',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: cBrown,
              height: 1.2,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  static TextSpan _shadowSpan(String t, Color color) {
    return TextSpan(
      text: t,
      style: TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        color: color,
        height: 1.2,
        letterSpacing: 0.5,
        shadows: const [
          Shadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

// (옵션) 커스텀 물결 — 상단 PNG가 없을 때만 사용
class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final top = const Color(0xFFA8E6CF); // 민트
    final mid = const Color(0xFFA8E6CF);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, mid],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height * 0.65)
      ..quadraticBezierTo(size.width * 0.25, size.height * 0.50,
          size.width * 0.5, size.height * 0.58)
      ..quadraticBezierTo(size.width * 0.8, size.height * 0.66,
          size.width, size.height * 0.45)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BottomPinkWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const c1 = Color(0x80FFAAA5); // 옅은 핑크
    const c2 = Color(0x80FFAAA5); // 더 연한 핑크
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c1, c2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(size.width * 0.20, size.height * 0.05,
          size.width * 0.45, size.height * 0.18)
      ..quadraticBezierTo(size.width * 0.75, size.height * 0.34,
          size.width, size.height * 0.10)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
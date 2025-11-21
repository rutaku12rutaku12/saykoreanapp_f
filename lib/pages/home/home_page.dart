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
    loadUserInfo();
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

  // 로그아웃 메소드
  void LogOut() async {
    try {
      final response = await ApiClient.dio.get(
        '/saykorean/logout',
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print('logout response = ${response.statusCode}');

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
    final size   = MediaQuery.of(context).size;
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg     = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    // 로딩 중일 때
    if (myUserNo == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold( //
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── 상단 물결
          // 라이트 모드: 아무것도 안 그림 (물결 제거)
          // 다크 모드: 기존처럼 커스텀 웨이브 유지
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: isDark
                ? CustomPaint(painter: _WavePainterDark(scheme))
                : const SizedBox.shrink(),
          ),

          // ── 하단 물결
          // 라이트 모드: 물결 제거
          // 다크 모드: 기존 커스텀 웨이브 유지
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.18,
            child: isDark
                ? CustomPaint(painter: _BottomWaveDark(scheme))
                : const SizedBox.shrink(),
          ),

          // ── 메인 컨텐츠 영역
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _TitleFancy(),
                    const SizedBox(height: 16),
                    AspectRatio(
                      aspectRatio: 1.6,
                      child: Image.asset(
                        _mascot,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),

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
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('로그아웃'),
                                content:
                                const Text('정말 로그아웃 하시겠습니까?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('취소'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text('로그아웃'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              LogOut();
                            }
                          },
                          child: const Text('로그아웃'),
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
// 타이틀 "재밌는 한국어"
// ─────────────────────────────────────────────────────────────────────────────

class _TitleFancy extends StatelessWidget {
  const _TitleFancy();

  @override
  Widget build(BuildContext context) {
    const cGreen = Color(0xFFA8E6CF); // 민트-블루
    const cPink  = Color(0xFFFFAAA5); // 코랄-핑크
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

// ─────────────────────────────────────────────────────────────────────────────
// 물결 Painter들 (라이트/다크 분리)
// ─────────────────────────────────────────────────────────────────────────────

// 라이트 모드 하단 핑크 웨이브
class _BottomWaveLight extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const c1 = Color(0x80FFAAA5);
    const c2 = Color(0x80FFAAA5);
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c1, c2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.25)
      ..quadraticBezierTo(
        size.width * 0.20,
        size.height * 0.05,
        size.width * 0.45,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.34,
        size.width,
        size.height * 0.10,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 다크 모드 상단 웨이브
class _WavePainterDark extends CustomPainter {
  final ColorScheme scheme;
  _WavePainterDark(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final top = scheme.primaryContainer.withOpacity(0.85);
    final mid = scheme.surface;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, mid],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..lineTo(0, size.height * 0.75)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.55,
        size.width * 0.5,
        size.height * 0.65,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.75,
        size.width,
        size.height * 0.55,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 다크 모드 하단 웨이브
class _BottomWaveDark extends CustomPainter {
  final ColorScheme scheme;
  _BottomWaveDark(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final c1 = scheme.secondaryContainer.withOpacity(0.9);
    final c2 = scheme.surface;

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [c1, c2],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.15)
      ..quadraticBezierTo(
        size.width * 0.20,
        0,
        size.width * 0.45,
        size.height * 0.18,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.36,
        size.width,
        size.height * 0.12,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

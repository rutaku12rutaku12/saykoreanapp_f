// start_page.dart — 라이트/다크 물결 분기 버전
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() =>
    _StartPageState();
}

class _StartPageState extends State<StartPage>{
    @override
  void initState() {
    super.initState();
    _checkLogin();
  }
  // 로그인 확인 메소드, Hot Restart 시작 시 토큰이 존재하면 homepage로 이동ㅕㄴ
  Future<void> _checkLogin() async{
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if( token != null && token.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      }
  }

  // 이미지 파일
  static const _bgWave = 'assets/img/bgImg.png';      // 라이트 전용
  static const _mascot = 'assets/img/mascot_pair.png';

  @override
  Widget build(BuildContext context) {
    final size   = MediaQuery.of(context).size;
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg     = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── 상단 물결
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: isDark
            // 🌙 다크 모드: 진한 톤 파도
                ? CustomPaint(painter: _WavePainterDark(scheme))
            // ☀️ 라이트 모드: 기존 파스텔 PNG (또는 커스텀)
                : Image.asset(_bgWave, fit: BoxFit.cover),
          ),

          // ── 하단 물결
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.18,
            child: isDark
                ? CustomPaint(painter: _BottomWaveDark(scheme))
                : CustomPaint(painter: _BottomWaveLight()),
          ),

          // ── 메인 콘텐츠
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
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: _PrimaryButton(
                            label: '로그인',
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/login'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GhostButton(
                            label: '회원가입',
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/signup'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '계정이 없으신가요? 회원가입을 눌러 시작해 보세요.',
                      style: TextStyle(
                        color: Color(0x995C4A42),
                        fontSize: 12.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
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

// ───────────────── 타이틀 ─────────────────

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
        // 🔥 여기 const 빼기!!
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
      style: const TextStyle(
        fontSize: 40,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: 0.5,
        shadows: [
          Shadow(
            color: Color(0x22000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ).copyWith(color: color),
    );
  }
}


// ───────────────── 버튼들 ─────────────────

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PrimaryButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFEEE9),
          foregroundColor: const Color(0xFF6B4E42),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

// 테두리만 있는 라운드 버튼 (회원가입)
class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _GhostButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE5D5CC), width: 1.2),
          foregroundColor: const Color(0xFF6B4E42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

// ───────────────── 물결 Painter들 ─────────────────

// 라이트 모드 하단 핑크 웨이브 (기존)
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
          size.width * 0.20, size.height * 0.05, size.width * 0.45, size.height * 0.18)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.34, size.width, size.height * 0.10)
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
    // 다크에 어울리는 깊은 민트/브라운 계열
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
          size.width * 0.25, size.height * 0.55, size.width * 0.5, size.height * 0.65)
      ..quadraticBezierTo(
          size.width * 0.8, size.height * 0.75, size.width, size.height * 0.55)
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
          size.width * 0.20, 0, size.width * 0.45, size.height * 0.18)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.36, size.width, size.height * 0.12)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

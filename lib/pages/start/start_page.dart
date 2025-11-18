// start_page.dart — 테마 대응 버전
import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  // 이미지 파일
  static const _bgWave = 'assets/img/bgImg.png';
  static const _mascot = 'assets/img/mascot_pair.png';

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor; // 테마에서 배경 가져오기

    return Scaffold(
      backgroundColor: bg, // 고정색 → 테마 기반 색
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

          // 대안: 커스텀 페인터 물결 (PNG 없을 때 사용하고 싶으면 이 부분만 남기면 됨)
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

          // ── 메인 카드 영역
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 타이틀: "재밌는 한국어"
                  _TitleFancy(),

                  const SizedBox(height: 16),

                  // 마스코트
                  AspectRatio(
                    aspectRatio: 1.6, // 이미지 비율
                    child: Image.asset(
                      _mascot,
                      fit: BoxFit.contain,
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 로그인 / 회원가입 버튼
                  Row(
                    children: [
                      Expanded(
                        child: _PrimaryButton(
                          label: '로그인',
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/login'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GhostButton(
                          label: '회원가입',
                          onPressed: () => Navigator.pushReplacementNamed(
                              context, '/signup'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // 안내문
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
        ],
      ),
    );
  }
}

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

// 꽉 찬 라운드 버튼 (로그인)
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
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
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
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

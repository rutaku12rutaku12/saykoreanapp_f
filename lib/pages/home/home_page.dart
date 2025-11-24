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
    final size       = MediaQuery.of(context).size;
    final theme      = Theme.of(context);
    final scheme     = theme.colorScheme;
    final bg         = theme.scaffoldBackgroundColor;
    final isDark     = theme.brightness == Brightness.dark;
    final topPadding = MediaQuery.of(context).padding.top;

    // 민트 테마 여부 (mintTheme에서 설정한 배경색으로 판별)
    final bool isMintTheme =
        bg.value == const Color(0xFFE7FFF6).value;

    // 로딩 중일 때
    if (myUserNo == null) {
      return Scaffold(
        backgroundColor: bg,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // ── 모드별 로그아웃 버튼 색상
    final Color logoutBg;
    final Color logoutFg;

    if (isDark) {
      logoutBg = scheme.surfaceContainerHigh;
      logoutFg = scheme.onSurface;
    } else if (isMintTheme) {
      logoutBg = const Color(0xFFD3F8EA); // 연민트
      logoutFg = const Color(0xFF2F7A69); // 진한 민트
    } else {
      logoutBg = const Color(0xFFFFEEE9); // 연핑크
      logoutFg = const Color(0xFF6B4E42); // 갈색
    }

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // ── 상단 웨이브
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.22,
            child: isDark
                ? CustomPaint(painter: _TopWaveDark(scheme))
                : (isMintTheme
                ? const CustomPaint(painter: _TopWaveMint())
                : const CustomPaint(painter: _TopWavePink())),
          ),

          // ── 하단 웨이브
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: size.height * 0.18,
            child: isDark
                ? CustomPaint(painter: _BottomWaveDark(scheme))
                : (isMintTheme
                ? const CustomPaint(painter: _BottomWaveMint())
                : const CustomPaint(painter: _BottomWavePink())),
          ),

          // ── 상단 아이콘들
//   - 왼쪽 끝 : 내정보
//   - 오른쪽 끝 : 스토어 + 순위
          Positioned(
            top: topPadding + 8,
            right: 16,
            child: Row(
              children: [
                // 오른쪽: 스토어 + 순위
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HomeTopIconButton(
                      icon: Icons.storefront_outlined,
                      label: '스토어',
                      onTap: () {
                        Navigator.pushNamed(context, '/store');
                      },
                    ),
                    const SizedBox(width: 8),
                    _HomeTopIconButton(
                      icon: Icons.emoji_events_outlined,
                      label: '순위',
                      onTap: () {
                        Navigator.pushNamed(context, '/ranking');
                      },
                    ),
                    const SizedBox(width: 8),
                    _HomeTopIconButton(
                      icon: Icons.person_outline,
                      label: '내정보',
                      onTap: () {
                        Navigator.pushNamed(context, '/info');
                      },
                    ),

                  ],
                ),
              ],
            ),
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
                            backgroundColor: logoutBg,
                            foregroundColor: logoutFg,
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

// ─────────────────────────────────────────────────────────────
// 타이틀 "재밌는 한국어"
// ─────────────────────────────────────────────────────────────

class _TitleFancy extends StatelessWidget {
  const _TitleFancy();

  @override
  Widget build(BuildContext context) {
    const cGreen = Color(0xFFA8E6CF); // 민트-블루
    const cPink  = Color(0xFFFFAAA5); // 코랄-핑크
    const cBrown = Color(0xFF6B4E42); // 갈색 텍스트

    return RichText(
      textAlign: TextAlign.center,
      text: const TextSpan(
        children: [
          TextSpan(
            text: '재',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: cGreen,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          TextSpan(
            text: '밌',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: cPink,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          TextSpan(
            text: '는 ',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: cBrown,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          TextSpan(
            text: '한국어',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w800,
              color: cBrown,
              height: 1.2,
              letterSpacing: 0.5,
              shadows: [
                Shadow(
                  color: Color(0x22000000),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 상단 웨이브 (라이트: 단색 핑크 / 민트: 단색 진한 민트 / 다크: 단색 다크)
// ─────────────────────────────────────────────────────────────

class _TopWavePink extends CustomPainter {
  const _TopWavePink();

  @override
  void paint(Canvas canvas, Size size) {
    const c = Color(0xFFFFE0DC); // 살짝 진한 핑크

    final paint = Paint()..color = c;

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

class _TopWaveMint extends CustomPainter {
  const _TopWaveMint();

  @override
  void paint(Canvas canvas, Size size) {
    const c = Color(0xFFA8E6CF); // 진한 민트

    final paint = Paint()..color = c;

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

class _TopWaveDark extends CustomPainter {
  final ColorScheme scheme;
  _TopWaveDark(this.scheme);

  @override
  void paint(Canvas canvas, Size size) {
    final c = scheme.primaryContainer.withOpacity(0.9);

    final paint = Paint()..color = c;

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

// ─────────────────────────────────────────────────────────────
// 하단 웨이브 (라이트: 핑크 / 민트: 진한 민트 / 다크: 기존)
// ─────────────────────────────────────────────────────────────

class _BottomWavePink extends CustomPainter {
  const _BottomWavePink();

  @override
  void paint(Canvas canvas, Size size) {
    const c1 = Color(0x80FFAAA5); // 반투명 핑크
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

class _BottomWaveMint extends CustomPainter {
  const _BottomWaveMint();

  @override
  void paint(Canvas canvas, Size size) {
    const c1 = Color(0xFFA8E6CF); // 진한 민트
    const c2 = Color(0xFFA8DCC4); // 살짝 다른 톤의 민트

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

// ─────────────────────────────────────────────────────────────
// 홈 화면 상단 오른쪽 아이콘 버튼 위젯
// ─────────────────────────────────────────────────────────────
class _HomeTopIconButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeTopIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme      = Theme.of(context);
    final isDark     = theme.brightness == Brightness.dark;
    final bg         = theme.scaffoldBackgroundColor;
    final bool isMintTheme =
        bg.value == const Color(0xFFE7FFF6).value;

    late final Color bgColor;
    late final Color iconColor;
    late final Color labelColor;

    if (isDark) {
      bgColor    = theme.colorScheme.surfaceContainerHigh;
      iconColor  = theme.colorScheme.onSurface;
      labelColor = theme.colorScheme.onSurface.withOpacity(0.85);
    } else if (isMintTheme) {
      bgColor    = const Color(0xFFD3F8EA); // 연민트
      iconColor  = const Color(0xFF2F7A69); // 진한 민트
      labelColor = const Color(0xFF2F7A69);
    } else {
      bgColor    = const Color(0xFFFFF3E8); // 크림
      iconColor  = const Color(0xFF6B4E42); // 갈색
      labelColor = const Color(0xFF6B4E42);
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

// lib/pages/test/loading.dart

import 'dart:math';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ FooterSafeArea 사용
import 'package:easy_localization/easy_localization.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

// ──────────────────────────────────────────────
// 로딩 슬라이드 데이터 모델
// ──────────────────────────────────────────────
class _LoadingSlide {
  final String asset;
  final String title;
  final String description;

  const _LoadingSlide({
    required this.asset,
    required this.title,
    required this.description,
  });
}

class _LoadingPageState extends State<LoadingPage> {
  bool _started = false;
  String _message = "loading.grading".tr();

  late final _LoadingSlide _slide;   // 랜덤으로 선택된 이미지+텍스트
  late final String _phrase;         // 하단 문구

  @override
  void initState() {
    super.initState();

    // ── 슬라이드 후보들
    final slides = <_LoadingSlide>[
      _LoadingSlide(
        asset: 'assets/loading/1_loading_img.png',
        title: "loading.sungrye".tr(),
        description: "loading.sungryeInfo".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/2_loading_img.png',
        title: "loading.bookchon".tr(),
        description: "loading.bookchonInfo".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/3_loading_img.png',
        title: "loading.guckjungback".tr(),
        description: "loading.guckjungbackInfo".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/4_loading_img.png',
        title: "loading.muryung".tr(),
        description: "loading.muryungInfo".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/5_loading_img.png',
        title: '???',
        description: "loading.slide5.desc".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/6_loading_img.png',
        title: "loading.gwanghan".tr(),
        description: "loading.gwanghanInfo".tr(),
      ),
      _LoadingSlide(
        asset: 'assets/loading/7_loading_img.png',
        title: "loading.hanra".tr(),
        description: "loading.hanraInfo".tr(),
      ),
    ];

    // 하단에 띄울 문구들
    final phrases = <String>[
      "loading.phrase1".tr(),
      "loading.phrase".tr(),
      "loading.phrase3".tr(),
    ];

    final rng = Random();
    _slide = slides[rng.nextInt(slides.length)];
    _phrase = phrases[rng.nextInt(phrases.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 빌드될 때 중복 호출 방지
    if (_started) return;
    _started = true;
    _startGrading();
  }

  Future<void> _startGrading() async {
    // 1) 라우트 인자 꺼내기
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is! Map) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': "error.argsFormat".tr(),
        });
      }
      return;
    }

    final args = rawArgs as Map;
    final action = args['action'];
    final payload = args['payload'];

    if (action != 'submitAnswer' || payload is! Map) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': "error.actionPayload".tr(),
        });
      }
      return;
    }

    final p = payload as Map;

    // TestPage에서 넘겨준 값들
    final String? url = p['url'] as String?;
    final dynamic body = p['body'];

    if (url == null || url.isEmpty) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': "error.emptyUrl".tr(),
        });
      }
      return;
    }

    try {
      // 2) 실제 채점 요청
      setState(() => _message = "loading.grading".tr());

      final res = await ApiClient.dio.post(url, data: body);

      if (!mounted) return;

      // 3) 성공 시 TestPage로 결과 반환
      Navigator.pop(context, {
        'ok': true,
        'data': res.data,
        'statusCode': res.statusCode,
      });
    } on DioException catch (e) {
      print('LoadingPage DioException: '
          'type=${e.type}, status=${e.response?.statusCode}, data=${e.response?.data}');
      if (!mounted) return;
      Navigator.pop(context, {
        'ok': false,
        'error': e.message ?? e.toString(),
        'statusCode': e.response?.statusCode,
      });
    } catch (e) {
      print('LoadingPage unknown error: $e');
      if (!mounted) return;
      Navigator.pop(context, {
        'ok': false,
        'error': e.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: FooterSafeArea( // ✅ 푸터에 안 가리도록 공통 래퍼
        child: SafeArea(
          top: true,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;

              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── 상단 타이틀
                          Text(
                            _slide.title,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? scheme.onSurface
                                  : const Color(0xFF6B4E42),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // ── 중앙 카드 (화면 폭 기준으로 크게)
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: 420,
                              // 폭은 화면의 85%
                              minWidth: maxWidth * 0.85,
                            ),
                            child: AspectRatio(
                              aspectRatio: 3 / 4, // 세로로 좀 더 긴 카드
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x22000000),
                                      blurRadius: 12,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: AssetImage(_slide.asset),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.45),
                                      borderRadius: const BorderRadius.vertical(
                                        bottom: Radius.circular(24),
                                      ),
                                    ),
                                    child: Text(
                                      _slide.description,
                                      textAlign: TextAlign.left,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── 하단 로딩 인디케이터 + 문구
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _phrase, // 랜덤 문구
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? scheme.onSurface.withOpacity(0.9)
                                  : const Color(0xFF6B4E42),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

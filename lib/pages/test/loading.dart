// lib/pages/test/loading.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ FooterSafeArea 사용

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
  String _message = '채점 중입니다...';

  late final _LoadingSlide _slide;   // 랜덤으로 선택된 이미지+텍스트
  late final String _phrase;         // 하단 문구

  @override
  void initState() {
    super.initState();

    // ── 슬라이드 후보들
    const slides = <_LoadingSlide>[
      _LoadingSlide(
        asset: 'assets/loading/1_loading_img.png',
        title: '숭례문',
        description: '서울을 대표하는 국보 제1호 숭례문은 '
            '조선시대 한양 도성의 남쪽 문으로, '
            '지금은 도심 속 유서 깊은 랜드마크가 되었어요.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/2_loading_img.png',
        title: '북촌 한옥마을',
        description: '고즈넉한 한옥과 골목길이 이어진 북촌은 '
            '전통과 현대가 공존하는 서울의 대표적인 관광지예요.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/3_loading_img.png',
        title: '국립중앙박물관',
        description: '한국의 역사와 문화를 한자리에서 만날 수 있는 곳, '
            '다양한 전시와 체험 프로그램도 즐겨 보세요.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/4_loading_img.png',
        title: '무령왕릉',
        description: '백제 무령왕과 왕비의 무덤으로, '
            '수많은 유물이 발견된 중요한 역사 유적지입니다.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/5_loading_img.png',
        title: '???',
        description: '5번 이미지 설명을 여기에 적어 주세요.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/6_loading_img.png',
        title: '광한루원',
        description: '춘향전의 무대가 된 남원의 광한루원은 '
            '기와와 연못, 정원이 어우러진 고즈넉한 누각이에요.',
      ),
      _LoadingSlide(
        asset: 'assets/loading/7_loading_img.png',
        title: '한라산',
        description: '제주도의 상징 한라산은 사계절마다 다른 풍경으로 '
            '등산객들을 반겨주는 우리나라 최고의 명산 중 하나입니다.',
      ),
    ];

    // 하단에 띄울 문구들
    const phrases = <String>[
      '채점 중입니다... 잠시만 기다려 주세요.',
      '답안을 분석하는 중이에요. 곧 결과가 나와요!',
      '조금만 더 기다리면 결과를 확인할 수 있어요.',
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
          'error': '잘못된 접근입니다. (arguments 형식 오류)',
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
          'error': '잘못된 접근입니다. (action/payload 오류)',
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
          'error': '요청 URL이 비어있습니다.',
        });
      }
      return;
    }

    try {
      // 2) 실제 채점 요청
      setState(() => _message = '채점 중입니다...');

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

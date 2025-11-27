// lib/pages/test/test_result_page.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ FooterSafeArea
import 'package:easy_localization/easy_localization.dart';

class TestResultPage extends StatelessWidget {
  const TestResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
    ModalRoute.of(context)!.settings.arguments as Map<dynamic, dynamic>?;

    // ─────────────────────────────────────────────
    // 1) 기본값 세팅 + 여러 형태 지원
    // ─────────────────────────────────────────────
    final int testNo = args?['testNo'] as int? ?? 0;

    final dynamic rawResult = args?['result'];
    final Map resultMap =
    (rawResult is Map) ? rawResult as Map : const <String, dynamic>{};

    int total = 0;
    int correct = 0;

    if (args?['total'] is int) total = args!['total'] as int;
    if (args?['correct'] is int) correct = args!['correct'] as int;

    if (total == 0) {
      if (resultMap['total'] is int) {
        total = resultMap['total'] as int;
      } else if (resultMap['totalQuestions'] is int) {
        total = resultMap['totalQuestions'] as int;
      }
    }

    if (correct == 0) {
      if (resultMap['correct'] is int) {
        correct = resultMap['correct'] as int;
      } else if (resultMap['correctAnswers'] is int) {
        correct = resultMap['correctAnswers'] as int;
      }
    }

    if (total == 0 && resultMap['score'] is int) {
      total = 1;
      correct = ((resultMap['isCorrect'] ?? 0) == 1) ? 1 : 0;
    }

    final double percent =
    (total > 0) ? (correct / total * 100).clamp(0, 100) : 0;

    // ─────────────────────────────────────────────
    // 테마 색 가져오기 + 민트 / 다크 분기
    // ─────────────────────────────────────────────
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bgColor = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    // 기본(살구) 기반 컬러
    final rawPrimary = scheme.primary;
    final rawAccent = scheme.secondary;
    final rawSurface = scheme.surface;
    final rawChipBg = scheme.secondaryContainer.withOpacity(0.4);
    final rawBarBg = isDark
        ? scheme.surfaceVariant.withOpacity(0.35)
        : scheme.surfaceVariant.withOpacity(0.4);

    // 민트 테마 판별 (홈/다른 페이지와 동일 로직)
    final bool isMintTheme =
        !isDark && bgColor.value == const Color(0xFFE7FFF6).value;

    // 민트/기본에 따라 실제 사용할 색
    final Color primary =
    isMintTheme ? const Color(0xFF2F7A69) : rawPrimary; // 텍스트 포인트
    final Color accent =
    isMintTheme ? const Color(0xFF2F7A69) : rawAccent; // 메달/버튼 그라데이션
    final Color cardBg =
    isMintTheme ? const Color(0xFFF4FFFA) : rawSurface; // 결과 카드 배경
    final Color chipBg =
    isMintTheme ? const Color(0xFFD3F8EA) : rawChipBg; // "시험 번호" 칩
    final Color barBg =
    isMintTheme ? const Color(0xFFD3F8EA) : rawBarBg; // 정답률 박스 배경
    final Color statChipBg = isMintTheme
        ? const Color(0xFFF4FFFA)
        : theme.colorScheme.surface.withOpacity(0.9); // 총 문항/맞힌 개수 칩 배경

    final subtleTextColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ??
            Colors.grey.shade600;

    String getMessage() {
      if (percent >= 90) return "test.result.perfect".tr();
      if (percent >= 70) return "feedback.great".tr();
      if (percent >= 40) return "feedback.practiceMore".tr();
      return "feedback.tryAgain".tr();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "test.result.title".tr(),
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      body: FooterSafeArea(
        child: SafeArea(
          top: false,
          bottom: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 480,
                    minHeight: constraints.maxHeight,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                    child: Column(
                      children: [
                        // ── 상단 영역
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // 시험 번호 칩
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                decoration: BoxDecoration(
                                  color: chipBg,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'test.number'.tr(namedArgs: {
                                    'no': testNo.toString(),
                                  }),
                                  style: TextStyle(
                                    color: primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 28),

                              // ── 메인 카드 (새싹 포함)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(
                                    20, 28, 20, 24),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: theme.dividerColor
                                        .withOpacity(0.25),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.black.withOpacity(0.45)
                                          : Colors.black.withOpacity(0.08),
                                      blurRadius: 22,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // 카드 안쪽 상단 새싹 메달
                                    Container(
                                      width: 78,
                                      height: 78,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: LinearGradient(
                                          colors: [
                                            accent.withOpacity(0.3),
                                            accent.withOpacity(0.9),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(0.35),
                                            blurRadius: 16,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          percent >= 90
                                              ? '🏅'
                                              : (percent >= 70
                                              ? '🎉'
                                              : (percent >= 40
                                              ? '📚'
                                              : '🌱')),
                                          style: const TextStyle(
                                            fontSize: 34,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 18),

                                    // 상단 멘트
                                    Text(
                                      getMessage(),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: primary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'test.summary'.tr(namedArgs: {
                                        'total': total.toString(),
                                        'correct': correct.toString(),
                                      }),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: subtleTextColor,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // 정답률/통계 박스
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                      decoration: BoxDecoration(
                                        borderRadius:
                                        BorderRadius.circular(18),
                                        color: barBg,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.center,
                                        children: [
                                          // 정답률 텍스트
                                          Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "ranking.th.accuracy".tr(),
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: subtleTextColor,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${percent.toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w900,
                                                  color: primary,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 24),
                                          // 총 문항 / 맞힌 개수 칩
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment.end,
                                              children: [
                                                _StatChip(
                                                  label: "ranking.th.total".tr(),
                                                  value: '$total',
                                                  color: primary,
                                                  bgColor: statChipBg,
                                                ),
                                                const SizedBox(width: 8),
                                                _StatChip(
                                                  label: "test.correctCount".tr(),
                                                  value: '$correct',
                                                  color: primary,
                                                  bgColor: statChipBg,
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── 하단 버튼 영역
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  // 현재 시험 화면으로 돌아가기
                                  Navigator.pop(context);
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  side: BorderSide(color: primary),
                                  foregroundColor: primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '다시 풀기',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    "/testList",
                                        (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  backgroundColor: accent.withOpacity(0.95),
                                  foregroundColor:
                                  theme.colorScheme.onSecondary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  '시험 목록으로',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

// ─────────────────────────────────────────────
// 귀여운 칩 스타일의 통계 아이템
// ─────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtle = theme.textTheme.bodySmall?.color?.withOpacity(0.8) ??
        Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.45),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: subtle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

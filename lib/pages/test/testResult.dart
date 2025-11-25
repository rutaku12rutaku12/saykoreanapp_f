// lib/pages/test/test_result_page.dart

import 'package:flutter/material.dart';

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
    // 여기부터 테마 색 가져오기
    // ─────────────────────────────────────────────
    final theme = Theme.of(context);
    final bgColor = theme.scaffoldBackgroundColor;
    final primary = theme.colorScheme.primary; // 민트/브라운 등 테마에 따라 바뀜
    final surface = theme.colorScheme.surface; // 카드 배경
    final chipBg = theme.colorScheme.secondaryContainer.withOpacity(0.4);
    final accent = theme.colorScheme.secondary; // 그래디언트/포인트 컬러용
    final subtleTextColor =
        theme.textTheme.bodySmall?.color?.withOpacity(0.8) ??
            Colors.grey.shade600;

    String getMessage() {
      if (percent >= 90) return "완벽해요! ✨";
      if (percent >= 70) return "아주 잘했어요! 😊";
      if (percent >= 40) return "조금만 더 연습해볼까요?";
      return "괜찮아요, 다시 도전해봐요! 💪";
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '시험 결과',
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: primary),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 뱃지
                Container(
                  padding:
                  const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius:
                    BorderRadius.circular(999),
                  ),
                  child: Text(
                    '시험 번호 : $testNo',
                    style: TextStyle(
                      color: primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 메인 카드
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius:
                    BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.dividerColor
                          .withOpacity(0.3),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.06),
                        blurRadius: 18,
                        offset:
                        const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 퍼센트 동그라미
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              accent.withOpacity(0.25),
                              accent.withOpacity(0.6),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: accent
                                  .withOpacity(0.3),
                              blurRadius: 16,
                              offset:
                              const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize:
                            MainAxisSize.min,
                            children: [
                              Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight:
                                  FontWeight
                                      .w800,
                                  color: primary,
                                ),
                              ),
                              const SizedBox(
                                  height: 4),
                              Text(
                                '정답률',
                                style: TextStyle(
                                  fontSize: 13,
                                  color:
                                  subtleTextColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 멘트
                      Text(
                        getMessage(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight:
                          FontWeight.w700,
                          color: primary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 상세 수치
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          _StatItem(
                            label: '총 문항',
                            value: '$total',
                            color: primary,
                            subtleColor:
                            subtleTextColor,
                          ),
                          const SizedBox(width: 32),
                          _StatItem(
                            label: '맞힌 개수',
                            value: '$correct',
                            color: primary,
                            subtleColor:
                            subtleTextColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 버튼들
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // 현재 시험 화면으로 돌아가기
                          Navigator.pop(context);
                        },
                        style:
                        OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets
                              .symmetric(
                              vertical: 14),
                          side: BorderSide(
                              color: primary),
                          foregroundColor:
                          primary,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                14),
                          ),
                        ),
                        child: const Text(
                          '다시 풀기',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator
                              .pushNamedAndRemoveUntil(
                            context,
                            "/testList", // 너 프로젝트 라우트 이름에 맞게
                                (route) => false,
                          );
                        },
                        style: ElevatedButton
                            .styleFrom(
                          padding:
                          const EdgeInsets
                              .symmetric(
                              vertical: 14),
                          backgroundColor:
                          accent
                              .withOpacity(
                              0.85),
                          foregroundColor:
                          theme
                              .colorScheme
                              .onSecondary,
                          elevation: 0,
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                                14),
                          ),
                        ),
                        child: const Text(
                          '시험 목록으로',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w600,
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
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color subtleColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.subtleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: subtleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }
}

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

    // result가 Map이면 그 안도 같이 뒤져본다
    final Map resultMap =
    (rawResult is Map) ? rawResult as Map : const <String, dynamic>{};

    // total, correct 값을 여러 키에서 찾아본다
    int total = 0;
    int correct = 0;

    // 1순위: 최상위 total / correct
    if (args?['total'] is int) total = args!['total'] as int;
    if (args?['correct'] is int) correct = args!['correct'] as int;

    // 2순위: result 안에 total / correct / totalQuestions / correctAnswers
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

    // 3순위: score/isCorrect만 있을 때 (임시 fallback)
    if (total == 0 && resultMap['score'] is int) {
      total = 1;
      correct = ((resultMap['isCorrect'] ?? 0) == 1) ? 1 : 0;
    }

    final double percent =
    (total > 0) ? (correct / total * 100).clamp(0, 100) : 0;

    // ─────────────────────────────────────────────
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);
    const pink = Color(0xFFFFAAA5);

    String getMessage() {
      if (percent >= 90) return "완벽해요! ✨";
      if (percent >= 70) return "아주 잘했어요! 😊";
      if (percent >= 40) return "조금만 더 연습해볼까요?";
      return "괜찮아요, 다시 도전해봐요! 💪";
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          '시험 결과',
          style: TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: brown),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 상단 뱃지
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEEE9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '시험 번호 : $testNo',
                    style: const TextStyle(
                      color: brown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 메인 카드
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.brown.withOpacity(0.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
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
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE5CF), Color(0xFFFFC9C3)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: pink.withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${percent.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: brown,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                '정답률',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF7C5A48),
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: brown,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 상세 수치
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _statItem(label: '총 문항', value: '$total'),
                          const SizedBox(width: 32),
                          _statItem(label: '맞힌 개수', value: '$correct'),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // 버튼
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // 그냥 뒤로가기 (같은 시험 다시 풀기 느낌)
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: brown),
                          foregroundColor: brown,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '다시 풀기',
                          style: TextStyle(fontWeight: FontWeight.w600),
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: const Color(0xFFFFEEE9),
                          foregroundColor: brown,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          '시험 목록으로',
                          style: TextStyle(fontWeight: FontWeight.w600),
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

Widget _statItem({required String label, required String value}) {
  const brown = Color(0xFF6B4E42);
  return Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF9C7C68),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: brown,
        ),
      ),
    ],
  );
}

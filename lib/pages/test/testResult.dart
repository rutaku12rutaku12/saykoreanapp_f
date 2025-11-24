// lib/pages/test/test_result_page.dart

import 'package:flutter/material.dart';

class TestResultPage extends StatelessWidget {
  const TestResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    // arguments에서 testNo / testMode 받기
    final args = ModalRoute.of(context)?.settings.arguments;
    int? testNo;
    String? testMode;

    if (args is Map) {
      testNo = args['testNo'] as int?;
      testMode = args['testMode'] as String?;
    }

    const brown = Color(0xFF6B4E42);
    const cream = Color(0xFFFFF9F0);
    const mint = Color(0xFFA8DCC4);

    String modeLabel;
    switch (testMode) {
      case 'INFINITE':
        modeLabel = '♾️ 무한모드';
        break;
      case 'HARD':
        modeLabel = '🔥 하드모드';
        break;
      case 'REGULAR':
      default:
        modeLabel = '📝 정기시험';
    }

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cream,
        foregroundColor: brown,
        centerTitle: true,
        title: const Text(
          '시험 결과',
          style: TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 상단 축하 카드
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: mint.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          '🎉',
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '수고했어요!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: brown,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '오늘 시험을 모두 마쳤어요.\n결과를 확인하고, 다음 학습을 이어가 볼까요?',
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Colors.brown.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 시험 정보 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEE9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modeLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.tag,
                          size: 18,
                          color: brown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '시험 번호: ${testNo ?? '-'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: brown,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 18,
                          color: brown,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '응시 모드: ${modeLabel.replaceAll(RegExp(r'[^\uAC00-\uD7A3a-zA-Z0-9 ]'), '')}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: brown,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 통계/점수 카드 (지금은 예시용, 나중에 실제 데이터 바인딩)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _ResultStat(
                      label: '점수',
                      value: '—',
                      subLabel: '총점',
                    ),
                    _ResultStat(
                      label: '정답',
                      value: '—',
                      subLabel: '개수',
                    ),
                    _ResultStat(
                      label: '소요 시간',
                      value: '—',
                      subLabel: '분',
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // 버튼 영역
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    // 홈('/')까지 모두 팝
                    Navigator.popUntil(context, ModalRoute.withName('/'));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mint,
                    foregroundColor: brown,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '홈으로 돌아가기',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 46,
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: 랭킹 페이지 라우트로 연결
                    // Navigator.pushNamed(context, '/ranking');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: brown,
                    side: const BorderSide(color: brown),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    '다른 시험 도전하기',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final String subLabel;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.brown.shade300,
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
        const SizedBox(height: 2),
        Text(
          subLabel,
          style: TextStyle(
            fontSize: 11,
            color: Colors.brown.shade300,
          ),
        ),
      ],
    );
  }
}

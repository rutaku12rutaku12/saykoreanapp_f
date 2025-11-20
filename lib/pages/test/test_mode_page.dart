  // lib/pages/test/test_mode_page.dart

  // ✅ 시험 모드 선택 페이지
  // - 정기시험 : 관리자가 만든 주제별 시험 목록
  // - 무한모드 : 완료한 주제의 모든 문항(틀릴 때까지)
  // - 하드모드 : 전체 DB의 모든 문항 (틀릴 때까지)

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestModePage extends StatefulWidget {
  const TestModePage({super.key});

  @override
  State<TestModePage> createState() => _TestModePageState();
}

class _TestModePageState extends State<TestModePage> {
  bool _loading = false;
  String? _error;
  int _langNo = 1;
  List<dynamic> _regularTests = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // 1. 시험 목록 불러오기
  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      // 완료한 주제(studyNo) 목록 가져오기
      final storedIds = prefs.getStringList('studies') ?? const <String>[];
      final List<int> completedStudyNos = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      print("📚 완료한 주제: $completedStudyNos");

      // 정기시험 목록 조회
      if (completedStudyNos.isEmpty) {
        setState(() => _regularTests = []);
        return;
      }

      // 완료한 주제별로 시험 조회
      final futures = completedStudyNos.map((id) => _fetchTestsByStudy(id));
      final results = await Future.wait(futures, eagerError: false);

      final merged = <dynamic>[];
      for (final list in results) {
        // testMode가 "REGULAR"인 시험만 필터링
        final regularOnly = list.where((test) {
          final mode = test['testMode'] as String?;
          return mode == null || mode == 'REGULAR';
        }).toList();
        merged.addAll(regularOnly);
      }

      setState(() {
        _regularTests = merged;
      });
    } catch (e , st) {
      print("TestModePage _bootstrap error: $e");
      print(st);
      setState(() {
        _error = '시험 목록을 불러오는 중 문제가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }

  }

  // 2. 시험목록 선택 불러오기
  Future<List<dynamic>> _fetchTestsByStudy(int studyNo) async {
    try{
      print("_fetchTestsByStudy(studyNo=$studyNo, langNo=$_langNo");
      final res = await ApiClient.dio.get(
        '/saykorean/test/by-study' ,
        queryParameters: {
          'studyNo' : studyNo,
          'langNo' : _langNo,
        },
      );

      print("▶ by-study($studyNo) status  = ${res.statusCode}");
      print("▶ by-study($studyNo) data    = ${res.data}");

      if (res.data is List) {
        return res.data as List;
      }
      return const [];

    } catch (e , st) {
      print("_fetchTestsByStudy error(studyNo=$studyNo): $e");
      print(st);
      return const [];
    }
  }

  // 정기시험 선택
  void _onTapRegularTest(dynamic test) {
    final rawTestNo = test['testNo'];
    final testNo = (rawTestNo is int)
        ? rawTestNo
        : (rawTestNo is num)
            ? rawTestNo.toInt()
            : int.tryParse(rawTestNo?.toString() ?? "0") ?? 0;

    print("정기시험 선택: testNo=$testNo");
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => TestPage(
                testNo: testNo,
                testMode: "REGULAR",
            ),
        ),
    );
  }

  // ♾️ 무한모드 시작
  void _startInfiniteMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedIds = prefs.getStringList('studies') ?? const <String>[];
      final completedStudyNos = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      if (completedStudyNos.isEmpty) {
        _showDiaLog(
          '♾️ 무한모드',
          '완료한 주제가 없습니다.\n먼저 학습을 완료해주세요!',
        );
        return;
      }

      print("♾️ 무한모드 시작 - 완료한 주제: $completedStudyNos");

      // TestPage로 이동 (testNo는 0, testMode는 "INFINITE")
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestPage(
            testNo: 0, // 무한모드는 testNo 사용 안 함
            testMode: "INFINITE",
          ),
        ),
      );
    } catch (e) {
      print("무한모드 시작 실패: $e");
      _showDiaLog('오류' , '무한모드를 시작할 수 없습니다.');
    }
  }

  // 🔥 하드모드 시작

  void _startHardMode() async {
    print("🔥 하드모드 시작");

    // 확인 다이얼로그
    final confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔥 하드모드'),
          content: const Text(
            '전체 DB의 모든 문항이 출제됩니다.\n'
                '배우지 않은 내용도 포함될 수 있어요.\n'
                '도전하시겠어요?',
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('취소'),
            ),
            TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('도전!')
            ),
          ],
        ),
    );

    if (confirm != true) return;
    
    // Testpage로 이동 (testNo는 0, testMode는 "HARD")
    Navigator.push(
        context, 
        MaterialPageRoute(
            builder: (_) => TestPage(
              testNo: 0,  // 하드모드는 testNo 없음
              testMode: "HARD",
            )
        ),
    );
  }
  
  void _showDiaLog(String title, String message) {
    showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('확인'),
            ),
          ],
        ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);
    
    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('시험 모드 선택'),
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: brown,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 무한모드 카드
                      _buildModeCard(
                        icon: '♾️',
                        title: '무한모드',
                        description: '완료한 주제에서 틀릴 때까지 도전!',
                        color: const Color(0xFFFF9800),
                        onTap: _startInfiniteMode,
                      ),
                      const SizedBox(height: 16),

                      // 하드모드 카드
                      _buildModeCard(
                        icon: '🔥',
                        title: '하드모드',
                        description: '전체 문항에서 틀릴 때까지 도전!',
                        color: const Color(0xFFF44336),
                        onTap: _startHardMode,
                      ),
                      const SizedBox(height: 32),

                      // 정기시험 섹션
                      const Text(
                        '📚 정기시험',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: brown,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '주제별로 체계적인 학습을 진행해보세요',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF9C7C68),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 정기시험 목록
                      if (_regularTests.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              '완료한 주제의 정기시험이 없습니다.',
                              style: TextStyle(color: Color(0xFF999999)),
                            ),
                          ),
                        )
                      else
                        ..._regularTests.map((test) => _buildTestCard(test)),
                    ],
                  ),
      ),
    );
  }


  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
              onPressed: _bootstrap,
              child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required String icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestCard(dynamic test) {
    final testNo = test['testNo'] ?? 0;
    final title = (test['testTitleSelected'] ?? test['testTitle'] ?? '시험 #$testNo').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => _onTapRegularTest(test),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.quiz,
                  color: Color(0xFF667EEA),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF999999),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


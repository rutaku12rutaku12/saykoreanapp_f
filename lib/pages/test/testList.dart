import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/api/api.dart'; // ApiClient.dio
import 'package:saykoreanapp_f/pages/test/test.dart';

class TestListPage extends StatefulWidget {
  const TestListPage({super.key});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  bool _loading = false;
  String? _error;
  int _langNo = 1;
  List<dynamic> _tests = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }



  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    print("🐰 stored studies = ${prefs.getStringList('studies')}");
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 언어 번호(React의 selectedLangNo 대응)
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      // 학습 완료한 studyNo 리스트 (StudyPage._complete 에서 저장한 값과 동일)
      final storedIds = prefs.getStringList('studies') ?? const <String>[];

      final List<int> ids = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      print("TestListPage bootstrap, completed studyIds = $ids, langNo = $_langNo");

      if (ids.isEmpty) {
        setState(() => _tests = []);
        return;
      }

      // 각 studyNo에 대한 테스트 목록 병렬 조회
      final futures = ids.map((id) => _fetchTestsByStudy(id));
      final results = await Future.wait(futures, eagerError: false);

      // List<List<..>> 를 하나의 List로 flatten
      final merged = <dynamic>[];
      for (final list in results) {
        merged.addAll(list);
      }

      setState(() {
        _tests = merged;
      });
    } catch (e, st) {
      print("TestListPage _bootstrap error: $e");
      print(st);
      setState(() {
        _error = '테스트 목록을 불러오는 중 문제가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // /saykorean/test/by-study?studyNo=...&langNo=...
  Future<List<dynamic>> _fetchTestsByStudy(int studyNo) async {
    try {
      print("_fetchTestsByStudy(studyNo=$studyNo, langNo=$_langNo)");
      final res = await ApiClient.dio.get(
        '/saykorean/test/by-study',
        queryParameters: {
          'studyNo': studyNo,
          'langNo': _langNo,
        },
      );

      print("▶ by-study($studyNo) status = ${res.statusCode}");
      print("▶ by-study($studyNo) data   = ${res.data}");

      if (res.data is List) {
        return res.data as List;
      }
      return const [];
    } catch (e, st) {
      print("_fetchTestsByStudy error(studyNo=$studyNo): $e");
      print(st);
      // 하나 실패해도 다른 studyNo들은 계속
      return const [];
    }
  }

  void _onTapTest(dynamic t) {
    final rawTestNo = t['testNo'];
    final testNo = (rawTestNo is int)
        ? rawTestNo
        : (rawTestNo is num)
        ? rawTestNo.toInt()
        : int.tryParse(rawTestNo?.toString() ?? "0") ?? 0;

    // ✅ testMode 추출 ( null인지 확인)
    final testMode = t['testMode'] as String?;

    print("go TestPage: testNo=$testNo , testMode=$testMode");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestPage(
            testNo: testNo,
            testMode: testMode, // ✅ testMode 전달
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);

    print("TestListPage build(), tests.length=${_tests.length}");

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('내 테스트 목록'),
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: brown,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
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

    if (_tests.isEmpty) {
      return const Center(
        child: Text('완수한 주제의 테스트가 아직 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: _tests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final t = _tests[index];

        final rawTestNo = t['testNo'];
        final testNo = (rawTestNo is int)
            ? rawTestNo
            : (rawTestNo is num)
            ? rawTestNo.toInt()
            : int.tryParse(rawTestNo?.toString() ?? "0") ?? 0;

        final title = (t['testTitleSelected'] ??
            t['testTitle'] ??
            '테스트 #$testNo')
            .toString();

        final desc = (t['testDesc'] ?? '').toString();

        // ✅ testMode에 따라 배지 표시
        final testMode = t['testMode'] as String?;
        String modeLabel = '';
        Color modeColor = Colors.grey;

        if (testMode == 'INFINITE') {
          modeLabel = '♾️ 무한';
          modeColor = const Color(0xFFFF9800);
        } else if (testMode == 'HARD') {
          modeLabel = '🔥 하드';
          modeColor = const Color(0xFFF44336);
        }

        return SizedBox(
          height: 56,
          child: ElevatedButton(
            onPressed: () => _onTapTest(t),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6B4E42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),

            // child: Align(
            //   alignment: Alignment.centerLeft,
            //   child: Column(

            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  Row(
                  children: [
                  Expanded(
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                  // if (desc.isNotEmpty)
                  //   Text(
                  //     desc,
                  //     overflow: TextOverflow.ellipsis,
                  //     style: const TextStyle(
                  //       fontSize: 12,
                  //       color: Color(0xFF6B7280),
                  //     ),
                  //   ),

                  // ✅ 모드 배지 표시
                  if (modeLabel.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: modeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: modeColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        modeLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: modeColor,
                        ),
                      ),
                    ),
                  ],
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
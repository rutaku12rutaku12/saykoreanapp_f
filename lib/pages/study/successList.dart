import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study.dart'; // ← 경로는 프로젝트 구조에 맞게 수정

class SuccessListPage extends StatefulWidget {
  const SuccessListPage({super.key});

  @override
  State<SuccessListPage> createState() => _SuccessExamListPageState();
}

class _SuccessExamListPageState extends State<SuccessListPage> {
  bool _loading = false;
  String? _error;
  int _langNo = 1;
  List<StudyDto> _studies = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 언어 번호(React의 selectedLangNo 대응)
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      // 학습 완료한 studyNo 리스트 (StudyPage._complete 에서 저장한 값)
      final storedIds = prefs.getStringList('studies') ?? const <String>[];

      final List<int> ids = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      if (ids.isEmpty) {
        setState(() => _studies = []);
        return;
      }

      // 완료한 주제들 상세 정보 병렬 조회
      final futures = ids.map((id) => _fetchStudyDetail(id));
      final results = await Future.wait(futures, eagerError: false);

      final list = results.whereType<StudyDto>().toList();

      setState(() {
        _studies = list;
      });
    } catch (e) {
      setState(() {
        _error = '완수한 주제 목록을 불러오는 중 문제가 발생했어요.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // /saykorean/study/getDailyStudy?studyNo=...&langNo=...
  Future<StudyDto?> _fetchStudyDetail(int studyNo) async {
    try {
      final res = await dio.get(
        '/saykorean/study/getDailyStudy',
        queryParameters: {
          'studyNo': studyNo,
          'langNo': _langNo,
        },
      );

      // 백엔드에서 StudyDto 1개 내려준다고 가정
      return StudyDto.fromJson(
        Map<String, dynamic>.from(res.data as Map),
      );
    } catch (e) {
      // 개별 실패는 무시
      return null;
    }
  }

  void _onTapStudy(StudyDto item) {
    Navigator.pushNamed(
      context,
      '/study',
      arguments: item.studyNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('완수한 주제 목록'),
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

    if (_studies.isEmpty) {
      return const Center(
        child: Text('완수한 주제가 아직 없습니다.'),
      );
    }

    return ListView.separated(
      itemCount: _studies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _studies[index];
        final title = s.themeSelected ??
            s.themeKo ??
            '주제 #${s.studyNo}'; // React 의 fallback 과 동일

        return SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: () => _onTapStudy(s),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF6B4E42),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        );
      },
    );
  }
}

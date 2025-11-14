import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'study.dart'; // ← 경로는 프로젝트 구조에 맞게 수정


// ─────────────────────────────────────────────────────────────────────────────
// 학습 완료한 주제 목록 페이지
// ─────────────────────────────────────────────────────────────────────────────

class SuccessListPage extends StatefulWidget {
  const SuccessListPage({super.key});

  @override
  State<SuccessListPage> createState() => _SuccessExamListPageState();
}


class _SuccessExamListPageState extends State<SuccessListPage> {
  bool _loading = false; // 전체 로딩 상태
  String? _error; // 에러 메세지
  int _langNo = 1; // 선택된 언어 번호
  List<StudyDto> _studies = const []; // 완료한 주제 리스트

  @override
  void initState() {
    super.initState();
    _bootstrap(); // 초기화
  }


  // SharedPreferences, 서버 호출해서 완료 주제 목록 구성
  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // 언어 번호 = React의 selectedLangNo 대응
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      // 학습 완료한 studyNo 리스트
      final storedIds = prefs.getStringList('studies') ?? const <String>[];

      final List<int> ids = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      // 완료된 주제가 하나도 없으면 바로 빈 리스트 세팅
      if (ids.isEmpty) {
        setState(() => _studies = []);
        return;
      }

      // 각 studyNo에 대해 상세 정보 API 병렬 호출
      final futures = ids.map((id) => _fetchStudyDetail(id));
      final results = await Future.wait(futures, eagerError: false);


      // null이 아닌 StudyNo만 필터링
      final list = results.whereType<StudyDto>().toList();

      setState(() {
        _studies = list;
      });
    } catch (e) {
      // 전체 로딩 중에 에러가 난 경우
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

  // 완료한 주제 버튼 클릭  -> 해당 주제로 StudyPage 열기
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


  // 로딩/에러/데이터 유무에 따라 다른 UI
  Widget _buildBody() {
    // 1) 로딩 중
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 2) 에러 발생
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


    // 3) 완료한 주제가 하나도 없는 경우
    if (_studies.isEmpty) {
      return const Center(
        child: Text('완수한 주제가 아직 없습니다.'),
      );
    }

    // 4) 정상적으로 목록이 있는 경우에는 리스트 출력
    return ListView.separated(
      itemCount: _studies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _studies[index];
        // 백엔드에서 내려주는 선택된 언어 제목 -> 한국어 제목 -> fallback
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
                overflow: TextOverflow.ellipsis, // 긴 제목은 ...처리
              ),
            ),
          ),
        );
      },
    );
  }
}

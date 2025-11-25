// lib/pages/study/successList.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/api/api.dart';   // ApiClient.dio
import 'study.dart';                           // StudyDto 사용
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ SKPageHeader, SKPrimaryButton

// ─────────────────────────────────────────────────────────────
// 학습 완료한 주제 목록 페이지
// ─────────────────────────────────────────────────────────────
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

      // null이 아닌 StudyDto만 필터링
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
      final res = await ApiClient.dio.get(
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

  // 완료한 주제 카드 클릭  -> 해당 주제로 StudyPage 열기
  void _onTapStudy(StudyDto item) {
    Navigator.pushNamed(
      context,
      '/study',
      arguments: item.studyNo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text(''), // 실제 타이틀은 SKPageHeader에서 크게 표시
        backgroundColor: bg,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SKPageHeader(
                title: '완수한 주제',
                subtitle: '이미 학습을 마친 주제 목록이에요.',
              ),
              const SizedBox(height: 16),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  // 로딩/에러/데이터 유무에 따라 다른 UI
  Widget _buildBody(BuildContext context) {
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
            SKPrimaryButton(
              label: '다시 시도',
              onPressed: _bootstrap,
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

    // 4) 정상적으로 목록이 있는 경우에는 카드 리스트 출력
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView.separated(
      itemCount: _studies.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final s = _studies[index];
        final title =
            s.themeSelected ?? s.themeKo ?? '주제 #${s.studyNo}';

        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _onTapStudy(s),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // 왼쪽 컬러 점/아이콘
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 제목
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
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: scheme.outline,
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

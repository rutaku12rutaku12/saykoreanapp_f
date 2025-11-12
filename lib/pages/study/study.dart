import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 환경별 baseUrl 감지 (dart-define로 API_HOST 넘기면 그것을 우선 사용)
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST'); // 예) --dart-define=API_HOST=http://192.168.0.10:8080
  if (env.isNotEmpty) return env;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080'; // 안드 에뮬레이터→호스트
  return 'http://localhost:8080';                        // iOS 시뮬레이터/데스크톱
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 6),
  receiveTimeout: const Duration(seconds: 12),
));

final Uri _baseUri = Uri.parse(_detectBaseUrl());

String buildUrl(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;
  if (path.startsWith('file://')) {
    final p = path.replaceFirst('file://', '');
    return _baseUri.resolve(p.startsWith('/') ? p.substring(1) : p).toString();
  }
  return _baseUri.resolve(path.startsWith('/') ? path.substring(1) : path).toString();
}

// ─────────────────────────────────────────────────────────────────────────────
// DTO
class StudyDto {
  final int studyNo;
  final int? genreNo;
  final String? themeSelected;
  final String? themeKo;
  final String? commenSelected;

  StudyDto({
    required this.studyNo,
    this.genreNo,
    this.themeSelected,
    this.themeKo,
    this.commenSelected,
  });

  factory StudyDto.fromJson(Map<String, dynamic> j) => StudyDto(
    studyNo: (j['studyNo'] ?? j['id']) as int,
    genreNo: j['genreNo'] as int?,
    themeSelected: (j['themeSelected'] ?? j['studyTitleSelected'] ?? j['titleSelected'])?.toString(),
    themeKo: (j['themeKo'] ?? j['titleKo'])?.toString(),
    commenSelected: (j['commenSelected'] ?? j['commentSelected'])?.toString(),
  );
}

class ExamDto {
  final int examNo;
  final String? examSelected;
  final String? imagePath;
  final String? koAudioPath;
  final String? enAudioPath;

  ExamDto({
    required this.examNo,
    this.examSelected,
    this.imagePath,
    this.koAudioPath,
    this.enAudioPath,
  });

  factory ExamDto.fromJson(Map<String, dynamic> j) => ExamDto(
    examNo: (j['examNo'] ?? j['id']) as int,
    examSelected: j['examSelected']?.toString(),
    imagePath: j['imagePath']?.toString(),
    koAudioPath: j['koAudioPath']?.toString(),
    enAudioPath: j['enAudioPath']?.toString(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 페이지
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  bool _loading = false;
  String? _error;

  // 목록/상세 상태
  List<StudyDto> _subjects = const [];
  StudyDto? _subject; // 선택된 주제 상세
  ExamDto? _exam;     // 현재 예문

  // 로컬 상태
  int? _genreNo;
  int _langNo = 1;

  // 오디오
  final AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // (선택) arguments로 초기 studyNo 받기
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is int && _subject == null) {
      // 뒤에서 목록 로드 후에 적용
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _genreNo = prefs.getInt('selectedGenreNo');
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      if (_genreNo == null || _genreNo! <= 0) {
        setState(() => _error = '먼저 장르를 선택해 주세요.');
        return;
      }

      await _fetchSubjects(); // 목록 로드
    } catch (e) {
      setState(() => _error = '초기화 실패: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  // ── API: 목록/상세/예문
  Future<void> _fetchSubjects() async {
    try {
      final res = await dio.get(
        '/saykorean/study/getSubject',
        queryParameters: {'genreNo': _genreNo, 'langNo': _langNo},
        options: Options(headers: {'Accept-Language': _langNo.toString()}),
      );

      final list = (res.data is List ? res.data as List : <dynamic>[])
          .map((e) => StudyDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      setState(() => _subjects = list);
    } on DioException catch (e) {
      setState(() => _error = e.message ?? '주제 목록을 가져오지 못했습니다.');
    } catch (_) {
      setState(() => _error = '주제 목록을 가져오지 못했습니다.');
    }
  }

  Future<void> _fetchDailyStudy(int studyNo) async {
    try {
      final res = await dio.get(
        '/saykorean/study/getDailyStudy',
        queryParameters: {'studyNo': studyNo, 'langNo': _langNo},
        options: Options(headers: {'Accept-Language': _langNo.toString()}),
      );
      setState(() => _subject = StudyDto.fromJson(Map<String, dynamic>.from(res.data)));
    } on DioException catch (e) {
      setState(() => _error = e.message ?? '주제 상세를 불러오지 못했습니다.');
    } catch (_) {
      setState(() => _error = '주제 상세를 불러오지 못했습니다.');
    }
  }

  Future<void> _fetchFirstExam(int studyNo) async {
    try {
      final res = await dio.get(
        '/saykorean/study/exam/first',
        queryParameters: {'studyNo': studyNo, 'langNo': _langNo},
      );
      setState(() => _exam = ExamDto.fromJson(Map<String, dynamic>.from(res.data)));
    } on DioException catch (e) {
      setState(() => _error = e.message ?? '예문을 불러오지 못했습니다.');
    } catch (_) {
      setState(() => _error = '예문을 불러오지 못했습니다.');
    }
  }

  Future<void> _fetchNextExam() async {
    if (_exam == null || _subject == null) return;
    try {
      final res = await dio.get(
        '/saykorean/study/exam/next',
        queryParameters: {
          'studyNo': _subject!.studyNo,
          'currentExamNo': _exam!.examNo,
          'langNo': _langNo,
        },
      );
      setState(() => _exam = ExamDto.fromJson(Map<String, dynamic>.from(res.data)));
    } catch (_) {}
  }

  Future<void> _fetchPrevExam() async {
    if (_exam == null || _subject == null) return;
    try {
      final res = await dio.get(
        '/saykorean/study/exam/prev',
        queryParameters: {
          'studyNo': _subject!.studyNo,
          'currentExamNo': _exam!.examNo,
          'langNo': _langNo,
        },
      );
      setState(() => _exam = ExamDto.fromJson(Map<String, dynamic>.from(res.data)));
    } catch (_) {}
  }

  // ── 오디오
  Future<void> _play(String? url) async {
    if (url == null || url.isEmpty) return;

    // 상대경로(file:///upload/..., /upload/...) → http(s) 절대경로로 변환
    final resolved = buildUrl(url);

    try {
      await _player.stop();
      await _player.play(UrlSource(resolved));
    } catch (e) {
    }
  }

  // ── 완료 처리
  Future<void> _complete() async {
    final id = _subject?.studyNo;
    if (id == null || id <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final prev = prefs.getStringList('studies') ?? [];
    final Set<String> merged = {...prev, id.toString()};
    await prefs.setStringList('studies', merged.toList());

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('학습이 완료되었습니다!')),
    );

    // 이동
    Navigator.pushNamed(context, '/successList'); // 예: 시험 화면으로
  }

  // ── UI
  @override
  Widget build(BuildContext context) {
    final cream = const Color(0xFFFFF9F0);
    final brown = const Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: const Text('학습'),
        backgroundColor: cream,
        elevation: 0,
        foregroundColor: brown,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorView(message: _error!, onRetry: _bootstrap)
          : (_subject == null ? _buildList() : _buildDetail()),
    );
  }

  Widget _buildList() {
    // 주제 목록 (필 버튼)
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _subjects.map((s) {
          final label = s.themeSelected ?? s.themeKo ?? '제목 없음';
          return _PillButton(
            label: label,
            active: false,
            onTap: () async {
              setState(() {
                _loading = true;
                _error = null;
              });
              await _fetchDailyStudy(s.studyNo);
              await _fetchFirstExam(s.studyNo);
              if (mounted) setState(() => _loading = false);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDetail() {
    final t = _subject!;
    final title = t.themeSelected ?? t.themeKo ?? '제목 없음';

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF6B4E42),
                    )),
                if (t.commenSelected != null && t.commenSelected!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      t.commenSelected!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0x995C4A42),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_exam != null) _ExamCard(
            exam: _exam!,
            onPlayKo: () => _play(_exam!.koAudioPath),
            onPlayEn: () => _play(_exam!.enAudioPath),
            onPrev: _fetchPrevExam,
            onNext: _fetchNextExam,
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _complete,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEEE9),
                foregroundColor: const Color(0xFF6B4E42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text('학습 완료'),
            ),
          ),

          const SizedBox(height: 8),

          SizedBox(
            height: 44,
            child: OutlinedButton(
              onPressed: () => setState(() {
                _subject = null;
                _exam = null;
              }),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE5D5CC)),
                foregroundColor: const Color(0xFF6B4E42),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('목록으로'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 컴포넌트들

class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFFFEEE9) : Colors.white;
    final fg = active ? const Color(0xFFFF7F79) : const Color(0xFF444444);
    final br = active ? const Color(0xFFFFC7C2) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: br),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final ExamDto exam;
  final VoidCallback onPlayKo;
  final VoidCallback onPlayEn;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _ExamCard({
    required this.exam,
    required this.onPlayKo,
    required this.onPlayEn,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final text = exam.examSelected ?? '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          if (exam.imagePath != null && exam.imagePath!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 350, // 가로 폭 제한
                height: 350, // 세로 폭 제한
                child: Image.network(
                  buildUrl(exam.imagePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Text('이미지를 불러올 수 없어요'),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF3F3F46),
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlayKo,
                  icon: const Text('🔊'),
                  label: const Text('한국어'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5D5CC)),
                    foregroundColor: const Color(0xFF6B4E42),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onPlayEn,
                  icon: const Text('🔊'),
                  label: const Text('영어'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE5D5CC)),
                    foregroundColor: const Color(0xFF6B4E42),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onPrev,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEEE9),
                    foregroundColor: const Color(0xFF6B4E42),
                    elevation: 0,
                  ),
                  child: const Text('이전'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEEE9),
                    foregroundColor: const Color(0xFF6B4E42),
                    elevation: 0,
                  ),
                  child: const Text('다음'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(onPressed: onRetry, child: const Text('다시 시도')),
      ]),
    );
  }
}

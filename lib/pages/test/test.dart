import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 환경 감지
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST');
  if (env.isNotEmpty) return env;
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 10),
));

// ─────────────────────────────────────────────────────────────────────────────
// TestPage
class TestPage extends StatefulWidget {
  final int testNo;
  const TestPage({super.key, required this.testNo});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool loading = false;
  String msg = "";
  List<dynamic> items = [];
  int idx = 0;
  bool submitting = false;
  Map<String, dynamic>? feedback;
  int? testRound;
  int langNo = 1; // 기본값
  String subjective = "";

  @override
  void initState() {
    super.initState();
    _loadLangAndTest();
  }

  // 언어 로드 후 문항 로드
  Future<void> _loadLangAndTest() async {
    // TODO: SharedPreferences 에서 언어번호 로드 가능
    langNo = 1; // 임시 고정
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      loading = true;
      msg = "";
    });

    try {
      // 회차 조회
      final roundRes = await dio.get('/saykorean/test/getnextround', queryParameters: {
        "testNo": widget.testNo,
      });
      testRound = roundRes.data ?? 1;

      // 문항 데이터 로드
      final res = await dio.get('/saykorean/test/findtestitem', queryParameters: {
        "testNo": widget.testNo,
        "langNo": langNo,
      });

      final list = (res.data is List) ? res.data as List : [];
      setState(() {
        items = list;
        idx = 0;
      });
    } catch (e) {
      msg = "문항을 불러올 수 없습니다.";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> submitAnswer({int? selectedExamNo}) async {
    if (testRound == null) return;
    final cur = items[idx];
    final isSubjective = idx % 3 == 2;

    final body = {
      "testRound": testRound,
      "selectedExamNo": selectedExamNo ?? 0,
      "userAnswer": selectedExamNo != null ? "" : subjective,
      "langNo": langNo
    };

    final url = "/saykorean/test/${widget.testNo}/items/${cur['testItemNo']}/answer";

    // 주관식이면 로딩 화면 전환 가능
    if (isSubjective && selectedExamNo == null) {
      // 예: Navigator.push(context, MaterialPageRoute(builder: (_) => LoadingPage(...)));
      print("로딩 페이지로 이동 (주관식)");
      return;
    }

    try {
      setState(() => submitting = true);
      final res = await dio.post(url, data: body);
      final data = res.data;
      setState(() {
        feedback = {
          "correct": data["isCorrect"] == 1,
          "score": data["score"] ?? 0,
        };
      });
    } catch (e) {
      msg = "답안 제출 실패";
    } finally {
      setState(() => submitting = false);
    }
  }

  void goNext() {
    if (idx < items.length - 1) {
      setState(() {
        idx++;
        subjective = "";
        feedback = null;
      });
    } else {
      Navigator.pushNamed(context, "/testresult/${widget.testNo}");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cur = (items.isNotEmpty) ? items[idx] : null;
    final questionType = idx % 3; // 0=그림,1=음성,2=주관식
    final isImageQuestion = questionType == 0;
    final isAudioQuestion = questionType == 1;
    final isSubjective = questionType == 2;

    return Scaffold(
      appBar: AppBar(title: const Text("시험 보기")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
            ? Center(child: Text(msg.isEmpty ? "문항이 없습니다." : msg))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("${idx + 1} / ${items.length}",
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(cur?['questionSelected'] ?? "",
                style: const TextStyle(fontSize: 16)),

            // 이미지 문항
            if (isImageQuestion && cur?['imagePath'] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 180,
                    child: AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Image.network(
                        "${_detectBaseUrl()}/${cur!['imagePath']}",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Text('이미지를 불러올 수 없어요'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // 🎵 오디오 문항
            if (isAudioQuestion && cur?['audios'] != null)
              Column(
                children: [
                  for (final audio in (cur!['audios'] as List))
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(vertical: 8.0),
                      child: TextButton(
                        onPressed: () {
                          // TODO: audio 재생 로직 추가 (audioplayers 등)
                        },
                        child: Text("🔊 ${audio['audioPath']}"),
                      ),
                    )
                ],
              ),

            // 📝 주관식 예문
            if (isSubjective && cur?['examSelected'] != null)
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(cur!['examSelected']),
              ),

            const SizedBox(height: 16),

            // 객관식
            if (!isSubjective)
              Column(
                children: [
                  if ((cur?['options'] as List?)?.isNotEmpty ?? false)
                    for (final opt in (cur!['options'] as List))
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 4),
                        child: ElevatedButton(
                          onPressed: feedback == null
                              ? () => submitAnswer(
                              selectedExamNo: opt['examNo'])
                              : null,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.teal,
                              side: const BorderSide(
                                  color: Colors.teal)),
                          child: Text(opt['examSelected'] ??
                              opt['examKo'] ??
                              "보기 로드 실패"),
                        ),
                      )
                  else
                    const Text("보기 불러오기 실패"),
                ],
              )
            else
            // 주관식 입력
              Column(
                children: [
                  TextField(
                    enabled: feedback == null,
                    minLines: 3,
                    maxLines: 4,
                    onChanged: (v) => subjective = v,
                    decoration: const InputDecoration(
                      hintText: "한국어로 답변을 작성하세요",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: (subjective.trim().isEmpty ||
                        submitting)
                        ? null
                        : () => submitAnswer(),
                    child: Text(submitting ? "로딩 중..." : "제출"),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // 결과/피드백
            if (feedback != null)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: feedback!['correct']
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      feedback!['correct']
                          ? "정답입니다!"
                          : "틀렸어요 😢",
                      style: TextStyle(
                        color: feedback!['correct']
                            ? Colors.green.shade900
                            : Colors.red.shade900,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: goNext,
                    child: Text(
                      idx < items.length - 1
                          ? "다음 문제"
                          : "결과 보기",
                    ),
                  )
                ],
              ),
          ],
        ),
      ),
    );
  }
}

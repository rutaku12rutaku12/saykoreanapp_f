// lib/pages/test/test.dart

import 'package:saykoreanapp_f/pages/test/loading.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/api/api.dart'; // 전역 Dio: ApiClient.dio 사용

class TestPage extends StatefulWidget {
  final int testNo;
  final String? testMode; // 시험모드 추가 : "REGULAR" , "INFINITE" , "HARD"

  const TestPage({super.key, required this.testNo, this.testMode});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  bool loading = false;
  String msg = "";
  List<dynamic> items = [];
  int idx = 0;

  bool submitting = false;
  String subjective = "";
  Map<String, dynamic>? feedback;

  int? langNo; // null 일 때는 아직 언어 안 정해진 상태
  int? testRound; // 회차

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLangAndQuestions();
  }

  Future<void> _initLangAndQuestions() async {
    // 1) 언어 로컬스토리지에서 읽기
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getInt('selectedLangNo');
      final n = stored ?? 1;
      setState(() => langNo = (n > 0) ? n : 1);
    } catch (e) {
      print("langNo load error: $e");
      setState(() => langNo = 1);
    }

    // 2) 언어 설정 후 문항/회차 로드
    await _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    if (langNo == null) return;

    setState(() {
      loading = true;
      msg = "";
      items = [];
      idx = 0;
      subjective = "";
      feedback = null;
    });

    try {

      // [1] 문항 로드 - 모드 분기 :: 2번째에서 1번째로
      print("🎯 testMode = ${widget.testMode}");
      List<dynamic> list = [];

      if (widget.testMode == "INFINITE") {
        // 무한모드 : 완료한 studyNo가 나오는 문항
        print("♾️ 무한모드 문항 로드 시작");
        list = await _loadInfiniteItems();
        // testRound 0 설정 ( 무한모드는 회차 개념 없음 )
        setState(() {
          testRound = 0;
        });
      } else if (widget.testMode == "HARD") {
        // 하드모드 : 전체 문항
        print("🔥 하드모드 문항 로드 시작");
        list = await _loadHardItems();
        // testRound 0 설정 ( 하드모드는 회차 개념 없음 )
        setState(() {
          testRound = 0;
        });
      } else {
        // 정규 시험
        print("📝 정기 시험 문항 로드 시작");

        // [2] 다음 회차 조회
        final roundRes = await ApiClient.dio.get(
          "/saykorean/test/getnextround",
          queryParameters: {"testNo": widget.testNo},
        );
        print("getnextround status = ${roundRes.statusCode}");
        print("getnextround data   = ${roundRes.data}");

        int nextRound = 1;
        final data = roundRes.data;
        if (data is int) {
          nextRound = data;
        } else if (data is Map && data['testRound'] is int) {
          nextRound = data['testRound'] as int;
        }
        setState(() => testRound = nextRound);

        list = await _loadRegularItems();

      }


      print("✅ 로드된 문항 수: ${list.length}");

      setState(() {
        items = list;
        idx = 0;
        msg = items.isEmpty ? "문항이 없습니다." : "";
      });
    } catch (e, st) {
      print("_loadQuestions error: $e");
      print(st);
      setState(() {
        msg = "문항을 불러올 수 없습니다.";
        items = [];
      });
    } finally {
      setState(() => loading = false);
    }
  }
      
  // 📝 [3-1] 정기 시험 문항 로드
  Future<List<dynamic>> _loadRegularItems() async {
      final res = await ApiClient.dio.get(
        "/saykorean/test/findtestitem",
        queryParameters: {
          "testNo": widget.testNo,
          "langNo": langNo,
        },
      );

      print("▶ findtestitem status = ${res.statusCode}");
      print("▶ findtestitem data   = ${res.data}");


      if (res.data is List) {
        return res.data as List;
      } else if (res.data is Map && res.data['list'] is List) {
        return res.data['list'] as List;
      } else {
        return [];
      }
  }


  // ♾️ [3-2] 무한모드 문항 로드
  Future<List<dynamic>> _loadInfiniteItems() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds = prefs.getStringList('studies') ?? const <String>[];

    final List<int> studyNos = storedIds
        .map((s) => int.tryParse(s))
        .where((n) => n != null && n! > 0)
        .cast<int>()
        .toList();
    
    // 완료한 주제가 비어있으면
    if (studyNos.isEmpty) {
      print("⚠️ 무한모드 : 완료한 주제가 없습니다");
      return [];
    }

    print("📚 무한모드 : studyNos = $studyNos}");

    final res = await ApiClient.dio.get(
      "/saykorean/test/infinite-items" ,
      queryParameters: {
        "langNo" : langNo ,
        "studyNos" : studyNos.join(','),
      },
    );

    print("▶ infinite-items status = ${res.statusCode}");
    print("▶ infinite-items count  = ${(res.data as List?)?.length ?? 0}");

    if (res.data is List) {
      final list = res.data as List;
      list.shuffle(); // 클라이언트에서 난수화
      return list;
    }
    return [];
  }

  // 🔥 [3-3] 하드모드 문항 로드
  Future<List<dynamic>> _loadHardItems() async {
    print("🔥 하드모드: 전체 문항 로드");

    final res = await ApiClient.dio.get(
      "/saykorean/test/hard-items" ,
      queryParameters: {
        "langNo" : langNo,
      },
    );

    print("▶ hard-items status = ${res.statusCode}");
    print("▶ hard-items count  = ${(res.data as List?)?.length ?? 0}");

    if (res.data is List) {
      final list = res.data as List;
      list.shuffle(); // 클라이언트에서 난수화
      return list;
    }
    return [];
  }

  // 문자열 안전 체크 (null / 빈문자열 방지용)
  String? _safeSrc(dynamic s) {
    if (s is String && s.trim().isNotEmpty) return s;
    return null;
  }

  // ─────────────────────────────────────────────────────────────
  //
  //   POST /saykorean/test/{testNo}/items/{testItemNo}/answer
  //   body: { testRound, selectedExamNo, userAnswer, langNo }
  //   resp: { score, isCorrect(1/0) }
  //

  // 답안 제출
  Future<void> submitAnswer({int? selectedExamNo}) async {
    if (items.isEmpty) return;
    if (testRound == null) return;

    final cur = items[idx] as Map<String, dynamic>;

    // 백엔드와 동일 규칙: itemIndex % 3 로 타입 판별 (0/1 = 객관식, 2 = 주관식)
    final questionType = idx % 3; // 0=그림객관식, 1=음성객관식, 2=주관식
    final isSubjective = questionType == 2;

    final body = {
      "testRound": testRound,
      "selectedExamNo": selectedExamNo ?? 0, // 객관식: examNo, 주관식: 0
      "userAnswer":
      selectedExamNo != null ? "" : subjective, // 주관식만 userAnswer 사용
      "langNo": langNo,
      // 🔥 userNo는 이제 안 보냄. AuthUtil이 JWT/세션에서 읽어감.
    };

    // 무한/하드모드: testItemNo가 없을 수 있으므로 임시 처리
    final testItemNo = cur['testItemNo'] ?? 0;

    // ✅ 무한/하드모드는 testNo가 0이므로 testItemNo 기반 URL 생성
    final effectiveTestNo = widget.testNo > 0 ? widget.testNo : 1;
    final url =
        "/saykorean/test/$effectiveTestNo/items/$testItemNo/answer";

    // 주관식: 로딩 페이지로 넘기기 (React와 동일 플로우)
    if (isSubjective && selectedExamNo == null) {
      print("주관식 → 로딩 페이지로 이동");
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        "/loading",
        arguments: {
          "action": "submitAnswer",
          "payload": {
            "testNo": effectiveTestNo,
            "url": url,
            "body": body,
          },
        },
      );
      return;
    }

    // 객관식: 바로 제출
    try {
      setState(() => submitting = true);
      final res = await ApiClient.dio.post(url, data: body);
      print("▶ submitAnswer status = ${res.statusCode}");
      print("▶ submitAnswer data   = ${res.data}");

      final data = res.data;

      int score = 0;
      bool isCorrect = false;

      if (data is Map) {
        // score: number
        final s = data["score"];
        if (s is num) {
          score = s.toInt();
        }

        // isCorrect: 1 or 0 (백엔드 계약)
        final ic = data["isCorrect"];
        if (ic is num) {
          isCorrect = ic == 1;
        } else if (ic is bool) {
          isCorrect = ic;
        } else if (ic is String) {
          final v = ic.toLowerCase();
          isCorrect = (v == "1" || v == "true");
        }
      }

      setState(() {
        feedback = {
          "correct": isCorrect,
          "score": score,
        };
      });
    } catch (e, st) {
      print("submitAnswer error: $e");
      print(st);
      setState(() {
        msg = "답안 제출 실패";
        feedback = {
          "correct": false,
          "score": 0,
        };
      });
    } finally {
      setState(() => submitting = false);
    }
  }

  void goNext() {
    // ✅ 무한/하드모드 : 한 문제 틀리면 게임 오버
    if (widget.testMode == "INFINITE" || widget.testMode == "HARD") {
      if (feedback != null && !feedback!['correct']) {
        _showGameOverDialog();
        return;
      }
    }

    if (idx < items.length - 1) {
      setState(() {
        idx++;
        subjective = "";
        feedback = null;
      });
    } else {
      // 정기시험 : 결과 ㅍ에ㅣ지로
      if (widget.testMode == "REGULAR") {
        Navigator.pushNamed(context, "/testresult/${widget.testNo}");
      } else {
        // 무한/하드모드 : 모든 문제 정답 시
        _showVictoryDialog();
      }
    }
  }

  // 무한모드/하드모드 오답 시 종료 다이얼로그
  void _showGameOverDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("게임 오버"),
          content: Text(
            widget.testMode == "INFINITE"
                ? "무한모드 종료!\n${idx + 1}문제까지 도전했어요!"
                : "하드모드 종료!\n${idx + 1}문제까지 도전했어요!"
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로드 닫기
                  Navigator.pop(context); // 시험페이지 닫기
                },
                child: const Text("확인"),
            ),
          ],
        )
    );
  }

  // 무한모드/하드모드 모든 문제 정답 시 다이얼로그
  void _showVictoryDialog() {
    showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text("🎉 완벽합니다!"),
          content: Text(
            widget.testMode == "INFINITE"
                ? "무한모드 모든 문제 정답! \n${items.length}문제 클리어!"
                : "하드모드 모든 문제 정답! \n${items.length}문제 클리어!"
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text("확인"),
            ),
          ],
        ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);
    final screenWidth = MediaQuery.of(context).size.width;

    final cur = (items.isNotEmpty) ? items[idx] as Map<String, dynamic> : null;

    // 백엔드와 **동일 규칙**: itemIndex % 3 로 문항 타입 판별
    final questionType = idx % 3; // 0=그림 객관식, 1=음성 객관식, 2=주관식
    final isImageQuestion = questionType == 0;
    final isAudioQuestion = questionType == 1;
    final isSubjective = questionType == 2;
    final isMultiple = !isSubjective;

    final hasImage = _safeSrc(cur?['imagePath']) != null;
    final hasAudio =
        cur?['audios'] is List && (cur!['audios'] as List).isNotEmpty;

    print("🔍 문항 타입: idx=$idx, type=$questionType, "
        "image=$hasImage, audio=$hasAudio, subj=$isSubjective");

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        backgroundColor: cream,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: brown),
        title: Text(
          widget.testMode == "INFINITE"
              ? '♾️ 무한모드'
              : widget.testMode == "HARD"
              ? '🔥 하드모드'
              : '📝 정기시험',
          style: const TextStyle(
            color: brown,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
          ? Center(
        child: Text(
          msg.isEmpty ? "문항이 없습니다." : msg,
          style: const TextStyle(color: Colors.grey),
        ),
      )
          : SafeArea(
        child: SingleChildScrollView(
          padding:
          const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              // 상단 타이틀
              Text(
                widget.testMode == "INFINITE"
                    ? "♾️ 무한모드"
                    : widget.testMode == "HARD"
                    ? "🔥 하드모드"
                    : "📝 오늘의 시험",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.testMode == "INFINITE" || widget.testMode == "HARD"
                    ? "틀릴 때까지 계속 도전해요!"
                    : "문제를 풀고 자신의 실력을 확인해 보아요.",
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
              const SizedBox(height: 18),

              // 진행도
              Text(
                "${idx + 1} / ${items.length}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7C5A48),
                ),
              ),
              const SizedBox(height: 8),

              // 문제 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                  ),
                  borderRadius:
                  BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.brown
                          .withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.center,
                  children: [
                    // 질문 텍스트
                    Text(
                      cur?['questionSelected'] ?? "",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF3F3F46),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 그림 (0,3,6...) 번째 문항
                    if (isImageQuestion && hasImage)
                      ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: AspectRatio(
                            aspectRatio: 3 / 3,
                            child: Image.network(
                              ApiClient.buildUrl(
                                _safeSrc(cur![
                                'imagePath'])!,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) =>
                              const Center(
                                child: Text(
                                    '이미지를 불러올 수 없어요'),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 오디오 (1,4,7...) 번째 문항
                    if (isAudioQuestion && hasAudio)
                      Column(
                        children: [
                          for (final audio
                          in (cur!['audios']
                          as List))
                            if (_safeSrc(audio[
                            'audioPath']) !=
                                null)
                              Padding(
                                padding:
                                const EdgeInsets
                                    .symmetric(
                                    vertical: 6.0),
                                child: OutlinedButton(
                                  onPressed: () {
                                    // TODO: 오디오 플레이 로직
                                  },
                                  style: OutlinedButton
                                      .styleFrom(
                                    foregroundColor:
                                    brown,
                                    side:
                                    const BorderSide(
                                      color: Color(
                                          0xFFE5D5CC),
                                    ),
                                  ),
                                  child: Text(
                                      "🔊 ${audio['audioPath']}"),
                                ),
                              )
                        ],
                      ),

                    // 주관식 예문 (2,5,8...) 번째 문항
                    if (isSubjective &&
                        cur?['examSelected'] != null)
                      Container(
                        margin:
                        const EdgeInsets.only(
                            top: 10),
                        padding:
                        const EdgeInsets.all(
                            12),
                        decoration:
                        BoxDecoration(
                          color: const Color(
                              0xFFF9FAFB),
                          borderRadius:
                          BorderRadius
                              .circular(10),
                        ),
                        child: Text(
                          cur!['examSelected'],
                          style: const TextStyle(
                            fontSize: 15,
                            color:
                            Color(0xFF4B5563),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 객관식 / 주관식 영역
              if (isMultiple)
                _buildMultipleChoice(cur)
              else
                _buildSubjective(),

              const SizedBox(height: 20),

              // 피드백 + 다음 버튼
              if (feedback != null)
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .stretch,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets
                          .all(14),
                      decoration:
                      BoxDecoration(
                        color: feedback![
                        'correct']
                            ? Colors.green
                            .shade100
                            : Colors.red
                            .shade100,
                        borderRadius:
                        BorderRadius
                            .circular(12),
                      ),
                      child: Text(
                        feedback!['correct']
                            ? "정답입니다!"
                            : "틀렸어요 😢",
                        style: TextStyle(
                          color: feedback![
                          'correct']
                              ? Colors.green
                              .shade900
                              : Colors.red
                              .shade900,
                          fontWeight:
                          FontWeight.bold,
                        ),
                        textAlign:
                        TextAlign.center,
                      ),
                    ),
                    const SizedBox(
                        height: 10),
                    SizedBox(
                      height: 48,
                      child:
                      ElevatedButton(
                        onPressed:
                        goNext,
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                              0xFFFFEEE9),
                          foregroundColor:
                          brown,
                          elevation: 0,
                        ),
                        child: Text(
                          idx <
                              items.length -
                                  1
                              ? "다음 문제"
                              : "결과 보기",
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  Widget _buildMultipleChoice(Map<String, dynamic>? cur) {
    const titleColor = Color(0xFF7C5A48);

    final options = cur?['options'];
    final hasOptions =
        options is List && options.isNotEmpty;

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "정답을 골라보세요",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        if (hasOptions)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
            (options as List).map<Widget>((opt) {
              final map =
              opt as Map<String, dynamic>;
              final label = map['examSelected'] ??
                  map['examKo'] ??
                  "보기 로드 실패";
              return _ChoiceButton(
                label: label.toString(),
                onTap: feedback == null
                    ? () => submitAnswer(
                  selectedExamNo: _toInt(map['examNo']),
                )
                    : null,
              );
            }).toList(),
          )
        else
          const Text("보기 불러오기 실패"),
      ],
    );
  }

  Widget _buildSubjective() {
    const titleColor = Color(0xFF7C5A48);
    const brown = Color(0xFF6B4E42);

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const Text(
          "한국어로 답을 입력해 보세요",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          enabled: feedback == null,
          minLines: 3,
          maxLines: 4,
          onChanged: (v) {
            setState(() {
              subjective = v;
            });
          },
          decoration: const InputDecoration(
            hintText: "한국어로 답변을 작성하세요",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton(
            onPressed: (subjective.trim().isEmpty ||
                submitting)
                ? null
                : () => submitAnswer(),
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFFFFEEE9),
              foregroundColor: brown,
              elevation: 0,
            ),
            child: Text(
                submitting ? "로딩 중..." : "제출"),
          ),
        ),
      ],
    );
  }
}

// 선택지 pill 버튼
class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ChoiceButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF2F7A69);
    const textColor = Color(0xFF2F7A69);

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border:
          Border.all(color: borderColor),
          borderRadius:
          BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: textColor,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

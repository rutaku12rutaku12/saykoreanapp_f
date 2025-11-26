// lib/pages/test/test.dart

import 'package:saykoreanapp_f/pages/test/loading.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:saykoreanapp_f/api/api.dart'; // 전역 Dio: ApiClient.dio 사용
import 'package:easy_localization/easy_localization.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ FooterSafeArea / 공통 UI

class TestPage extends StatefulWidget {
  final int testNo;
  final String? testMode; // "REGULAR" , "INFINITE" , "HARD"

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

  // AudioPlayer
  final AudioPlayer _audioPlayer = AudioPlayer();

  int? langNo; // null 이면 아직 언어 안 정해진 상태
  int? testRound; // 회차

  // ✅ 정기시험 정답 개수 카운트용
  int _correctCount = 0;

  // ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLangAndQuestions();
  }

  // 🌍 언어 변경 감지
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _onLocaleChanged();
  }

  Future<void> _onLocaleChanged() async {
    // ko → "ko"
    // ja → "ja"
    // zh-CN → "zh_CN"
    final code = context.locale.toString();
    int newLang = 1;

    switch (code) {
      case 'ko':
        newLang = 1; // 한국어
        break;
      case 'ja':
        newLang = 2; // 일본어
        break;
      case 'zh_CN': // Flutter 내부에서 '-' 대신 '_' 사용됨
      case 'zh-CN':
        newLang = 3; // 중국어 (중국)
        break;
      case 'en':
        newLang = 4; // 영어
        break;
      case 'es':
        newLang = 5; // 스페인어
        break;
      default:
        newLang = 1;
    }

    setState(() => langNo = newLang);

    // 문항 재로드
    await _loadQuestions();
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ✅ 오디오 재생 함수
  Future<void> _playAudio(String? audioPath) async {
    if (audioPath == null || audioPath.isEmpty) {
      print('⚠️ 오디오 경로가 비어있습니다');
      return;
    }

    final audioUrl = ApiClient.getAudioUrl(audioPath);
    print('🎵 오디오 재생 시도: $audioUrl');

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(UrlSource(audioUrl));
      print('✅ 오디오 재생 성공');
    } catch (e) {
      print('❌ 오디오 재생 실패: $e');
      if (mounted) {
        showFooterSnackBar(context, "test.audio.error".tr());
      }
    }
  }

  // 언어 설정 + 문항 로드
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

  // 문항 로드
  Future<void> _loadQuestions() async {
    if (langNo == null) return;

    setState(() {
      loading = true;
      msg = "";
      items = [];
      idx = 0;
      subjective = "";
      feedback = null;
      _correctCount = 0; // 새 시험 시작 시 초기화
    });

    try {
      // [1] 문항 로드 - 모드 분기
      print("🎯 testMode = ${widget.testMode}");
      List<dynamic> list = [];

      if (widget.testMode == "INFINITE") {
        // 무한모드 : 완료한 studyNo가 나오는 문항
        print("♾️ 무한모드 문항 로드 시작");
        list = await _loadInfiniteItems();
        // testRound 0 설정 ( 무한모드는 회차 개념 없음 )
        setState(() {
          testRound = 0; // 회차 개념 없음
        });
      } else if (widget.testMode == "HARD") {
        // 하드모드 : 전체 문항
        print("🔥 하드모드 문항 로드 시작");
        list = await _loadHardItems();
        setState(() {
          testRound = 0;
        });
      } else {
        // 정기 시험
        print("📝 정기 시험 문항 로드 시작");

        // 다음 회차 조회
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
        msg = items.isEmpty ? "test.empty".tr() : "";
      });
    } catch (e, st) {
      print("_loadQuestions error: $e");
      print(st);
      setState(() {
        msg = "test.loadError".tr();
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
      "/saykorean/test/infinite-items",
      queryParameters: {
        "langNo": langNo,
        "studyNos": studyNos.join(','),
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
      "/saykorean/test/hard-items",
      queryParameters: {
        "langNo": langNo,
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
    if (testRound == null && widget.testMode == "REGULAR") return;

    final cur = items[idx] as Map<String, dynamic>;

    // ✅ 타입 판별
    int questionType;
    bool isSubjective;
    final bool isInfiniteHard =
        widget.testMode == "INFINITE" || widget.testMode == "HARD";
    final bool isRegular = !isInfiniteHard;


    if (widget.testMode == "INFINITE" || widget.testMode == "HARD") {
      // 무한/하드모드: 모두 객관식
      questionType = 0;
      isSubjective = false;
    } else {
      // 정기시험 - 백엔드와 동일 규칙: itemIndex % 3 로 타입 판별 (0/1 = 객관식, 2 = 주관식)
      questionType = idx % 3; // 0=그림객관식, 1=음성객관식, 2=주관식
      isSubjective = questionType == 2;
    }

    final body = {
      "testRound": testRound ?? 0,
      "selectedExamNo": selectedExamNo ?? 0,
      "userAnswer": selectedExamNo != null ? "" : subjective,
      "langNo": langNo,
      // userNo는 JWT/세션에서 AuthUtil이 처리
    };

    final testItemNo = cur['testItemNo'] ?? 0;
    final effectiveTestNo = widget.testNo; // 무한/하드모드일 때 0일 수도 있음

    final url = "/saykorean/test/$effectiveTestNo/items/$testItemNo/answer";

    // 🔹 주관식 → 로딩 페이지를 통해 채점
    if (isSubjective && selectedExamNo == null) {
      print("주관식 → /loading 페이지로 이동");
      if (!mounted) return;

      final result = await Navigator.pushNamed(
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
      ) as Map<String, dynamic>?;

      if (!mounted || result == null || result['ok'] != true) {
        setState(() {
          msg = "test.submitError".tr();
          feedback = {
            "correct": false,
            "score": 0,
          };
        });
        return;
      }

      final data = result['data'];

      int score = 0;
      bool isCorrect = false;

      if (data is Map) {
        final s = data["score"];
        if (s is num) score = s.toInt();

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

      if (isCorrect && widget.testMode == "REGULAR") {
        _correctCount++;
      }

      setState(() {
        feedback = {
          "correct": isCorrect,
          "score": score,
        };
      });

      return;
    }

    // 🔹 객관식 → 바로 제출
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

      if (isCorrect && widget.testMode == "REGULAR") {
        _correctCount++;
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
        msg = "test.submitError".tr();
        feedback = {
          "correct": false,
          "score": 0,
        };
      });
    } finally {
      setState(() => submitting = false);
    }
  }

  // 다음 문제 / 결과 페이지 이동
  void goNext() {
    // 무한/하드모드 : 한 문제라도 틀리면 종료
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
      // ✅ 마지막 문제까지 다 풀었을 때
      if (widget.testMode == "REGULAR") {
        Navigator.pushNamed(
          context,
          "/testresult",
          arguments: {
            "testNo": widget.testNo,
            "total": items.length,
            "correct": _correctCount,
          },
        );
      } else {
        // 무한/하드모드 : 모든 문제 정답 시
        _showVictoryDialog();
      }
    }
  }

  // 무한모드/하드모드 오답 시 종료 다이얼로그
  void _showGameOverDialog() {
    final count = idx + 1;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Text("test.gameover.title".tr()),
            content: Text(
              widget.testMode == "INFINITE"
                  ? "test.gameover.infinite".tr(args: ["$count"])
                  : "test.gameover.hard".tr(args: ["${idx + 1}"]),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // 다이얼로그 닫기
                  Navigator.pop(context); // 시험페이지 닫기
                },
                child: Text("common.confirm".tr()),
              ),
            ],
          ),
    );
  }

  // 무한모드/하드모드 모든 문제 정답 시 다이얼로그
  void _showVictoryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Text("test.result.perfect".tr()),
            content: Text(
              widget.testMode == "INFINITE"
                  ? "test.victory.infiniteAll".tr(args: ["${items.length}"])
                  : "test.victory.hardAll".tr(args: ["${items.length}"]),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text("common.confirm".tr()),
              ),
            ],
          ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 빌드
  // ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // 🔥 locale 변경 시 이 페이지도 자동으로 rebuild 되도록 강제 의존
    print("🔍 TESTPAGE locale = ${context.locale}");
    print("🔍 supportedLocales = ${context.supportedLocales}");
    print("🔍 delegates OK? = ${Localizations.of(context, WidgetsLocalizations)}");

    final _ = context.locale;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    final screenWidth = MediaQuery.of(context).size.width;

    final cur = (items.isNotEmpty) ? items[idx] as Map<String, dynamic> : null;

    // ✅ 타입 판별
    int questionType;
    bool isSubjective;
    final bool isInfiniteHard =
        widget.testMode == "INFINITE" || widget.testMode == "HARD";
    final bool isRegular = !isInfiniteHard;

    if (widget.testMode == "INFINITE" || widget.testMode == "HARD") {
      // 무한/하드모드: 모두 객관식
      questionType = 0;
      isSubjective = false;
    } else {
      // 정기시험: 순서 기반
      // 백엔드와 **동일 규칙**: itemIndex % 3 로 문항 타입 판별
      questionType = idx % 3; // 0=그림 객관식, 1=음성 객관식, 2=주관식
      isSubjective = questionType == 2;
    }

    final isMultiple = !isSubjective;

    // ✅ 무한/하드모드: 그림+음성 모두 표시
    final hasImage = _safeSrc(cur?['imagePath']) != null;
    final hasAudio =
        cur?['audios'] is List && (cur!['audios'] as List).isNotEmpty;

    print("🔍 문항 타입: idx=$idx, type=$questionType, "
        "image=$hasImage, audio=$hasAudio, subj=$isSubjective");

    // 상단 헤더 텍스트 (학습 / 시험 모드 스타일 통일)
    final String headerTitle;
    final String headerSubtitle;

    if (widget.testMode == "INFINITE") {
      headerTitle =  "exam.mode.infinite".tr();
      headerSubtitle = "test.header.infiniteSubtitle".tr();
    } else if (widget.testMode == "HARD") {
      headerTitle = "exam.mode.hard".tr();
      headerSubtitle = "test.header.hardSubtitle".tr();
    } else {
      headerTitle = "exam.today".tr();
      headerSubtitle = "test.header.regularSubtitle".tr();
    }

    final titleColor = theme.appBarTheme.foregroundColor ??
        (isDark ? scheme.onSurface : const Color(0xFF6B4E42));
    final subtitleColor = scheme.onSurface.withOpacity(0.7);
    final progressColor = scheme.onSurface.withOpacity(0.8);
    final cardColor = isDark ? scheme.surface : Colors.white;
    final cardBorderColor =
    isDark ? scheme.outline.withOpacity(0.4) : const Color(0xFFE5E7EB);
    final nextButtonBg = scheme.primaryContainer;
    final nextButtonFg = scheme.onPrimaryContainer;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          "footer.test".tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: loading
          ? Center(
        child: CircularProgressIndicator(
          color: scheme.primary,
        ),
      )
          : items.isEmpty
          ? FooterSafeArea(
        child: Center(
          child: Text(
            msg.isEmpty ? "exam.noQuestions".tr() : msg,
            style: TextStyle(color: subtitleColor),
          ),
        ),
      )
          : FooterSafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 🔥 상단 공통 헤더 (학습/시험모드와 톤 통일)
              SKPageHeader(
                title: headerTitle,
                subtitle: headerSubtitle,),
              const SizedBox(height: 18),

              // 진행도
              Text(
                "${idx + 1} / ${items.length}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: progressColor,
                ),
              ),
              const SizedBox(height: 8),

              // 문제 카드
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  border: Border.all(color: cardBorderColor),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isDark
                      ? const []
                      : [
                    BoxShadow(
                      color:
                      Colors.brown.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 질문 텍스트 (무한모드/하드모드에서는 안 나옴)
                    if (isRegular)
                      Text(
                        cur?['questionSelected'] ?? "",
                        style: TextStyle(
                          fontSize: 16,
                          color: scheme.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(height: 12),

                    // 그림
                    if ((isRegular &&
                        hasImage &&
                        questionType == 0) ||
                        (isInfiniteHard && hasImage))
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: screenWidth * 0.8,
                          child: AspectRatio(
                            aspectRatio: 3 / 3,
                            child: Image.network(
                              ApiClient.buildUrl(
                                _safeSrc(cur!['imagePath'])!,
                              ),
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                              Center(
                                child:
                                Text("exam.image.error".tr()),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // 오디오
                    if ((isRegular && hasAudio && questionType == 1) ||
                        (isInfiniteHard && hasAudio))
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final maxWidth = constraints.maxWidth;
                          // 한 줄에 2개씩 나란히 배치 (좌/우)
                          final itemWidth = (maxWidth - 12) / 2; // 가운데 여백 12

                          final audios = (cur!['audios'] as List);

                          return Wrap(
                            spacing: 12,       // 가로 간격
                            runSpacing: 8,     // 세로 간격
                            children: audios.where((audio) {
                              return _safeSrc(audio['audioPath']) != null;
                            }).map<Widget>((audio) {
                              return SizedBox(
                                width: itemWidth,
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _playAudio(audio['audioPath']);
                                  },
                                  icon: const Text('🔊'),
                                  label: Text("test.audio.play".tr()),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: titleColor,
                                    side: BorderSide(
                                      color: cardBorderColor,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                    // 주관식 예문
                    if (isSubjective &&
                        cur?['examSelected'] != null)
                      Container(
                        margin:
                        const EdgeInsets.only(top: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.surfaceVariant
                              .withOpacity(
                              isDark ? 0.6 : 0.4),
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                        child: Text(
                          cur!['examSelected'],
                          style: TextStyle(
                            fontSize: 15,
                            color: scheme.onSurface,
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
                  CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: feedback!['correct']
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      child: Text(
                        feedback!['correct']
                            ? "test.correct".tr()
                            : "test.wrong".tr(),
                        style: TextStyle(
                          color: feedback!['correct']
                              ? Colors
                              .green.shade900
                              : Colors.red.shade900,
                          fontWeight:
                          FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔥 공통 기본 버튼 사용 (테마/민트 자동 반영)
                    SKPrimaryButton(
                      label: idx < items.length - 1
                          ? "test.next".tr()
                          : "test.result.view".tr(),
                      onPressed: goNext,
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
  // ✅ 객관식: 한 줄에 버튼 하나씩, 가로 전체 폭 사용
  // ─────────────────────────────────────────────────────────────
  Widget _buildMultipleChoice(Map<String, dynamic>? cur) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleColor = theme.appBarTheme.foregroundColor ??
        const Color(0xFF6B4E42);

    final options = cur?['options'];
    final hasOptions = options is List && options.isNotEmpty;

    int? _toInt(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is String) return int.tryParse(v);
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "test.multiple.title".tr(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        const SizedBox(height: 8),

        if (hasOptions)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: (options as List).map<Widget>((opt) {
              final map = opt as Map<String, dynamic>;
              final label = map['examSelected'] ??
                  map['examKo'] ??
                  "test.options.loadError.short".tr();
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _ChoiceButton(
                  label: label.toString(),
                  onTap: feedback == null
                      ? () => submitAnswer(
                    selectedExamNo:
                    _toInt(map['examNo']),
                  )
                      : null,
                ),
              );
            }).toList(),
          )
        else
          Text("test.options.loadError.long".tr()),
      ],
    );
  }

  Widget _buildSubjective() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final titleColor = theme.appBarTheme.foregroundColor ??
        const Color(0xFF6B4E42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          "test.subjective.title".tr(),
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
          decoration: InputDecoration(
            hintText: "test.subjective.hint".tr(),
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: scheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // 공통 기본 버튼 사용 (themeColor 따라 자동 변경)
    SKPrimaryButton(
    label: "test.submit".tr(),
    onPressed: () {
    if (subjective.trim().isEmpty || submitting) return;
    submitAnswer();
    },
    ),
      ],
    );
  }
}

// 선택지 pill 버튼 – 한 줄에 하나씩, 가로 전체 폭
class _ChoiceButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ChoiceButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint';

    Color bg = const Color(0xFFFFF5ED);
    Color border = const Color(0xFFF4D6C4);
    Color fg = const Color(0xFF6B4E42);

    if (isMint && !isDark) {
      bg = const Color(0xFFF4FFFA);
      border = const Color(0xFFD3F8EA);
      fg = const Color(0xFF2F7A69);
    }

    if (isDark) {
      bg = scheme.surfaceContainer;
      border = scheme.outline.withOpacity(0.5);
      fg = scheme.onSurface;
    }

    return SizedBox(
      width: double.infinity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

// 공통으로 쓰면 좋은 객관식 버튼 빌더 (기존 것 – 필요 시 다른 페이지에서 사용)
Widget buildChoiceButton(
    BuildContext context,
    String text,
    VoidCallback? onTap,
    ) {
  final theme = Theme.of(context);
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  final borderColor =
  isDark ? scheme.outline.withOpacity(0.5) : const Color(0xFFE5E7EB);
  final fgColor =
  isDark ? scheme.onSurface : const Color(0xFF6B4E42); // 브라운 톤
  final bgColor = isDark ? scheme.surface : Colors.white;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: BorderSide(color: borderColor, width: 1.4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

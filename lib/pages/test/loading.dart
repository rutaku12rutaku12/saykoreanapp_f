
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api.dart'; // ApiClient.dio 사용

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  // 랜덤 슬라이드/문구 선택용
  late final Map<String, String> _slide;
  late final String _phrase;

  bool _started = false; // didChangeDependencies에서 한 번만 실행하기 위한 플래그

  @override
  void initState() {
    super.initState();

    final slides = <Map<String, String>>[
      {
        "img": "assets/img/loading_img/1_loading_img.png",
        "title": "숭례문",
        "desc": "조선의 정문이었던 남대문, 불타 올랐다가 다시 복원된 서울의 상징이에요."
      },
      {
        "img": "assets/img/loading_img/2_loading_img.png",
        "title": "북촌 한옥마을",
        "desc": "한옥과 골목길이 어우러진 서울의 전통 주거지, 산책하기 딱 좋아요."
      },
      {
        "img": "assets/img/loading_img/3_loading_img.png",
        "title": "국립고궁박물관",
        "desc": "조선 왕실의 유물과 역사를 만날 수 있는 박물관이에요."
      },
      {
        "img": "assets/img/loading_img/4_loading_img.png",
        "title": "무령왕릉",
        "desc": "백제의 무령왕과 왕비가 잠든 무덤, 찬란한 금제 유물이 유명해요."
      },
      {
        "img": "assets/img/loading_img/6_loading_img.png",
        "title": "광한루원",
        "desc": "춘향전의 배경이 된 누각, 전통 정원의 정취를 느낄 수 있어요."
      },
      {
        "img": "assets/img/loading_img/7_loading_img.png",
        "title": "한라산",
        "desc": "제주의 상징, 사계절마다 다른 풍경을 보여주는 높은 산이에요."
      },
    ];

    final phrases = <String>[
      "답안을 채점하는 중이에요...",
      "조금만 기다려 주세요. 열심히 평가하고 있어요!",
      "AI가 당신의 답을 꼼꼼히 확인하고 있어요.",
    ];

    final rnd = Random();
    _slide = slides[rnd.nextInt(slides.length)];
    _phrase = phrases[rnd.nextInt(phrases.length)];
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args == null) {
      print("LoadingPage: arguments 없음");
      return;
    }

    _runAction(args);
  }

  Future<void> _runAction(Map<String, dynamic> args) async {
    final action = args["action"];
    if (action != "submitAnswer") {
      print("LoadingPage: 지원하지 않는 action = $action");
      return;
    }

    final payload = args["payload"] as Map<String, dynamic>?;

    if (payload == null) {
      print("LoadingPage: payload 없음");
      return;
    }

    final String url = payload["url"] as String;
    final Map<String, dynamic> body =
    (payload["body"] as Map).cast<String, dynamic>();
    final int testNo = payload["testNo"] as int;
    final String? backTo = args["backTo"] as String?;

    print("LoadingPage: 채점 요청 시작");
    print("  URL  : $url");
    print("  body : $body");

    try {
      final res = await ApiClient.dio.post(url, data: body);
      print("LoadingPage: 응답 status = ${res.statusCode}");
      print("LoadingPage: 응답 data   = ${res.data}");

      // 결과 페이지로 이동 (React: /testresult/${testNo})
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        "/testresult/$testNo",
        arguments: {
          "result": res.data,
        },
      );
    } catch (e, st) {
      print("LoadingPage 에러: $e");
      print(st);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("채점 중 오류가 발생했어요. 다시 시도해 주세요.")),
      );

      // 실패 시 돌아갈 페이지 (기본: /home)
      Navigator.pushReplacementNamed(
        context,
        backTo ?? "/home",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: cream,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 16),
              // 상단 타이틀
              Text(
                _slide["title"] ?? "",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: brown,
                ),
              ),
              const SizedBox(height: 12),

              // 이미지 + 설명
              Expanded(
                child: Center(
                  child: Container(
                    width: 410,
                    // React: height: "75vh"
                    height: MediaQuery.of(context).size.height * 0.6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // 배경 이미지
                        Image.asset(
                          _slide["img"] ?? "",
                          fit: BoxFit.cover,
                        ),

                        // 이미지 위 텍스트
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                            ),
                            child: Text(
                              _slide["desc"] ?? "",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 하단 문구 + 로딩 인디케이터
              Padding(
                padding: const EdgeInsets.only(bottom: 32, top: 8),
                child: Column(
                  children: [
                    const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: brown,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _phrase,
                      style: const TextStyle(
                        color: Color(0xFF9C7C68),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

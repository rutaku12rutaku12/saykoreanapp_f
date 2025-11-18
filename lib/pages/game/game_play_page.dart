// lib/pages/game_play_page.dart


import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/game_api.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GamePlayPage extends StatefulWidget {
  final int gameNo;
  final String gameTitle;

  GamePlayPage({
    required this.gameNo,
    required this.gameTitle,
});

  @override
  _GamePlayPageState createState() => _GamePlayPageState();
}

class _GamePlayPageState extends State<GamePlayPage> {
  late final WebViewController controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // 하드웨어 가속 활성화
      ..setBackgroundColor(Colors.transparent)
      // 캐시 설정 - 더 빠른 로딩
      ..clearCache()
      // 네비게이션 델리케이드
      ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              print('🔄 페이지 로딩 시작: $url');
            },
              onPageFinished: (String url) {
                print('✅ 페이지 로딩 완료: $url');
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                  });
                }
              },
              onWebResourceError: (WebResourceError e) {
                print('❌ 웹뷰 에러: ${e.description}');
                if (mounted) {
                  setState(() {
                    _errorMessage = '게임을 불러오는데 실패했습니다.';
                    _isLoading = false;
                  });
                }
              },
          ),
      )

      // ✅ JavaScript 채널 추가 - Flutter로 게임 결과 전송
      ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            print('📨 게임에서 메시지 수신: ${message.message}');
            _handleGameResult(message.message);
          },
      )

      // ✅ 게임 HTML 로드
      ..loadFlutterAsset(_getGameAssetPath());

  }

  // 게임 번호에 따라 asset 경로 반환
  String _getGameAssetPath() {
    switch (widget.gameNo) {
      case 1:
        return 'assets/game/receive/game.html';     // 토돌이 한글 받기
      case 2:
        return 'assets/game/watermelon/index.html'; // 한글 수박게임
      default:
        return 'assets/game/receive/game.html';
    }

  }
  
  //게임 결과 처리
  Future<void> _handleGameResult(String message) async {
    try {
      // JSON 파싱
      final data = jsonDecode(message);
      final int gameNo = data['gameNo'] ?? widget.gameNo;
      final int gameScore = data['gameScore'] ?? 0;
      final int gameResult = data['gameResult'] ?? 0;

      print('🎮 게임 결과 파싱 완료:');
      print('   - gameNo: $gameNo');
      print('   - gameScore: $gameScore');
      print('   - gameResult: $gameResult');
      
      // 서버에 게임 기록 저장
      await GameApi.createGameLog(
          gameNo: gameNo,
          gameResult: gameResult, 
          gameScore: gameScore
      );

      print('✅ 게임 기록 저장 완료');
      
      // 결과 다이얼로그 표시
      if (mounted) {
        _showResultDialog(gameScore, gameResult);
      }
      
    } catch (e) {
      print('게임 결과 처리 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('게임 결과 저장에 실패했습니다: $e'),
          backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 결과 다이얼로그 표시
  void _showResultDialog(int score, int result) {
    String resultText = result == 2
        ? '🏆 대성공!'
        : result == 1
        ? '✨ 성공!'
        : '💪 도전!';

    String resultEmoji = result == 2
        ? '🎉'
        : result == 1
        ? '👍'
        : '💪';

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                resultEmoji,
                style: TextStyle(fontSize: 40),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  resultText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFAAA5),
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '최종 점수',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF999999),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              SizedBox(height: 16),
              Text(
                '게임 기록이 저장되었습니다!',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 게임 페이지 닫기
              },
              child: Text(
                '확인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFAAA5),
                ),
              ),
            ),
          ],
        ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gameTitle,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        backgroundColor: Color(0xFFFFF9F0),
        elevation: 0,
        iconTheme: IconThemeData(color: Color(0xFF333333)),
      ),
      body: Stack(
        children: [
          // ✅ 웹뷰
          if (_errorMessage == null)
            WebViewWidget(controller: controller)
          else
          // ✅ 에러 화면
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: TextStyle(fontSize: 16, color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _initializeWebView();
                    },
                    child: Text('다시 시도'),
                  ),
                ],
              ),
            ),

          // ✅ 로딩 인디케이터
          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Color(0xFFFFAAA5),
                    ),
                    SizedBox(height: 16),
                    Text(
                      '게임을 불러오는 중...',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 웹뷰 리소스 정리
    super.dispose();
  }
}
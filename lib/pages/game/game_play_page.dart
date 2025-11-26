// lib/pages/game/game_play_page.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/game_api.dart';
import 'package:webview_flutter/webview_flutter.dart';

class GamePlayPage extends StatefulWidget {
  final int gameNo;
  final String gameTitle;

  const GamePlayPage({
    super.key,
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
      ..setBackgroundColor(Colors.transparent)
      ..clearCache()
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // ignore: avoid_print
            print('🔄 페이지 로딩 시작: $url');
          },
          onPageFinished: (String url) {
            // ignore: avoid_print
            print('✅ 페이지 로딩 완료: $url');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError e) {
            // ignore: avoid_print
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
          // ignore: avoid_print
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
        return 'assets/game/receive/game.html'; // 토돌이 한글 받기
      case 2:
        return 'assets/game/watermelon/index.html'; // 한글 수박게임
      default:
        return 'assets/game/receive/game.html';
    }
  }

  // 게임 결과 처리
  Future<void> _handleGameResult(String message) async {
    try {
      final data = jsonDecode(message);
      final int gameNo = data['gameNo'] ?? widget.gameNo;
      final int gameScore = data['gameScore'] ?? 0;
      final int gameResult = data['gameResult'] ?? 0;

      // ignore: avoid_print
      print('🎮 게임 결과 파싱 완료: gameNo=$gameNo, score=$gameScore, result=$gameResult');

      await GameApi.createGameLog(
        gameNo: gameNo,
        gameResult: gameResult,
        gameScore: gameScore,
      );

      // ignore: avoid_print
      print('✅ 게임 기록 저장 완료');

      if (mounted) {
        _showResultDialog(gameScore, gameResult);
      }
    } catch (e) {
      // ignore: avoid_print
      print('게임 결과 처리 실패: $e');
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('게임 결과 저장에 실패했습니다: $e'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  // 결과 다이얼로그 표시 (테마 색상 반영)
  void _showResultDialog(int score, int result) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              resultEmoji,
              style: const TextStyle(fontSize: 40),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                resultText,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
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
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$score',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '게임 기록이 저장되었습니다!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                Navigator.of(context).pop(); // 게임 페이지 닫기
              },
              child: Text(
                '확인',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.secondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.gameTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      backgroundColor: bg,
      // ✅ 푸터 영역만큼 bottom padding 추가
      body: Padding(
        padding: const EdgeInsets.only(bottom: 88.0), // 76 (footer) + 12 (margin)
        child: Stack(
          children: [
            if (_errorMessage == null)
              WebViewWidget(controller: controller)
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: scheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: scheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _errorMessage = null;
                              _isLoading = true;
                            });
                            _initializeWebView();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: scheme.primary,
                            foregroundColor: scheme.onPrimary,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('다시 시도'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_isLoading)
              Container(
                color: isDark
                    ? Colors.black.withOpacity(0.5)
                    : bg.withOpacity(0.8),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: scheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '게임을 불러오는 중...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 16,
                          color: scheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io'; // 🔥 추가

// JWT → payload 추출
Map<String, dynamic> _decodeJwt(String token) {
  final parts = token.split('.');
  final payload = base64Url.normalize(parts[1]);
  return json.decode(utf8.decode(base64Url.decode(payload)));
}

class SocialLoginWebView extends StatefulWidget {
  final String loginUrl; // 구글/카카오 URL

  const SocialLoginWebView({
    super.key,
    required this.loginUrl,
  });

  @override
  State<SocialLoginWebView> createState() => _SocialLoginWebViewState();
}

class _SocialLoginWebViewState extends State<SocialLoginWebView> {

  // 세션으로 JWT 받아오기
  Future<void> getTokenWithSession(String sessionId) async {
    try {
      final response = await ApiClient.dio.get(
        '/saykorean/oauth2/mobile/token',
        options: Options(
          headers: {
            'Cookie': 'JSESSIONID=$sessionId',
          },
          validateStatus: (status) => status! < 600,
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data['token'] != null) {

        final token = response.data['token'];
        final userNo = response.data['userNo'];

        // SharedPreferences에 저장
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString());
        await prefs.setInt('myUserNo', userNo);

        // 출석 체크
        await onAttend(userNo);

        // 홈으로 이동
        Navigator.pushReplacementNamed(context, '/home');

        Fluttertoast.showToast(
            msg: "로그인 성공!",
            backgroundColor: Colors.greenAccent
        );
      } else {
        Fluttertoast.showToast(
            msg: "소셜 로그인에 실패했습니다.",
            backgroundColor: Colors.red
        );
        Navigator.pop(context);
      }
    } catch (e) {
      print("토큰 가져오기 오류: $e");
      Fluttertoast.showToast(
          msg: "로그인 처리 중 오류가 발생했습니다.",
          backgroundColor: Colors.red
      );
      Navigator.pop(context);
    }
  }

  // 출석 메소드
  Future<void> onAttend(userNo) async {
    try {
      final sendData = {"userNo": userNo};
      final response = await ApiClient.dio.post(
        '/saykorean/attend',
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null && response.data == 1) {
        Fluttertoast.showToast(
            msg: "출석이 완료되었습니다.",
            backgroundColor: Colors.greenAccent
        );
      } else if (response.statusCode == 222) {
        Fluttertoast.showToast(
            msg: "이미 출석이 완료되었습니다.",
            backgroundColor: Colors.orange
        );
      }
    } catch (e) {
      print("출석 체크 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 WebView에서만 localhost → 10.0.2.2 변환
    String webViewUrl = widget.loginUrl;
    if (Platform.isAndroid) {
      webViewUrl = webViewUrl.replaceAll('localhost', '10.0.2.2');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("소셜 로그인"),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(webViewUrl), // 변환된 URL 사용
        ),
        initialSettings: InAppWebViewSettings(
          userAgent: 'Flutter App', // 플러터 앱임을 표시
        ),
        onLoadStart: (controller, url) async {
          final current = url.toString();
          print("현재 URL: $current");

          // 🔥 커스텀 스킴 감지
          // saykoreanapp://login?session=xxx
          if (current.startsWith("saykoreanapp://login")) {
            final uri = Uri.parse(current);
            final sessionId = uri.queryParameters["session"];
            final error = uri.queryParameters["error"];

            if (error != null) {
              String errorMsg = "로그인에 실패했습니다.";
              if (error == "email_required") {
                errorMsg = "이메일 정보가 필요합니다.";
              } else if (error == "email_exists") {
                errorMsg = "이미 가입된 이메일입니다.";
              }

              Fluttertoast.showToast(
                  msg: errorMsg,
                  backgroundColor: Colors.red
              );
              Navigator.pop(context);
              return;
            }

            if (sessionId != null && sessionId.isNotEmpty) {
              print("Session ID 받음: $sessionId");
              await getTokenWithSession(sessionId);
            }
          }
        },
        onLoadError: (controller, url, code, message) {
          print("WebView 로드 에러: $message");
        },
      ),
    );
  }
}
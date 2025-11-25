// lib/pages/auth/login_page.dart

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';
// (소셜 로그인 다시 쓸 거면 아래 import 주석 해제해서 사용하면 됨)
// import 'package:saykoreanapp_f/pages/auth/social_login_webview.dart';

/// JWT → payload 추출
Map<String, dynamic> _decodeJwt(String token) {
  final parts = token.split('.');
  final payload = base64Url.normalize(parts[1]);
  return json.decode(utf8.decode(base64Url.decode(payload)));
}

// ─────────────────────────────────────────────────────────────
// 로그인 페이지
// ─────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginState();
}

class _LoginState extends State<LoginPage> {
  // 입력 컨트롤러
  final TextEditingController emailCon = TextEditingController();
  final TextEditingController pwdCont = TextEditingController();

  @override
  void dispose() {
    emailCon.dispose();
    pwdCont.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────────────────────────
  // 로그인 메소드
  // ───────────────────────────────────────────────────────────
  Future<void> onLogin() async {
    print("onLogin.exe");

    try {
      final sendData = {
        "email": emailCon.text.trim(),
        "password": pwdCont.text,
      };
      print(sendData);

      final response = await ApiClient.dio.post(
        '/saykorean/login',
        data: sendData,
        options: Options(
          headers: {'Content-Type': 'application/json'},
          validateStatus: (status) {
            // 500 에러도 받아서 확인
            return status! < 600;
          },
        ),
      );

      print("응답 상태: ${response.statusCode}");
      print("응답 데이터: ${response.data}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data != '') {
        final token = response.data['token'];

        // 1) JWT → userNo 추출
        final decoded = _decodeJwt(token);
        final userNo = decoded['userNo'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString());
        await prefs.setInt('myUserNo', userNo);

        if (!mounted) return;

        // 홈으로 이동
        Navigator.pushReplacementNamed(context, '/home');

        // 출석 체크
        await onAttend(userNo);
      } else {
        print("로그인 실패: ${response.statusCode}");
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("로그인 오류 : $e");
      if (e is DioException) {
        print("응답 데이터: ${e.response?.data}");
        print("상태 코드: ${e.response?.statusCode}");
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 중 오류가 발생했습니다.')),
      );
    }
  }

  // 출석 메소드
  Future<void> onAttend(int userNo) async {
    try {
      final sendData = {"userNo": userNo};
      print(sendData);

      final response = await ApiClient.dio.post(
        '/saykorean/attend',
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data == 1) {
        Fluttertoast.showToast(
          msg: "출석이 완료되었습니다.",
          backgroundColor: Colors.greenAccent,
        );
      } else if (response.statusCode == 222) {
        Fluttertoast.showToast(
          msg: "이미 출석이 완료되었습니다.",
          backgroundColor: Colors.red,
        );
      } else {
        Fluttertoast.showToast(
          msg: "출석 체크 중 오류가 발생하였습니다.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // ───────────────────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "로그인",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SKPageHeader(
                title: '다시 만나 반가워요!',
                subtitle: '등록한 이메일과 비밀번호로 로그인해 주세요.',
              ),
              const SizedBox(height: 24),

              // 이메일 / 비밀번호 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '이메일 로그인',
                description: 'SayKorean 계정으로 바로 로그인할 수 있어요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: emailCon,
                      label: '이메일',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: pwdCont,
                      label: '비밀번호',
                      obscure: true,
                    ),
                    const SizedBox(height: 16),
                    SKPrimaryButton(
                      label: "login.button".tr(),
                      onPressed: onLogin,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 회원/찾기 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '도움이 필요하신가요?',
                description: '계정이 없거나 비밀번호를 잊어버리셨나요?',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          // 🔥 이름 기반 라우트로 이동
                          Navigator.pushReplacementNamed(context, '/find');
                        },
                        child: Text("login.find".tr()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 44,
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/signup');
                        },
                        child: Text("signup.signup".tr()),
                      ),
                    ),
                  ],
                ),
              ),

              // 소셜 로그인 영역 (필요하면 다시 활성화)
              // const SizedBox(height: 24),
              // _buildCard(
              //   theme: theme,
              //   scheme: scheme,
              //   title: '간편 로그인',
              //   description: '카카오, 구글 계정으로 빠르게 로그인해요.',
              //   child: Column(
              //     crossAxisAlignment: CrossAxisAlignment.stretch,
              //     children: [
              //       SizedBox(
              //         height: 44,
              //         child: OutlinedButton(
              //           onPressed: () {
              //             Navigator.push(
              //               context,
              //               MaterialPageRoute(
              //                 builder: (_) => SocialLoginWebView(
              //                   loginUrl:
              //                       "http://10.0.2.2:8080/oauth2/authorization/kakao",
              //                 ),
              //               ),
              //             );
              //           },
              //           child: const Text("카카오 로그인"),
              //         ),
              //       ),
              //       const SizedBox(height: 10),
              //       SizedBox(
              //         height: 44,
              //         child: OutlinedButton(
              //           onPressed: () {
              //             Navigator.push(
              //               context,
              //               MaterialPageRoute(
              //                 builder: (_) => SocialLoginWebView(
              //                   loginUrl:
              //                       "http://10.0.2.2:8080/oauth2/authorization/google",
              //                 ),
              //               ),
              //             );
              //           },
              //           child: const Text("구글 로그인"),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  // 공통 카드 UI
  Widget _buildCard({
    required ThemeData theme,
    required ColorScheme scheme,
    required String title,
    required String description,
    required Widget child,
  }) {
    final cardColor = scheme.surface;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: scheme.outline.withOpacity(0.15),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  // 공통 TextField
  Widget _buildTextField({
    required ThemeData theme,
    required ColorScheme scheme,
    required TextEditingController controller,
    required String label,
    bool obscure = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: scheme.onSurface.withOpacity(0.7),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: scheme.primary,
            width: 1.5,
          ),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
    );
  }
}

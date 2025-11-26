// lib/pages/auth/signup_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';

import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/utils/recaptcha_manager.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SignupState();
  }
}

class _SignupState extends State<SignupPage> {
  // 컨트롤러들
  final TextEditingController nameCon = TextEditingController();
  final TextEditingController emailCon = TextEditingController();
  final TextEditingController passwordCon = TextEditingController();
  final TextEditingController passwordCon2 = TextEditingController();
  final TextEditingController nickNameCon = TextEditingController();
  final TextEditingController phoneCon = TextEditingController();

  // 중복검사 상태
  bool emailCheck = false;
  bool phoneCheck = false;

  // 서버 전송용 국제번호
  PhoneNumber? emailPhoneNumber;

  @override
  void dispose() {
    nameCon.dispose();
    emailCon.dispose();
    passwordCon.dispose();
    passwordCon2.dispose();
    nickNameCon.dispose();
    phoneCon.dispose();
    super.dispose();
  }

  // 회원가입
  Future<void> onSignup() async {
    // 기본 유효성 검사
    if (nameCon.text.trim().isEmpty ||
        emailCon.text.trim().isEmpty ||
        passwordCon.text.trim().isEmpty ||
        passwordCon2.text.trim().isEmpty ||
        nickNameCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "입력값을 채워주세요.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (passwordCon.text != passwordCon2.text) {
      Fluttertoast.showToast(
        msg: "비밀번호가 일치하지 않습니다.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (passwordCon.text.length < 8 || passwordCon2.text.length < 8) {
      Fluttertoast.showToast(
        msg: "8자 이상 비밀번호를 입력해주세요.",
        backgroundColor: Colors.red,
      );
      return;
    }

    if (!emailCheck || !phoneCheck) {
      Fluttertoast.showToast(
        msg: "중복 확인을 모두 해주세요.",
        backgroundColor: Colors.red,
      );
      return;
    }

    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    String recaptchaToken = '';

    try {
      // reCAPTCHA 토큰 발급
      recaptchaToken =
      await RecaptchaManager.getClient().execute(RecaptchaAction.SIGNUP());
      // ignore: avoid_print
      print('reCAPTCHA Token: $recaptchaToken');
    } catch (e) {
      Navigator.pop(context); // 로딩 닫기
      Fluttertoast.showToast(
        msg: "보안 검증 실패. 다시 시도해 주세요. [$e]",
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      // ignore: avoid_print
      print('reCAPTCHA execution error: $e');
      return;
    }

    final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;

    final sendData = {
      'name': nameCon.text.trim(),
      'email': emailCon.text.trim(),
      'password': passwordCon.text,
      'nickName': nickNameCon.text.trim(),
      'phone': plusPhone.trim(),
      // 'recaptcha': recaptchaToken,
    };

    // ignore: avoid_print
    print(sendData);

    try {
      final response =
      await ApiClient.dio.post("/saykorean/signup", data: sendData);
      final data = response.data;

      Navigator.pop(context); // 로딩 닫기

      if (data == true) {
        // ignore: avoid_print
        print("회원가입 성공");

        Fluttertoast.showToast(
          msg: "회원가입 성공 했습니다.",
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          timeInSecForIosWeb: 10,
          backgroundColor: const Color(0xFFA8E6CF),
          textColor: const Color(0xFF6B4E42),
          fontSize: 16,
        );

        // 로그인 페이지로 교체 이동
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        // ignore: avoid_print
        print("회원가입 실패");
        Fluttertoast.showToast(
          msg: "회원가입 실패",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Navigator.pop(context); // 에러 시 로딩 닫기
      // ignore: avoid_print
      print(e);
      Fluttertoast.showToast(
        msg: "서버 통신 오류가 발생했습니다.",
        backgroundColor: Colors.red,
      );
    }
  }

  // 이메일 중복 확인
  Future<void> checkEmail() async {
    try {
      final response = await ApiClient.dio.get(
        "/saykorean/checkemail",
        options: Options(
          validateStatus: (status) => true,
        ),
        queryParameters: {'email': emailCon.text.trim()},
      );
      // ignore: avoid_print
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data == 0) {
        setState(() => emailCheck = true);
        Fluttertoast.showToast(
          msg: "이메일 사용이 가능합니다.",
          backgroundColor: Colors.greenAccent,
        );
      } else {
        Fluttertoast.showToast(
          msg: "이메일 형식이 올바르지 않거나, 사용 중인 이메일입니다.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 전화번호 중복 확인
  Future<void> checkPhone() async {
    try {
      final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
      final response = await ApiClient.dio.get(
        "/saykorean/checkphone",
        options: Options(
          validateStatus: (status) => true,
        ),
        queryParameters: {'phone': plusPhone.trim()},
      );
      // ignore: avoid_print
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data == 0) {
        setState(() => phoneCheck = true);
        Fluttertoast.showToast(
          msg: "전화번호 사용이 가능합니다.",
          backgroundColor: Colors.greenAccent,
        );
      } else {
        Fluttertoast.showToast(
          msg: "전화번호 형식이 올바르지 않거나, 사용 중인 전화번호입니다.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // ───────────────── UI ─────────────────
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
          "회원가입",
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
                title: '새 계정 만들기',
                subtitle: '필수 정보를 입력하고 SayKorean에 가입해 보세요.',
              ),
              const SizedBox(height: 24),

              // 기본 정보 카드 (이름, 이메일, 닉네임)
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '기본 정보',
                description: '로그인과 프로필에 사용될 기본 정보를 입력하세요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: nameCon,
                      label: '이름',
                    ),
                    const SizedBox(height: 12),

                    // 이메일 + 중복확인
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            theme: theme,
                            scheme: scheme,
                            controller: emailCon,
                            label: '이메일',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: checkEmail,
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(
                                color: scheme.primary,
                                width: 1.2,
                              ),
                              foregroundColor: scheme.primary,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('중복 확인'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: nickNameCon,
                      label: '닉네임',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 보안 정보 카드 (비밀번호, 전화번호, 회원가입 버튼)
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '보안 정보',
                description: '비밀번호와 연락처는 안전하게 암호화되어 저장됩니다.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: passwordCon,
                      label: '비밀번호 (8자 이상)',
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: passwordCon2,
                      label: '비밀번호 확인',
                      obscure: true,
                    ),
                    const SizedBox(height: 12),

                    // 전화번호 + 중복확인
                    Row(
                      children: [
                        Expanded(
                          child: _buildPhoneField(
                            theme: theme,
                            scheme: scheme,
                            controller: phoneCon,
                            onChanged: (phone) {
                              emailPhoneNumber = phone;
                              // ignore: avoid_print
                              print("입력한 번호: ${phone.completeNumber}");
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: checkPhone,
                            style: OutlinedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                              side: BorderSide(
                                color: scheme.primary,
                                width: 1.2,
                              ),
                              foregroundColor: scheme.primary,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            child: const Text('중복 확인'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Text(
                      '가입 버튼을 누르면 보안 검증(reCAPTCHA)이 자동으로 실행됩니다.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // ✅ 공통 Primary 버튼 사용 (테마 컬러 자동 대응)
                    SKPrimaryButton(
                      label: "회원가입",
                      onPressed: onSignup,
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

  // 공통 카드 UI (항상 흰 카드 / 다크에서는 surface)
  Widget _buildCard({
    required ThemeData theme,
    required ColorScheme scheme,
    required String title,
    required String description,
    required Widget child,
  }) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.zero,
      elevation: theme.cardTheme.elevation ?? 2,
      shape: theme.cardTheme.shape ??
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
      color: isDark ? scheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
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

  // 공통 IntlPhoneField
  Widget _buildPhoneField({
    required ThemeData theme,
    required ColorScheme scheme,
    required TextEditingController controller,
    required Function(PhoneNumber) onChanged,
  }) {
    return IntlPhoneField(
      controller: controller,
      initialCountryCode: 'KR',
      autovalidateMode: AutovalidateMode.disabled,
      validator: (value) => null,
      decoration: InputDecoration(
        labelText: '전화번호',
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
      onChanged: onChanged,
    );
  }
}

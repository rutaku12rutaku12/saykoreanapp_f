// lib/pages/setting/my_info_update_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ 공통 UI (헤더/버튼)

// ─────────────────────────────────────────────────────────────
// 내 정보 수정 페이지
// ─────────────────────────────────────────────────────────────

class MyInfoUpdatePage extends StatefulWidget {
  const MyInfoUpdatePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _InfoUpdateState();
  }
}

class _InfoUpdateState extends State<MyInfoUpdatePage> {
  // 입력 컨트롤러
  final TextEditingController nameCon = TextEditingController();
  final TextEditingController nickCon = TextEditingController();
  final TextEditingController phoneCon = TextEditingController();

  final TextEditingController currentPassCon = TextEditingController();
  final TextEditingController newPassCon = TextEditingController();
  final TextEditingController checkPassCon = TextEditingController();

  // 중복검사 상태
  bool phoneCheck = false;

  // 서버 전송용 국제번호
  PhoneNumber? emailPhoneNumber;

  // 원래 전화번호 저장 (+82 포함)
  String originalPhone = "";

  @override
  void initState() {
    super.initState();
    loadUserInfo(); // 기존 값 자동 세팅
  }

  @override
  void dispose() {
    nameCon.dispose();
    nickCon.dispose();
    phoneCon.dispose();
    currentPassCon.dispose();
    newPassCon.dispose();
    checkPassCon.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // 팝업 / API 호출 메소드
  // ─────────────────────────────────────────────────────────────

  // 탈퇴용 비밀번호 입력 팝업
  Future<String?> showPasswordPrompt() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("정말 탈퇴하시겠습니까?"),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              hintText: "비밀번호를 입력해주세요.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("취소"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  // 전화번호 중복 확인
  void checkPhone() async {
    try {
      final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
      final response = await ApiClient.dio.get(
        "/saykorean/checkphone",
        options: Options(
          validateStatus: (status) => true,
        ),
        queryParameters: {'phone': plusPhone},
      );
      // ignore: avoid_print
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");
      if (response.statusCode == 200 &&
          response.data != null &&
          response.data == 0) {
        setState(() {
          phoneCheck = true;
        });
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

  // 사용자 기본 정보 수정
  void updateUserInfo() async {
    if (nameCon.text.trim().isEmpty ||
        nickCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "입력값을 채워주세요.",
        backgroundColor: Colors.red,
      );
      // ignore: avoid_print
      print("입력값을 채워주세요.");
      return;
    }
    try {
      final plusPhone =
          emailPhoneNumber?.completeNumber ?? "+82${phoneCon.text}";
      final bool isPhoneChanged = (originalPhone != plusPhone);

      // ignore: avoid_print
      print("원래 번호: $originalPhone");
      // ignore: avoid_print
      print("현재 번호: $plusPhone");
      // ignore: avoid_print
      print("변경 여부: $isPhoneChanged");

      if (isPhoneChanged && !phoneCheck) {
        Fluttertoast.showToast(
          msg: "전화번호 중복 확인을 해주세요.",
          backgroundColor: Colors.red,
        );
        return;
      }

      final sendData = {
        "name": nameCon.text,
        "nickName": nickCon.text,
        "phone": plusPhone,
      };
      // ignore: avoid_print
      print(sendData);

      final response = await ApiClient.dio.put(
        "/saykorean/updateuserinfo",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      // ignore: avoid_print
      print(response);
      // ignore: avoid_print
      print(response.data);

      if (response.statusCode == 200 &&
          response.data != null &&
          response.data == 1) {
        Fluttertoast.showToast(
          msg: "수정이 완료되었습니다.",
          backgroundColor: Colors.greenAccent,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPage()),
        );
      } else {
        Fluttertoast.showToast(
          msg: "수정이 실패했습니다. 올바른 값을 입력해주세요.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 비밀번호 수정
  void updatePwrd() async {
    if (currentPassCon.text.trim().isEmpty ||
        newPassCon.text.trim().isEmpty ||
        checkPassCon.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "입력값을 채워주세요.",
        backgroundColor: Colors.red,
      );
      // ignore: avoid_print
      print("입력값을 채워주세요.");
      return;
    }
    if (newPassCon.text != checkPassCon.text) {
      // ignore: avoid_print
      print(
          "비밀번호 불일치 , 새 비밀번호: ${newPassCon.text}, 비밀번호 확인: ${checkPassCon.text} ");
      Fluttertoast.showToast(
        msg: "비밀번호가 일치하지 않습니다.",
        backgroundColor: Colors.red,
      );
      return;
    }
    if (newPassCon.text.length < 8 || checkPassCon.text.length < 8) {
      Fluttertoast.showToast(
        msg: "8자 이상 비밀번호를 입력해주세요.",
        backgroundColor: Colors.red,
      );
      return;
    }
    try {
      final sendData = {
        "currentPassword": currentPassCon.text,
        "newPassword": newPassCon.text,
      };
      final response = await ApiClient.dio.put(
        "/saykorean/updatepwrd",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      // ignore: avoid_print
      print(response);
      // ignore: avoid_print
      print(response.data);

      if (response.statusCode == 200 && response.data != null) {
        Fluttertoast.showToast(
          msg: "수정이 완료되었습니다.",
          backgroundColor: Colors.greenAccent,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPage()),
        );
      } else {
        Fluttertoast.showToast(
          msg: "수정이 실패했습니다. 올바른 값을 입력해주세요.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 회원 탈퇴
  void deleteUserStatus() async {
    try {
      final inputPassword = await showPasswordPrompt();

      if (inputPassword == null || inputPassword.trim().isEmpty) {
        Fluttertoast.showToast(
          msg: "취소되었습니다.",
          backgroundColor: Colors.red,
        );
        return;
      }

      final response = await ApiClient.dio.put(
        "/saykorean/deleteuser",
        data: {"password": inputPassword},
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      // ignore: avoid_print
      print("탈퇴 성공 시 1 반환: ${response.data}");

      if (response.statusCode == 200 && response.data == 1) {
        Fluttertoast.showToast(
          msg: "회원 탈퇴가 완료되었습니다.",
          backgroundColor: Colors.greenAccent,
        );
        _logOut(); // 탈퇴 후 로그아웃
      } else {
        Fluttertoast.showToast(
          msg: "비밀번호가 올바르지 않습니다.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 로그아웃
  void _logOut() async {
    try {
      await ApiClient.dio.get(
        '/saykorean/logout',
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
      await prefs.remove('myUserNo');

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // 수정 입력값 기존값 불러오기
  void loadUserInfo() async {
    try {
      final response = await ApiClient.dio.get(
        "/saykorean/info",
        options: Options(
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;

        setState(() {
          nameCon.text = data["name"] ?? "";
          nickCon.text = data["nickName"] ?? "";

          String phone = data["phone"] ?? "";
          if (phone.startsWith("+82")) {
            phone = phone.substring(3);
          } else if (phone.startsWith("82")) {
            phone = phone.substring(2);
          }
          phoneCon.text = phone;
          originalPhone = data["phone"] ?? "";
        });
      }
    } catch (e) {
      // ignore: avoid_print
      print(e);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────

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
          "내 정보",
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
                title: '내 정보 관리',
                subtitle: '닉네임과 연락처, 비밀번호를 변경할 수 있어요.',
              ),
              const SizedBox(height: 24),

              // 섹션 1: 기본 정보 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '기본 정보',
                description: '닉네임과 전화번호를 수정할 수 있어요.',
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
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: nickCon,
                      label: '닉네임',
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneField(theme, scheme),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: checkPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("전화번호 중복 확인"),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updateUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("정보 수정"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 섹션 2: 비밀번호 변경 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '비밀번호 변경',
                description: '현재 비밀번호를 확인한 후 새 비밀번호를 설정해 주세요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: currentPassCon,
                      label: '기존 비밀번호',
                      obscure: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: newPassCon,
                      label: '새 비밀번호 (8자 이상)',
                      obscure: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: checkPassCon,
                      label: '새 비밀번호 확인',
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updatePwrd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: scheme.primary,
                          foregroundColor: scheme.onPrimary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("비밀번호 수정"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 섹션 3: 회원 탈퇴 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '회원 탈퇴',
                description: '탈퇴 시 계정 정보와 포인트, 랭킹 기록 등이 삭제될 수 있어요.',
                accentColor: scheme.error,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "탈퇴 후에는 일부 데이터를 복구할 수 없습니다.",
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SKPrimaryButton(
                      label: '회원 탈퇴',
                      onPressed: deleteUserStatus,
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

  // ─────────────────────────────────────────────────────────────
  // 공통 위젯
  // ─────────────────────────────────────────────────────────────

  Widget _buildCard({
    required ThemeData theme,
    required ColorScheme scheme,
    required String title,
    required String description,
    Color? accentColor,
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
                color: accentColor ?? scheme.primary,
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

  Widget _buildPhoneField(ThemeData theme, ColorScheme scheme) {
    return IntlPhoneField(
      controller: phoneCon,
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
      onChanged: (phone) {
        emailPhoneNumber = phone;
        phoneCheck = false;
        // ignore: avoid_print
        print("입력한 번호: ${phone.number}");
      },
    );
  }
}

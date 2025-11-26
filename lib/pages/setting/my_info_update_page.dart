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
import 'package:easy_localization/easy_localization.dart';

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
          title: Text("mypage.delete.confirmTitle".tr()),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: InputDecoration(
              hintText: "mypage.delete.passwordHint".tr(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("common.cancel".tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: Text("common.confirm".tr()),
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
          msg: "signuppage.ablePhone".tr(),
          backgroundColor: Colors.greenAccent,
        );
      } else {
        Fluttertoast.showToast(
          msg: "signuppage.phoneFormatOrUsed".tr(),
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
        msg: "common.fillRequired".tr(),
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
          msg:  "common.checkPhoneDup".tr(),
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
          msg: "myinfoupdate.updateUser".tr(),
          backgroundColor: Colors.greenAccent,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPage()),
        );
      } else {
        Fluttertoast.showToast(
          msg: "myinfoupdate.updateFailed".tr(),
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
        msg: "common.fillRequired".tr(),
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
        msg: "common.passwordNotMatch".tr(),
        backgroundColor: Colors.red,
      );
      return;
    }
    if (newPassCon.text.length < 8 || checkPassCon.text.length < 8) {
      Fluttertoast.showToast(
        msg: "common.passwordMinLength".tr(),
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
          msg: "myinfoupdate.updateUser".tr(),
          backgroundColor: Colors.greenAccent,
        );
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyPage()),
        );
      } else {
        Fluttertoast.showToast(
          msg:  "myinfoupdate.updateFailed".tr(),
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
          msg:  "common.canceled".tr(),
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
          msg: "myinfoupdate.removeSignup".tr(),
          backgroundColor: Colors.greenAccent,
        );
        _logOut(); // 탈퇴 후 로그아웃
      } else {
        Fluttertoast.showToast(
          msg:  "common.passwordInvalid".tr(),
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
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint';

    // 🔥 이 페이지 전용 버튼 색: 기본 테마(라이트 + default)일 때만 연핑크 + 갈색
    Color primaryBtnBg;
    Color primaryBtnFg;

    if (!isDark && !isMint) {
      primaryBtnBg = const Color(0xFFFFEEED); // 연핑크
      primaryBtnFg = const Color(0xFF6B4E42); // 갈색
    } else {
      primaryBtnBg = scheme.primary;
      primaryBtnFg = scheme.onPrimary;
    }

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "footer.myPage".tr(),
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
        // ✅ 푸터에 안 가리도록 FooterSafeArea 추가
        child: FooterSafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SKPageHeader(
                  title: "myinfoupdate.title".tr(),
                  subtitle: 'mypage.updateInfoDesc'.tr(),
                ),
                const SizedBox(height: 24),

              // 섹션 1: 기본 정보 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: "myinfoupdate.basicInfo".tr(),
                description: "myinfoupdate.basicInfoDesc".tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: nameCon,
                      label: 'account.name'.tr(),
                    ),
                    SizedBox(height: 12),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: nickCon,
                      label: 'ranking.th.nickname'.tr(),
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneField(theme, scheme),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        onPressed: checkPhone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnBg,
                          foregroundColor: primaryBtnFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text("myinfoupdate.checkPhoneDup".tr()),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updateUserInfo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnBg,
                          foregroundColor: primaryBtnFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child:Text("myinfoupdate.updateInfo".tr()),
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
                title: "myinfoupdate.changePassword".tr(),
                description: "myinfoupdate.changePasswordDesc".tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: currentPassCon,
                      label: "myInfoUpdate.oldPassword".tr(),
                      obscure: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: newPassCon,
                      label: "myinfoupdate.newPasswordHint".tr(),
                      obscure: true,
                    ),
                    const SizedBox(height: 10),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: checkPassCon,
                      label:  "myInfoUpdate.checkNewPassword".tr(),
                      obscure: true,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: updatePwrd,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnBg,
                          foregroundColor: primaryBtnFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text("myInfoUpdate.updatePassword".tr()),
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
                title:  "myInfoUpdate.deleteUser".tr(),
                description: "myinfoupdate.deleteInfoWarning".tr(),
                accentColor: scheme.error,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                    "myinfoupdate.deleteInfoWarning2".tr(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: deleteUserStatus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryBtnBg,
                          foregroundColor: primaryBtnFg,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text("myInfoUpdate.deleteUser".tr(),),
                      ),
                    ),
                  ],
                ),
              ),

                const SizedBox(height: 8),
              ],
            ),
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
    final isDark = theme.brightness == Brightness.dark;
    final isMint = themeColorNotifier.value == 'mint';

    // ✅ 이 페이지는 카드도 기본테마에서 흰색으로
    Color cardColor;
    if (isDark) {
      cardColor = scheme.surfaceContainer;
    } else {
      cardColor = Colors.white;
    }

    Color titleColor = accentColor ?? scheme.primary;
    Color descColor = scheme.onSurface.withOpacity(0.7);

    if (isMint && !isDark && accentColor == null) {
      titleColor = const Color(0xFF2F7A69);
      descColor = const Color(0xFF4E8476);
    }

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
                color: titleColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: descColor,
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

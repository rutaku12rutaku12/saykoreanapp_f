// lib/pages/setting/my_info_update_page.dart

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/setting/myPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ 공통 UI (헤더/버튼)

class MyInfoUpdatePage extends StatefulWidget {
  const MyInfoUpdatePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _InfoUpdateState();
  }
}

class _InfoUpdateState extends State<MyInfoUpdatePage> {
  @override
  void initState() {
    super.initState();
    loadUserInfo(); // ← 기존 값 자동 세팅
  }

  // 입력창 텍스트 컨트롤러
  final TextEditingController nameCon = TextEditingController();
  final TextEditingController nickCon = TextEditingController();
  final TextEditingController phoneCon = TextEditingController();
  final TextEditingController currentPassCon = TextEditingController();
  final TextEditingController newPassCon = TextEditingController();
  final TextEditingController checkPassCon = TextEditingController();

  // 중복검사 상태관리
  bool phoneCheck = false;

  // 서버 전송용 국제번호 저장 변수
  PhoneNumber? emailPhoneNumber;

  // 원래 전화번호 저장용
  String originalPhone = "";

  // 탈퇴용 비밀번호 입력 팝업 메소드
  Future<String?> showPasswordPrompt() async {
    final TextEditingController controller = TextEditingController();

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
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

  // 전화번호 중복 확인 메소드
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
      print(e);
    }
  }

  // 사용자 정보 수정 메소드
  void updateUserInfo() async {
    if (nameCon.text.trim().isEmpty ||
        nickCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "입력값을 채워주세요.",
        backgroundColor: Colors.red,
      );
      print("입력값을 채워주세요.");
      return;
    }
    try {
      final plusPhone = emailPhoneNumber?.completeNumber ?? "+82${phoneCon.text}";
      bool isPhoneChanged = (originalPhone != plusPhone);

      print("원래 번호: $originalPhone");
      print("현재 번호: $plusPhone");
      print("변경 여부: $isPhoneChanged");

      // 전화번호가 변경되었는데 중복 확인을 안했으면 에러
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
        "phone": plusPhone
      };
      print(sendData);
      final response = await ApiClient.dio.put(
        "/saykorean/updateuserinfo",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print(response);
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
      print(e);
    }
  }

  // 비밀번호 수정 메소드
  void updatePwrd() async {
    if (currentPassCon.text.trim().isEmpty ||
        newPassCon.text.trim().isEmpty ||
        checkPassCon.text.trim().isEmpty) {
      Fluttertoast.showToast(
        msg: "입력값을 채워주세요.",
        backgroundColor: Colors.red,
      );
      print("입력값을 채워주세요.");
      return;
    }
    if (newPassCon.text != checkPassCon.text) {
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
        "newPassword": newPassCon.text
      };
      final response = await ApiClient.dio.put(
        "/saykorean/updatepwrd",
        data: sendData,
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print(response);
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
      print(e);
    }
  }

  // 탈퇴 메소드
  void deleteUserStatus() async {
    try {
      // 비밀번호 입력 팝업 띄우기
      final inputPassword = await showPasswordPrompt();

      // 취소 누르면 null -> 종료
      if (inputPassword == null || inputPassword.trim().isEmpty) {
        Fluttertoast.showToast(
          msg: "취소되었습니다.",
          backgroundColor: Colors.red,
        );
        return;
      }
      // 서버로 전송
      final response = await ApiClient.dio.put(
        "/saykorean/deleteuser",
        data: {"password": inputPassword},
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      print("탈퇴 성공 시 1 반환: ${response.data}");

      if (response.statusCode == 200 && response.data == 1) {
        Fluttertoast.showToast(
          msg: "회원 탈퇴가 완료되었습니다.",
          backgroundColor: Colors.greenAccent,
        );
        LogOut(); // 탈퇴 후 로그아웃(토큰제거, 로그인페이지로 이동)
      } else {
        Fluttertoast.showToast(
          msg: "비밀번호가 올바르지 않습니다.",
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print(e);
    }
  }

  // 로그아웃 메소드
  void LogOut() async {
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
          // 전화번호 불러오기
          String phone = data["phone"] ?? "";
          if (phone.startsWith("+82")) {
            phone = phone.substring(3); // +82 제거만
          } else if (phone.startsWith("82")) {
            phone = phone.substring(2); // 82 제거만
          }
          phoneCon.text = phone;
          // 원래 전화번호 저장 (국제번호 포함)
          originalPhone = data["phone"] ?? "";
        });
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    // 공통 핑크 메인 버튼 스타일 (CTA)
    final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFFFFAAA5), // 🩷 딸기우유 핑크
      foregroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(vertical: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );

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
            color:
            theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color:
          theme.appBarTheme.foregroundColor ?? theme.colorScheme.primary,
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

              // 섹션 1: 기본 정보
              Text(
                "기본 정보",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nameCon,
                decoration: const InputDecoration(
                  labelText: '이름',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: nickCon,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              IntlPhoneField(
                controller: phoneCon,
                decoration: const InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                initialCountryCode: 'KR',
                autovalidateMode: AutovalidateMode.disabled,
                validator: (value) => null,
                onChanged: (phone) {
                  emailPhoneNumber = phone;
                  phoneCheck = false;
                  print("입력한 번호: ${phone.number}");
                }, // 입력 위젯, 전화번호
              ),
              const SizedBox(height: 8),

              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: checkPhone,
                  style: primaryButtonStyle,
                  child: const Text("전화번호 중복 확인"),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: updateUserInfo,
                  style: primaryButtonStyle,
                  child: const Text("정보 수정"),
                ),
              ),

              const SizedBox(height: 32),

              // 섹션 2: 비밀번호 변경
              Text(
                "비밀번호 수정",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 12),

              TextField(
                controller: currentPassCon,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "기존 비밀번호",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: newPassCon,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "새 비밀번호",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: checkPassCon,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "새 비밀번호 확인",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: updatePwrd,
                  style: primaryButtonStyle,
                  child: const Text("비밀번호 수정"),
                ),
              ),

              const SizedBox(height: 32),

              // 섹션 3: 탈퇴
              Text(
                "회원 탈퇴",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: scheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "탈퇴 시 계정 정보와 포인트, 랭킹 기록 등이 삭제될 수 있어요.",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 16),

              // 🔥 로그아웃이랑 같은 톤(연살구) 버튼 → SKPrimaryButton 사용
              SKPrimaryButton(
                label: '회원 탈퇴',
                onPressed: deleteUserStatus,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

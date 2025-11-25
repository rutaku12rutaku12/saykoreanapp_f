// lib/pages/auth/find_page.dart

import 'package:flutter/material.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

class FindPage extends StatefulWidget {
  const FindPage({super.key});

  @override
  State<FindPage> createState() => _FindState();
}

class _FindState extends State<FindPage> {
  // 1.1 이메일 찾기 입력상자 컨트롤러
  final TextEditingController name1Con = TextEditingController();
  final TextEditingController phone1Con = TextEditingController();

  // 1.2 비밀번호 찾기 입력상자 컨트롤러
  final TextEditingController name2Con = TextEditingController();
  final TextEditingController phone2Con = TextEditingController();
  final TextEditingController emailCon = TextEditingController();

  // 서버 전송용 국제번호 저장 변수 (이메일 / 비밀번호 각각)
  PhoneNumber? _emailPhoneNumber;
  PhoneNumber? _pwPhoneNumber;

  @override
  void dispose() {
    name1Con.dispose();
    phone1Con.dispose();
    name2Con.dispose();
    phone2Con.dispose();
    emailCon.dispose();
    super.dispose();
  }

  // 2. 이메일 찾기, 자바 통신
  Future<void> onFindEmail() async {
    print("onFindEmail.exe");
    try {
      final plusPhone = _emailPhoneNumber?.completeNumber ?? phone1Con.text;

      final sendData = {
        "name": name1Con.text.trim(),
        "phone": plusPhone.trim(),
      };
      print(sendData);

      final response = await ApiClient.dio.get(
        '/saykorean/findemail',
        queryParameters: sendData,
      );

      print(response.data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('찾으시는 이메일은 : ${response.data} 입니다.'),
          duration: const Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print("오류발생 : 이메일 찾기 실패, $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('이메일 찾기에 실패했어요. 다시 시도해주세요.'),
        ),
      );
    }
  }

  // 3. 비밀번호 찾기, 자바 통신
  Future<void> onFindPass() async {
    print("onFindPass.exe");
    try {
      final plusPhone = _pwPhoneNumber?.completeNumber ?? phone2Con.text;

      final sendData = {
        "name": name2Con.text.trim(),
        "phone": plusPhone.trim(),
        "email": emailCon.text.trim(),
      };
      print(sendData);

      final response = await ApiClient.dio.get(
        '/saykorean/findpwrd',
        queryParameters: sendData,
      );

      print(response.data);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('임시 비밀번호가 이메일로 발급되었습니다.'),
          duration: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print("오류발생 : 비밀번호 찾기 실패, $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('비밀번호 찾기에 실패했어요. 다시 시도해주세요.'),
        ),
      );
    }
  }

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
          "이메일 / 비밀번호 찾기",
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
        child: FooterSafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SKPageHeader(
                title: '계정 찾기',
                subtitle: '가입 시 입력하신 정보로 이메일과 비밀번호를 찾아드려요.',
              ),
              const SizedBox(height: 24),

              // 이메일 찾기 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '이메일 찾기',
                description: '이름과 전화번호를 입력하면\n가입한 이메일을 알려드려요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: name1Con,
                      label: '이름',
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneField(
                      theme: theme,
                      scheme: scheme,
                      controller: phone1Con,
                      onChanged: (phone) {
                        _emailPhoneNumber = phone;
                        print("이메일 찾기 번호: ${phone.completeNumber}");
                      },
                    ),
                    const SizedBox(height: 16),
                    // 살구색 공통 버튼
                    const SizedBox(height: 4),
                    SKPrimaryButton(
                      label: '이메일 찾기',
                      onPressed: onFindEmail,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 비밀번호 찾기 카드
              _buildCard(
                theme: theme,
                scheme: scheme,
                title: '비밀번호 찾기',
                description: '이름, 전화번호, 이메일을 입력하면\n임시 비밀번호를 보내드려요.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: name2Con,
                      label: '이름',
                    ),
                    const SizedBox(height: 12),
                    _buildPhoneField(
                      theme: theme,
                      scheme: scheme,
                      controller: phone2Con,
                      onChanged: (phone) {
                        _pwPhoneNumber = phone;
                        print("비밀번호 찾기 번호: ${phone.completeNumber}");
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      theme: theme,
                      scheme: scheme,
                      controller: emailCon,
                      label: '이메일',
                    ),
                    const SizedBox(height: 16),
                    SKPrimaryButton(
                      label: '비밀번호 찾기',
                      onPressed: onFindPass,
                    ),
                  ],
                ),
              ),
            ],
          ),
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
  }) {
    return TextField(
      controller: controller,
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

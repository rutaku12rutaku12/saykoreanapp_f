import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl_phone_field_v2/intl_phone_field.dart';
import 'package:intl_phone_field_v2/phone_number.dart';
import 'package:recaptcha_enterprise_flutter/recaptcha_action.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';

import 'package:saykoreanapp_f/utils/recaptcha_manager.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SignupState();
  }
}

class _SignupState extends State<SignupPage> {
  // * 입력 컨트롤러, 각 입력창에서 입력받은 값을 제어
  TextEditingController nameCon = TextEditingController();
  TextEditingController emailCon = TextEditingController();
  TextEditingController passwordCon = TextEditingController();
  TextEditingController nickNameCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();

  // 중복검사 상태관리
  bool emailCheck = false;
  bool phoneCheck = false;
  // [추가] reCAPTCHA V2 체크박스 상태를 흉내 낼 변수
  bool _isRecaptchaChecked = false;

  // 서버 전송용 국제번호 저장 변수
  PhoneNumber? emailPhoneNumber;

  // 회원가입 함수
  void onSignup() async {
    // // [추가] V2처럼 사용자가 체크했는지 확인
    // if (!_isRecaptchaChecked) {
    //   Fluttertoast.showToast(msg: "reCAPTCHA를 확인해 주세요.", backgroundColor: Colors.orange);
    //   return;
    // }
    // 공백 또는 빈 문자열 유효성 검사
    if(nameCon.text.trim().isEmpty ||
        emailCon.text.trim().isEmpty ||
        passwordCon.text.trim().isEmpty ||
        nickNameCon.text.trim().isEmpty ||
        phoneCon.text.trim().isEmpty)
    {
      Fluttertoast.showToast(msg: "입력값을 채워주세요.", backgroundColor: Colors.red);
      print("입력값을 채워주세요.");
      return;}
    if( emailCheck == false || phoneCheck == false ){
      Fluttertoast.showToast(msg: "중복 확인을 모두 해주세요.",backgroundColor: Colors.red); print("중복 확인을 해주세요.");
      return;}
    // 1. [수정] 로딩 화면을 가장 먼저 표시
    showDialog(
      context: context,
      builder: (context) => const Center(child: CircularProgressIndicator()),
      barrierDismissible: false, // 팝업창(로딩화면) 외 바깥 클릭 차단
    );

    String recaptchaToken = '';

    try {
      // 2. reCAPTCHA 토큰 요청 (Signup 액션)
      // V2 방식의 UX를 위해 체크는 했지만, 토큰 요청은 Enterprise SDK를 그대로 사용
      recaptchaToken = await RecaptchaManager.getClient().execute(RecaptchaAction.SIGNUP());
      print('reCAPTCHA Token successfully generated: $recaptchaToken');
    } catch (e) {
      // 3. [수정] 토큰 생성 실패 시, 로딩 화면을 안전하게 닫고 사용자에게 알림
      Navigator.pop(context); // 로딩 닫기 (이제는 안전함)
      Fluttertoast.showToast(msg: "보안 검증 실패. 다시 시도해 주세요. [$e]", backgroundColor: Colors.red, toastLength: Toast.LENGTH_LONG);
      print('reCAPTCHA execution error: $e');
      return; // 회원가입 진행을 중단
    }

    // 4. 자바에게 보낼 데이터 준비
    final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
    print(recaptchaToken);
    final sendData = {
      'name': nameCon.text,
      'email': emailCon.text,
      'password': passwordCon.text,
      'nickName': nickNameCon.text,
      'phone': plusPhone,
      // 'recaptcha':recaptchaToken,
    };
    print(sendData);
    // 이 시점부터는 API 통신이 시작되므로, 로딩 화면을 유지합니다.
    try {
      final response = await ApiClient.dio.post(
          "/saykorean/signup", data: sendData);
      final data = response.data;

      Navigator.pop(context); // 로딩 화면 닫기

      if (data) {
        print("회원가입 성공");

        Fluttertoast.showToast(
          // 출력할 내용
          msg: "회원가입 성공 했습니다.",
          // 메시지 유지기간
          toastLength: Toast.LENGTH_LONG,
          // 메시지 위치 : 앱 적용
          gravity: ToastGravity.BOTTOM,
          // 자세한 유지시간 (sec)
          timeInSecForIosWeb: 10,
          // 배경색
          backgroundColor: Color(0xFFA8E6CF),
          // 글자색상
          textColor: Color(0xFF6B4E42),
          // 글자 크기
          fontSize: 16,
        );

        // * 페이지 전환
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
      else {
        print("회원가입 실패");
        Fluttertoast.showToast(msg: "회원가입 실패", backgroundColor: Colors.red);
      }
    } catch (e) {
      Navigator.pop(context); // 오류 발생 시 로딩 화면 닫기
      print(e);
      Fluttertoast.showToast(msg: "서버 통신 오류가 발생했습니다.", backgroundColor: Colors.red);
    }
  } // f end

  // 이메일 중복 확인 메소드
  void checkEmail () async{
    try{
      final response = await ApiClient.dio.get(
        "/saykorean/checkemail",
        options: Options(
          validateStatus: (status) => true,
        ),
        queryParameters: { 'email' : emailCon.text }
      );
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");
      if(response.statusCode == 200 && response.data != null && response.data == 0){
        setState(() {
          emailCheck=true;
        });
        Fluttertoast.showToast(msg: "이메일 사용이 가능합니다.", backgroundColor: Colors.greenAccent);
      }else{Fluttertoast.showToast(msg: "이메일 형식이 올바르지 않거나, 사용 중인 이메일입니다ㄹ.", backgroundColor: Colors.red);}
    }catch(e){print(e);}
  }

  // 전화번호 중복 확인 메소드
  void checkPhone () async{
    try{
      final plusPhone = emailPhoneNumber?.completeNumber ?? phoneCon.text;
      final response = await ApiClient.dio.get(
        "/saykorean/checkphone",
        options: Options(
          validateStatus: (status) => true,
        ),
        queryParameters: { 'phone' : plusPhone }
      );
      print("(중복 : 1 , 사용 가능 : 0 반환 ): ${response.data}");
      if(response.statusCode == 200 && response.data != null && response.data == 0){
        setState(() {
          phoneCheck=true;
        });
        Fluttertoast.showToast(msg: "전화번호 사용이 가능합니다.", backgroundColor: Colors.greenAccent);
      }else{Fluttertoast.showToast(msg: "전화번호 형식이 올바르지 않거나, 사용 중인 전화번호입니다.", backgroundColor: Colors.red);}
    }catch(e){
      print(e);}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container( // Container( padding : , margin : ); 안쪽/바깥 여백 위젯
          padding: EdgeInsets.all(30), // EdgeInsets.all() : 상하좌우 모두 적용되는 안쪽 여백
          margin: EdgeInsets.all(30), // EdgeInsets.all() : 상하좌우 모두 적용되는 바깥 여백
          child: Column( // 세로배치 위젯
            mainAxisAlignment: MainAxisAlignment.center,
            // 주 축으로 가운데 정렬( Column 이면 세로 , Row이면 가로)
            children: [ // 하위 위젯
              TextField(
                controller: nameCon,
                decoration: InputDecoration(
                    labelText: "이름", border: OutlineInputBorder()),
              ), // 입력 위젯, 네임
              SizedBox(height: 20,),
              TextField(
                controller: emailCon,
                decoration: InputDecoration(
                    labelText: "이메일", border: OutlineInputBorder()),
              ),// 입력 위젯, 이메일(id)
              SizedBox(height: 20,),
              ElevatedButton(onPressed: checkEmail, child: Text("중복 확인")),

              SizedBox(height: 20,),
              TextField(
                controller: passwordCon,
                obscureText: true, // 입력한 텍스트 가리기
                decoration: InputDecoration(
                    labelText: "비밀번호", border: OutlineInputBorder()),
              ), // 입력 위젯 , 패스워드
              SizedBox(height: 20,),
              TextField(
                controller: nickNameCon,
                decoration: InputDecoration(
                    labelText: "닉네임", border: OutlineInputBorder()),
              ), // 입력 위젯, 닉네임
              SizedBox(height: 20,),
              IntlPhoneField(
                controller: phoneCon,
                decoration: InputDecoration(
                  labelText: '전화번호',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(),
                  ),
                ),
                initialCountryCode: 'KR',
                autovalidateMode: AutovalidateMode.disabled,
                validator: (value) => null, // 자리수 검증 제거// ,
                onChanged: (phone) {
                  emailPhoneNumber = phone;
                  print("입력한 번호: ${phone.number}");
                }, // 입력 위젯, 전화번호
              ),
              ElevatedButton(onPressed: checkPhone, child: Text("중복 확인")),
              SizedBox(height: 20,),

              // // 리캡챠
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.start,
              //   children: [
              //     Checkbox(
              //       value: _isRecaptchaChecked,
              //       onChanged: (bool? newValue) {
              //         setState(() {
              //           _isRecaptchaChecked = newValue ?? false;
              //         });
              //       },
              //     ),
              //     const Text("로봇이 아닙니다."),
              //     const Spacer(),
              //     // 실제 reCAPTCHA 로고를 흉내냄 (실제로는 Enterprise 버전이 백그라운드에 있음)
              //     Image.network(
              //       "https://placehold.co/100x40/DDDDDD/000000?text=reCAPTCHA",
              //       errorBuilder: (context, error, stackTrace) => const Text("reCAPTCHA Logo", style: TextStyle(fontSize: 12)),
              //       height: 40,
              //     )
              //   ],
              // ),
              SizedBox(height: 20,),

              ElevatedButton(onPressed: onSignup, child: const Text("회원가입")),
              SizedBox(height: 20,),
              ElevatedButton(onPressed: () =>
              {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => LoginPage())),
              }, child: Text("이미 가입된 사용자면 로그인"))

            ],
          ),
        )
    );
  } // build end
} // class end
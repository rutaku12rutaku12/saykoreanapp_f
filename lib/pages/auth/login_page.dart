
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/api.dart';

class LoginPage extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<LoginPage>{
  // 1. 입력상자 컨트롤러
  TextEditingController emailCon = TextEditingController();
  TextEditingController pwdCont = TextEditingController();

  // 2. 자바와 통신
  // user02@example.com , pass#02!
  void onLogin() async {
    print("onLogin.exe");
    try {
      final sendData = { "email": emailCon.text, "password": pwdCont.text};
      print(sendData);
      // baseUrl + path만 사용
      final response = await ApiClient.dio.post(
        // '/saykorean/login'     // 슬래시로 시작하는 path만 적기
        'http://10.0.2.2:8080/saykorean/login',
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

      final data = response.data;
      print(data);

      if (response.statusCode == 200 && response.data != null && response.data != '') { // 로그인 성공시 토큰 SharedPreferences 저장하기.
        final token = response.data['token'];
        // 1. 전역변수 호출
        final prefs = await SharedPreferences.getInstance();
        // 2. 전역변수 값 추가
        await prefs.setString( 'token', token.toString() );

        // * 로그인 성공 시 페이지 전환 //
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (content) => HomePage()),
        );
      } else {
        print("로그인 실패: ${response.statusCode}");
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 중 오류가 발생했습니다.')),
      );
    }
  } // c end



  @override
  Widget build(BuildContext context) {
    return Scaffold( // 레이아웃 위젯
      body: Container( // 여백 제공하는 박스 위젯
        padding: EdgeInsets.all(30), // 박스 안쪽 여백
        margin: EdgeInsets.all(30), // 박스 바깥 여백
        child: Column( // 하위 요소 세로 위젯
          mainAxisAlignment: MainAxisAlignment.center,
          // 현재 축(Column) 기준으로 정렬
          children: [ // 하위 요소를 위젯
            TextField(controller: emailCon,
              decoration: InputDecoration(
                  labelText: "이메일", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20,),
            TextField(controller: pwdCont, obscureText: true, // 입력값 감추기
              decoration: InputDecoration(
                  labelText: "비밀번호", border: OutlineInputBorder()),
            ),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: onLogin, child: Text("로그인")),
            SizedBox(height: 20,),
            TextButton(onPressed: () =>
            {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => FindPage()))
            }, child: Text("이메일 찾기/비밀번호 찾기 ")),
            SizedBox(height: 20,),
            TextButton(onPressed: () =>
            {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (context) => SignupPage() )
              )
            }, child: Text("회원가입") ),

            SizedBox( height: 20,),
            TextButton(onPressed: (){}, child: Text("카카오로그인 예정")),
            SizedBox( height: 20,) ,
            TextButton(onPressed: (){}, child: Text("구글 로그인 예정")),
          ],
        ), // c end
      ), // c end
    ); // s end
  }
}


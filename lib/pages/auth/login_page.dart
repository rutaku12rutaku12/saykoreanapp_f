import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

final dio = Dio();
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
  void onLogin() async {
    try {
      Dio dio = Dio();
      final sendData = { "email": emailCon.text, "password": pwdCont.text};
      final response = await dio.post(
          "http://192.168.40.235:8080/saykorean/login", data: sendData);
      final data = response.data;
      if (data != '') { // 로그인 성공 시 토큰 SharedPreferences 저장하기.
        // 1. 전역변수 호출
        final prefs = await SharedPreferences.getInstance();
        // 2. 전역변수 값 추가
        await prefs.setString('result', data);

        // * 로그인 성공 시 페이지 전환
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (content) => HomePage()),
        );
      } else {
        print("로그인 실패");
      }
    } catch (e) {
      print(e);
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


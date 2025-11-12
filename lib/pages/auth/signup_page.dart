import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';

class SignupPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _SignupState();
  }
}



class _SignupState extends State<SignupPage>{
  // * 입력 컨트롤러, 각 입력창에서 입력받은 값을 제어
  TextEditingController nameCon = TextEditingController();
  TextEditingController emailCon = TextEditingController();
  TextEditingController passwordCon = TextEditingController();
  TextEditingController nickNameCon = TextEditingController();
  TextEditingController phoneCon = TextEditingController();

  // * 등록 버튼 클릭 시
  void onSignup() async{
    // 1. 자바에게 보낼 데이터 준비
    final sendData = {
      'name' : nameCon.text,
      'email': emailCon.text,
      'password': passwordCon.text,
      'nickName': nickNameCon.text,
      'phone': phoneCon.text,
      //'recaptcha' : captchaValue
    }; print(sendData);

    // * Rest API 통신 간의 로딩 화면 표시, showDialog() : 팝업 창 띄우기 위한 위젯
    showDialog(
      context: context,
      builder: (context) => Center( child: CircularProgressIndicator() ,),
      barrierDismissible: false, // 팝업창(로딩화면) 외 바깥 클릭 차단
    );

    // 2.
    try{
      Dio dio = Dio();
      final response = await dio.post("http://192.168.40.22:8080/saykorean/signup", data: sendData);
      final data = response.data;

      Navigator.pop(context); // 가장 앞(가장 최근에 열린)에 있는 위젯 닫기 (showDialog(): 팝업 창)

      if (data){
        print("회원가입 성공");

        Fluttertoast.showToast(
          msg: "회원가입 성공 했습니다.", // 출력할 내용
          toastLength: Toast.LENGTH_LONG , // 메시지 유지기간
          gravity: ToastGravity.BOTTOM, // 메시지 위치 : 앱 적용
          timeInSecForIosWeb: 3 , // 자세한 유지시간 (sec)
          backgroundColor: Colors.redAccent, // 배경색
          textColor: Colors.green, // 글자색상
          fontSize: 16, // 글자 크기
        );
        
        // * 페이지 전환
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> LoginPage() ) );
      }
      else{print("회원가입 실패"); }
    } catch(e){print(e);}
  } // f end

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("회원가입페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("회원가입 페이지"),
            ElevatedButton(
                onPressed: (){
                  Navigator.pop(context);
                },
                child: Text("뒤로가기"))
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/dio_client.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/setting/genre.dart';
import 'package:saykoreanapp_f/pages/setting/language.dart';


  class MyPage extends StatefulWidget{
    @override
    State<StatefulWidget> createState() {
      return _MyPageState();
    }
  }

  class _MyPageState extends State<MyPage>{
    final dioClient = DioClient();

    // 1. 상태변수
    String nickName = "";
    String userDate = "";
    bool isLoading = true;
    // String 총 출석 일수 = "";
    // String 현재 연속 출석 일수 = "";

    // 2. 해당 페이지 열렸을때 실행되는 함수
    @override
    void initState() {
      super.initState();
      loginCheck();
    }

    // 3. 로그인 상태를 확인하는 함수
    Future<void> loginCheck() async {
      await dioClient.init();
      await onInfo();
    }

    // 4. 로그인된 (회원) 정보 요청 , 로그인 중일때 실행
    Future<void> onInfo(  ) async{
      try {
        final response = await dioClient.instance.get("/saykorean/info");

        print("응답 상태: ${response.statusCode}");
        print("응답 데이터: ${response.data}");

        if (response.statusCode == 200 && response.data != null) {
          setState(() {
            nickName = response.data['nickName'] ?? '';
            userDate = response.data['userDate'] ?? '';
            isLoading = false;
          });
        } else {
          // 로그인 x -> 로그인 페이지로 이동
          Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage()),
          );
        }
      } catch (e) {
      print("로그인 확인 오류: $e");
      // 오류 발생 시 로그인 페이지로 이동
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context)=> LoginPage()),
        );
      }
    }

    @override
    Widget build(BuildContext context) {
      // 로딩 중일 때
      if( isLoading ){
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      }
      
      return Scaffold(
        appBar: AppBar( title: Text("마이페이지"),),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("마이페이지"),
              SizedBox(height: 20,),
              
              Text("닉네임 : $nickName"),
              SizedBox(height: 10,),
              Text("가입일자 : $userDate"),
              SizedBox(height: 10,),

              Text("총 출석 일수 : "),
              SizedBox(height: 10,),
              Text("현재 연속 출석 일수 : "),
              SizedBox(height: 10,),

              Text("내가 선택한 장르 : "),
              SizedBox(height: 10,),
              Text("내가 선택한 언어 : "),
              SizedBox(height: 10,),

              TextButton(onPressed: (){ Navigator.pushReplacement(
                context,
                  MaterialPageRoute(builder: (context) => MyInfoUpdatePage() ));
              }, child: Text("정보 수정") , ) ,
              // 장르 설정, 언어 설정 버튼
              TextButton(onPressed: (){ Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => GenrePage() ));
                  } , child: Text("장르 설정") , ) ,
              TextButton(onPressed: (){ Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => LanguagePage() ));
              } , child: Text("언어 설정") , ) ,


            ],
          ),
        ),
      );
    }
  }
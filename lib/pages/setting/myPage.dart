  import 'package:flutter/material.dart';
  import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
  import 'package:saykoreanapp_f/pages/setting/genre.dart';
  import 'package:saykoreanapp_f/pages/setting/language.dart';

  class Mypage extends StatelessWidget{
    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar( title: Text("마이페이지"),),
        body: Center(
          child: Column(
            children: [
              Text("마이페이지"),

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
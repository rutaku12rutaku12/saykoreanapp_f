import 'package:flutter/material.dart';
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

            // 장르 설정, 언어 설정 버튼
            TextButton(onPressed: (){ Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => GenrePage() ));
                } , child: Text("장르 설정") , ) ,
            TextButton(onPressed: (){ Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => Language() ));
            } , child: Text("언어 설정") , ) ,

            // 뒤로 가기 버튼
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
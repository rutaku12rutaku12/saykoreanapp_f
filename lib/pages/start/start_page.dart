import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';

class StartPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("시작페이지"),),
      body: Center(
        child: Row(
          children: [
            Text("시작 페이지"),
            TextButton( onPressed: (){ Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context)=>LoginPage() ));
                }, child: Text("로그인") ,) ,

            TextButton( onPressed: () { Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context)=>SignupPage() ));
              }, child: Text("회원가입") , ) ,
          ],
        ),
      ),
    );
  }
}
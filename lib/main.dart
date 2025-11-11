import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:saykoreanapp_f/pages/auth/signup_page.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';
import 'package:saykoreanapp_f/pages/home/home_page.dart';
import 'package:saykoreanapp_f/pages/my/my_info_update_page.dart';
import 'package:saykoreanapp_f/pages/my/my_page.dart';
import 'package:saykoreanapp_f/pages/start/start_page.dart';

void main(){
  runApp( MyApp() );
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      // routes : { "경로정의" : (context) =>위젯명() },
      routes: {
        "/" : (context) => StartPage() ,
        "/home" : (context) => HomePage() ,
        "/login" : (context) => LoginPage() ,
        "/signup" : (context) => SignupPage() ,
        "/find" : (context) => FindPage() ,
        "/info" : (context) => MyPage() ,
        "/update" : (context) => MyInfoUpdatePage() ,
        "/game": (context) => GamePage(),
      },
    );
  }
}

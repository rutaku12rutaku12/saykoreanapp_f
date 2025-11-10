import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/auth/find_page.dart';

void main(){
  runApp( MyApp() );
}

class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: "/",
      routes: {
        "/" : (context) => StartPage() ,
        "/home" : (context) => StartPage() ,
        "/login" : (context) => StartPage() ,
        "/signup" : (context) => StartPage() ,
        "/find" : (context) => StartPage() ,
        "/info" : (context) => StartPage() ,
        "/update" : (context) => StartPage() ,
      },
    );
  }
}
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api.dart';
import 'package:saykoreanapp_f/pages/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? myUserNo;

  @override
  void initState() {
    super.initState();
    loadUserNo();
  }

  void loadUserNo() async {
    final prefs = await SharedPreferences.getInstance();
    final no = prefs.getInt('myUserNo');
    print("HomePage에서 가져온 userNo = $no");

    setState(() {
      myUserNo = no;
    });
  }

  void LogOut() async{
    try{
      final response = await ApiClient.dio.get(
        '/saykorean/logout',
        options: Options(
          validateStatus: (status) => true,
        )

      );
      // 토큰이 저장되있는 SharedPreferences로 접근
      final prefs = await SharedPreferences.getInstance();
      // 토큰 제거
      await prefs.remove('token');
      // 로그인 페이지로 이동
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (context) => LoginPage()));
    } catch(e){print(e);}
  }
  @override
  Widget build(BuildContext context) {
    if (myUserNo == null) {
      return Scaffold(
        appBar: AppBar(title: Text("홈페이지")),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text("홈페이지")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("로그인된 유저 번호: $myUserNo"),
            SizedBox(height: 20,),
            ElevatedButton(onPressed: LogOut, child: Text("로그아웃"))
          ],
        ),
      ),
    );
  }
}

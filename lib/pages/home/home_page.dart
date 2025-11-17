import 'package:flutter/material.dart';
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

            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  "/friends",
                  arguments: myUserNo,   // ⭐ 여기서 userNo 전달
                );
              },
              child: Text("친구 목록으로 이동"),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class MyPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("내정보페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("내정보 페이지"),
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
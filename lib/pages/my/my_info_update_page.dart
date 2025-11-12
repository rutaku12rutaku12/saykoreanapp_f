import 'package:flutter/material.dart';

class MyInfoUpdatePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("내정보수정페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("정보 수정 페이지"),
          ],
        ),
      ),
    );
  }
}
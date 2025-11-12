import 'package:flutter/material.dart';

class SuccesslistPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("완수한 주제 목록"),),
      body: Center(
        child: Column(
          children: [
            Text("완수한 주제 목록 페이지"),

          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("로딩페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("로딩페이지"),

          ],
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("홈페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("홈 페이지"),
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
import 'package:flutter/material.dart';

class FindPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text("찾기페이지"),),
      body: Center(
        child: Column(
          children: [
            Text("찾기 페이지"),
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
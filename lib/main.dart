import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/pages/game/game.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget { // 리팩토링 할때 이거 뒤로 밀어주세요
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: GamePage(),  // 게임 페이지로 바로 시작
    );
  }
}
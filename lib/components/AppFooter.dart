import 'package:flutter/material.dart';

class AppFooter extends StatelessWidget {
  final Widget child;
  final double height;
  const AppFooter({super.key, required this.child, this.height = 56});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: height,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
          color: Colors.white,
        ),
        child: child,
      ),
    );
  }
}

// 사용
// bottomNavigationBar: const AppFooter(child: Text('© 2025 SayKorean')),

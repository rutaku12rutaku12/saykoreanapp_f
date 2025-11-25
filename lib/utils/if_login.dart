import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IfLogin extends StatefulWidget{
  final Widget child;

    const IfLogin({
      Key? key,
      required this.child,
  }) : super(key: key);

    @override
    State<IfLogin> createState() => _IfLoginState();
}

class _IfLoginState extends State<IfLogin> {
    bool _isChecking = true;

    @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if( !mounted) return;

    // 로그인 안 되어 있으면 로그인 페이지로 이동
    if( token ==null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // 로그인 되어 있으면 정상 표시
    setState(() => _isChecking = false);
  }

@override
  Widget build(BuildContext context) {
    if( _isChecking){
      return Scaffold(
        body: Center(child: CircularProgressIndicator(),),
      );
    }

    // 🔥 EasyLocalization context를 그대로 유지하면서 child 렌더링
    return Builder(
      builder: (ctx) {
        return widget.child;
      },
    );

  }
}
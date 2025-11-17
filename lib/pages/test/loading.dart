// lib/pages/test/loading.dart

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  bool _started = false;
  String _message = '채점 중입니다...';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _startGrading();
  }

  Future<void> _startGrading() async {
    // TestPage에서 넘긴 arguments 받기
    final args =
    ModalRoute.of(context)?.settings.arguments as Map<dynamic, dynamic>?;

    final action = args?['action'];
    final payload = args?['payload'] as Map<dynamic, dynamic>?;

    if (action != 'submitAnswer' || payload == null) {
      setState(() {
        _message = '잘못된 접근입니다.';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
      return;
    }

    final String url = payload['url'] as String;
    final dynamic body = payload['body'];
    final int testNo = payload['testNo'] as int;

    try {
      final res = await ApiClient.dio.post(url, data: body);
      // print("▶ loading submitAnswer status = ${res.statusCode}");
      // print("▶ loading submitAnswer data   = ${res.data}");

      if (!mounted) return;

      // React처럼 채점 끝나면 결과 페이지로 이동
      Navigator.pushReplacementNamed(
        context,
        "/testresult/$testNo",
        arguments: res.data, // 필요하면 결과 페이지에서 arguments로 사용
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _message = '채점 중 오류가 발생했습니다.';
      });
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cream = Color(0xFFFFF9F0);
    const brown = Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: cream,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              _message,
              style: const TextStyle(
                color: brown,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

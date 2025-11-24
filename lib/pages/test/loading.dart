// lib/pages/test/loading.dart

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart';

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
    // 화면이 다시 빌드될 때 중복 호출 방지
    if (_started) return;
    _started = true;
    _startGrading();
  }

  Future<void> _startGrading() async {
    // 1) 라우트 인자 꺼내기
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is! Map) {
      // 잘못된 접근이면 바로 이전 페이지로 에러 반환
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': '잘못된 접근입니다. (arguments 형식 오류)',
        });
      }
      return;
    }

    final args = rawArgs as Map;
    final action = args['action'];
    final payload = args['payload'];

    if (action != 'submitAnswer' || payload is! Map) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': '잘못된 접근입니다. (action/payload 오류)',
        });
      }
      return;
    }

    final p = payload as Map;

    // TestPage에서 넘겨준 값들
    final String? url = p['url'] as String?;
    final dynamic body = p['body'];

    if (url == null || url.isEmpty) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': '요청 URL이 비어있습니다.',
        });
      }
      return;
    }

    try {
      // 2) 실제 채점 요청
      setState(() => _message = '채점 중입니다...');

      final res = await ApiClient.dio.post(url, data: body);

      if (!mounted) return;

      // 3) 성공 시 TestPage로 결과 반환
      Navigator.pop(context, {
        'ok': true,
        'data': res.data,
        'statusCode': res.statusCode,
      });
    } on DioException catch (e) {
      // Dio 에러 로깅
      print('LoadingPage DioException: '
          'type=${e.type}, status=${e.response?.statusCode}, data=${e.response?.data}');

      if (!mounted) return;

      Navigator.pop(context, {
        'ok': false,
        'error': e.message ?? e.toString(),
        'statusCode': e.response?.statusCode,
      });
    } catch (e) {
      // 기타 예외
      print('LoadingPage unknown error: $e');

      if (!mounted) return;

      Navigator.pop(context, {
        'ok': false,
        'error': e.toString(),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const brown = Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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

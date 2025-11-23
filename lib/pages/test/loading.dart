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
    if (_started) return;
    _started = true;
    _startGrading();
  }

  Future<void> _startGrading() async {
    final rawArgs = ModalRoute.of(context)?.settings.arguments;

    if (rawArgs is! Map) {
      if (mounted) {
        Navigator.pop(context, {
          'ok': false,
          'error': '잘못된 접근입니다. (args 타입)',
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
          'error': '잘못된 접근입니다. (payload)',
        });
      }
      return;
    }

    final p = payload as Map;
    final String url = p['url'] as String;
    final dynamic body = p['body'];

    try {
      final res = await ApiClient.dio.post(url, data: body);

      if (!mounted) return;

      Navigator.pop(context, {
        'ok': true,
        'data': res.data,
        'statusCode': res.statusCode,
      });
    } on DioException catch (e) {
      print('loading.dart DioException: '
          'type=${e.type}, status=${e.response?.statusCode}, data=${e.response?.data}');

      if (!mounted) return;
      Navigator.pop(context, {
        'ok': false,
        'error': e.message ?? e.toString(),
      });
    } catch (e) {
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

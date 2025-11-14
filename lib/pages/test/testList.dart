import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';

// ─────────────────────────────────────────────────────────────────────────────
// baseUrl 감지 (다른 파일과 동일하게 맞추기)
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST');
  if (env.isNotEmpty) return env;
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 6),
  receiveTimeout: const Duration(seconds: 12),
));

// ─────────────────────────────────────────────────────────────────────────────

class TestListPage extends StatefulWidget {
  final int studyNo;
  const TestListPage({super.key, required this.studyNo});

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  bool loading = false;
  String msg = "";
  List<dynamic> tests = [];
  int _langNo = 1; // 언어번호

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    setState(() {
      loading = true;
      msg = "";
    });

    try {
      // StudyPage에서 쓰던 selectedLangNo 그대로 사용
      final prefs = await SharedPreferences.getInstance();
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      await _loadTests();
    } catch (e) {
      setState(() {
        msg = "테스트 목록 로드 중 오류가 발생했어요 😢";
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  Future<void> _loadTests() async {
    try {
      final res = await dio.get(
        '/saykorean/test/by-study',
        queryParameters: {
          'studyNo': widget.studyNo,
          'langNo': _langNo, // 백엔드 시그니처에 맞게 langNo까지 전송
        },
      );

      final list = (res.data is List) ? (res.data as List) : <dynamic>[];
      setState(() => tests = list);
    } catch (e) {
      setState(() => msg = "테스트 목록을 불러올 수 없어요 😢");
    }
  }

  @override
  Widget build(BuildContext context) {
    final cream = const Color(0xFFFFF9F0);
    final brown = const Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: cream,
      appBar: AppBar(
        title: Text("테스트 목록 (study #${widget.studyNo})"),
        backgroundColor: cream,
        foregroundColor: brown,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
          ? Center(
        child: Text(
          msg.isEmpty ? "등록된 테스트가 없어요" : msg,
          style: const TextStyle(color: Colors.grey),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: tests.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final t = tests[i];

          // testNo 안전 캐스팅
          final rawTestNo = t['testNo'];
          final testNo = (rawTestNo is int)
              ? rawTestNo
              : (rawTestNo is num)
              ? rawTestNo.toInt()
              : int.tryParse(rawTestNo?.toString() ?? "0") ?? 0;

          // 언어별 CASE 컬럼이 있다면 testTitleSelected 우선 사용
          final title =
          (t['testTitleSelected'] ?? t['testTitle'] ?? "테스트 $testNo")
              .toString();
          final desc = (t['testDesc'] ?? "").toString();

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            elevation: 0,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF3F3F46),
                ),
              ),
              subtitle: desc.isNotEmpty
                  ? Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
              )
                  : null,
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TestPage(testNo: testNo),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

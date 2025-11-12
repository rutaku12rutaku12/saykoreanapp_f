import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';

// ── baseUrl 감지
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST');
  if (env.isNotEmpty) return env;
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}
final dio = Dio(BaseOptions(baseUrl: _detectBaseUrl()));

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

  @override
  void initState() {
    super.initState();
    _loadTests();
  }

  Future<void> _loadTests() async {
    setState(() { loading = true; msg = ""; });
    try {
      final res = await dio.get('/saykorean/test/by-study', queryParameters: {
        'studyNo': widget.studyNo,
      });
      final list = (res.data is List) ? (res.data as List) : [];
      setState(() => tests = list);
    } catch (e) {
      setState(() => msg = "테스트 목록을 불러올 수 없어요 😢");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("테스트 목록 (study #${widget.studyNo})")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tests.isEmpty
          ? Center(child: Text(msg.isEmpty ? "등록된 테스트가 없어요" : msg))
          : ListView.separated(
        itemCount: tests.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final t = tests[i];
          final testNo = t['testNo'] as int;
          final title = (t['testTitle'] ?? "테스트 $testNo").toString();
          final desc = (t['testDesc'] ?? "").toString();
          return ListTile(
            title: Text(title),
            subtitle: desc.isNotEmpty ? Text(desc) : null,
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TestPage(testNo: testNo),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

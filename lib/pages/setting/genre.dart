// main.dart — 그대로 복붙해서 실행하세요.
// (안드로이드 에뮬레이터에서 호스트 서버로 붙는 경우, 기본 baseUrl은 10.0.2.2:8080)
// (실기기/다른 PC로 붙을 땐 flutter run --dart-define=API_HOST=http://<IP>:8080)

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 환경별 baseUrl 감지 (dart-define로 API_HOST 넘기면 그것을 우선 사용)
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST'); // 예) --dart-define=API_HOST=http://192.168.0.10:8080
  if (env.isNotEmpty) return env;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080'; // 안드 에뮬레이터→호스트
  return 'http://localhost:8080';                        // iOS 시뮬레이터/데스크톱
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 10),
));

// ─────────────────────────────────────────────────────────────────────────────
// DTO
class GenreDto {
  final int genreNo;
  final String genreName;

  GenreDto({required this.genreNo, required this.genreName});

  factory GenreDto.fromJson(Map<String, dynamic> j) => GenreDto(
    genreNo: j['genreNo'] as int,
    genreName: (j['genreName'] ?? j['genreName_ko'] ?? '').toString(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 앱 시작
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SayKorean Genres',
      themeMode: ThemeMode.system,              // ← 시스템 테마 따라가기
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.teal,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.teal,
      ),
      home: const GenrePage(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 장르 페이지
class GenrePage extends StatefulWidget {
  const GenrePage({super.key});

  @override
  State<GenrePage> createState() => _GenreState();
}

class _GenreState extends State<GenrePage> {
  bool _loading = false;
  String? _error;
  List<GenreDto> _items = const [];
  int? _selected; // 저장된 선택값 표시용

  @override
  void initState() {
    super.initState();
    _loadSelected();
    _fetchGenres();
  }

  // 저장된 선택값 불러오기
  Future<void> _loadSelected() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selected = prefs.getInt('selectedGenreNo'));
  }

  // 장르 목록 호출 (백엔드가 i18n을 수행한다면 lng를 함께 전달 가능)
  Future<void> _fetchGenres() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // (옵션) 저장된 언어 코드
      final prefs = await SharedPreferences.getInstance();
      final lng = prefs.getString('lng') ?? 'ko';

      final res = await dio.get(
        '/saykorean/study/getGenre',
        queryParameters: {'lng': lng}, // 서버가 사용한다면 유지
        options: Options(headers: {'Accept-Language': lng}),
      );

      final raw = res.data;
      final list = (raw is List ? raw : (jsonDecode(raw as String) as List))
          .map((e) => GenreDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() => _items = list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? '요청 실패');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 탭 시 저장
  Future<void> _saveGenre(int genreNo, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedGenreNo', genreNo);
    if (!mounted) return;
    setState(() => _selected = genreNo);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('선택한 장르: $name (No.$genreNo) 저장됨')),
    );

    // 필요 시 화면 전환
    // if (mounted) {
    //   Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MyPage()));
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('장르 선택'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('에러: $_error'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchGenres,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final g = _items[i];
          final selected = _selected == g.genreNo;
          return ListTile(
            leading: CircleAvatar(child: Text('${g.genreNo}')),
            title: Text(g.genreName),
            trailing:
            selected ? const Icon(Icons.check_circle) : null,
            onTap: () => _saveGenre(g.genreNo, g.genreName),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _fetchGenres,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

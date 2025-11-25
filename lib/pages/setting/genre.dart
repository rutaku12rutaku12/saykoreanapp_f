// main.dart — 그대로 복붙해서 실행 가능 (단일 샘플 앱 버전)
// 실제 SayKorean 앱에 넣을 때는 MyApp/Theme는 이미 있으니까
// 아래 GenrePage 부분만 가져가서 pages/... 쪽에 붙여도 됨.

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// 🔥 공통 UI (헤더/버튼)
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

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
// 앱 시작 (샘플용 MyApp)
// 실제 프로젝트에선 이미 MyApp/테마 있으니까 GenrePage만 써도 됨
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
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFFFF9F0),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFAAA5), // 딸기우유 핑크
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF9F0),
          foregroundColor: Color(0xFF6B4E42),
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1E1816),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6B4E42),
          brightness: Brightness.dark,
        ),
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
        queryParameters: {'lng': lng},
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

    // 필요 시 다른 페이지로 이동할 때 여기서 Navigator.pushReplacement 사용
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '장르 선택',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      body: SafeArea(
        child: _loading
            ? Center(
          child: CircularProgressIndicator(
            color: scheme.primary,
          ),
        )
            : _error != null
            ? _buildError(theme, scheme)
            : _buildContent(theme, scheme),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _fetchGenres,
      //   backgroundColor: scheme.primary,
      //   foregroundColor: Colors.white,
      //   child: const Icon(Icons.refresh),
      // ),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '에러가 발생했어요',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SKPrimaryButton(
            label: '다시 시도',
            onPressed: _fetchGenres,
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SKPageHeader(
            title: '장르 선택',
            subtitle: '관심 있는 장르를 선택하면 학습 추천에 활용돼요.',
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text(
                '등록된 장르가 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final g = _items[i];
                final selected = _selected == g.genreNo;

                final cardColor = scheme.surface;
                final borderColor = selected
                    ? scheme.primary.withOpacity(0.5)
                    : scheme.outline.withOpacity(0.15);

                return Material(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(14),
                  elevation: selected ? 3 : 1,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => _saveGenre(g.genreNo, g.genreName),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                            scheme.primary.withOpacity(0.12),
                            child: Text(
                              '${g.genreNo}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              g.genreName,
                              style:
                              theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            color: selected
                                ? scheme.primary
                                : scheme.outline,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

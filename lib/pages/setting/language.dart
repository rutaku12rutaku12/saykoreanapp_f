// language_page.dart — 그대로 복붙해서 사용하세요.
// (라우트는 '/language' 등으로 등록해서 화면 전환하세요. 선택 후 '/info'로 이동하도록 되어 있습니다.)

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 환경별 baseUrl 감지 (dart-define로 API_HOST 넘기면 그것을 우선 사용)
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST'); // 예) --dart-define=API_HOST=http://192.168.0.10:8080
  if (env.isNotEmpty) return env;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080'; // 안드 에뮬레이터→호스트
  return 'http://localhost:8080';                        // iOS 시뮬레이터/데스크톱
}

Locale _toLocale(String code) {
  if (code.contains('-')) {
    final parts = code.split('-');
    return Locale(parts[0], parts[1]);
  }
  return Locale(code);
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 10),
));

// ─────────────────────────────────────────────────────────────────────────────
// DTO
class LanguageDto {
  final int langNo;
  final String langName;

  LanguageDto({required this.langNo, required this.langName});

  factory LanguageDto.fromJson(Map<String, dynamic> j) => LanguageDto(
    langNo: j['langNo'] as int,
    langName: (j['langName'] ?? j['langName_ko'] ?? '').toString(),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 페이지
class LanguagePage extends StatefulWidget {
  const LanguagePage({super.key});

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

class _LanguagePageState extends State<LanguagePage> {
  bool _loading = false;
  String? _error;
  List<LanguageDto> _items = const [];
  int? _selected; // 저장된 선택값 표시용

  // 번호 → 표시명(폴백용)
  static const Map<int, String> _LANG_DISPLAY = {
    1: '한국어',
    2: '日本語',
    3: '中文',
    4: 'English',
    5: 'Español',
  };

  // 번호 → i18n 코드
  static const Map<int, String> _LANG_MAP = {
    1: 'ko',
    2: 'ja',
    3: 'zh-CN',
    4: 'en',
    5: 'es',
  };

  @override
  void initState() {
    super.initState();
    _loadSelected();
    _fetchLanguages();
  }

  Future<void> _loadSelected() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selected = prefs.getInt('selectedLangNo'));
  }

  Future<void> _fetchLanguages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // (옵션) 저장된 언어 코드로 서버에 힌트 전달
      final prefs = await SharedPreferences.getInstance();
      final lng = prefs.getString('lng') ?? 'ko';

      final res = await dio.get(
        '/saykorean/study/getlang',
        options: Options(headers: {'Accept-Language': lng}),
      );

      final raw = res.data;
      final list = (raw is List ? raw : <dynamic>[])
          .map((e) => LanguageDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() => _items = list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? '언어 목록을 불러오지 못했습니다.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = '언어 목록을 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickLang(int langNo, String name) async {
    final n = int.tryParse('$langNo');
    if (n == null || n <= 0) return;

    final prefs = await SharedPreferences.getInstance();
    final code = _LANG_MAP[n] ?? 'ko';

    
    await prefs.setInt('selectedLangNo', n);
    await prefs.setString('lng', code);
    
    await context.setLocale(_toLocale(code));

    if (!mounted) return;
    setState(() => _selected = n);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('언어가 변경되었습니다: $name ($code)')),
    );

    // 필요 시 마이페이지로 이동 (React의 navigate("/mypage") 대응)
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/info', (r) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('언어 선택')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchLanguages,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      )
          : _items.isEmpty
          ? const Center(child: Text('지원 언어가 없습니다.'))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _items.map((l) {
            final isActive = _selected == l.langNo;
            final label =
                _LANG_DISPLAY[l.langNo] ?? l.langName;
            return _PillButton(
              label: label,
              active: isActive,
              onTap: () => _pickLang(l.langNo, label),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UI 컴포넌트: 필(알약) 버튼
class _PillButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = active ? const Color(0xFFFFEEE9) : Colors.white;
    final fg = active ? const Color(0xFFFF7F79) : const Color(0xFF444444);
    final br = active ? const Color(0xFFFFC7C2) : const Color(0xFFE5E7EB);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: br),
            borderRadius: BorderRadius.circular(999),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontWeight: FontWeight.w600,
              fontSize: 14,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),
    );
  }
}

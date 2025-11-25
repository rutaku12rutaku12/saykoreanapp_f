// lib/pages/setting/language_page.dart — 장르 스타일 리스트 버전

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // SKPageHeader, SKPrimaryButton

// ─────────────────────────────────────────────────────────────
// 환경별 baseUrl 감지
// ─────────────────────────────────────────────────────────────
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST');
  if (env.isNotEmpty) return env;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}

Locale _toLocale(String code) {
  if (code.contains('-')) {
    final parts = code.split('-');
    return Locale(parts[0], parts[1]);
  }
  return Locale(code);
}

final Dio dio = Dio(
  BaseOptions(
    baseUrl: _detectBaseUrl(),
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 10),
  ),
);

// ─────────────────────────────────────────────────────────────
// DTO
// ─────────────────────────────────────────────────────────────
class LanguageDto {
  final int langNo;
  final String langName;

  LanguageDto({
    required this.langNo,
    required this.langName,
  });

  factory LanguageDto.fromJson(Map<String, dynamic> j) => LanguageDto(
    langNo: j['langNo'] as int,
    langName: (j['langName'] ?? j['langName_ko'] ?? '').toString(),
  );
}

// ─────────────────────────────────────────────────────────────
// 페이지
// ─────────────────────────────────────────────────────────────
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
      if (mounted) {
        setState(() => _loading = false);
      }
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

    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/info', (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (_loading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SKPrimaryButton(
              label: '다시 시도',
              onPressed: _fetchLanguages,
            ),
          ],
        ),
      );
    } else if (_items.isEmpty) {
      content = const Center(
        child: Text('지원 언어가 없습니다.'),
      );
    } else {
      // ✅ 장르 선택 페이지처럼: 한 줄에 한 언어 카드
      content = ListView.separated(
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final l = _items[index];
          final isActive = _selected == l.langNo;
          final label = _LANG_DISPLAY[l.langNo] ?? l.langName;

          return _LanguageTile(
            index: index + 1,
            label: label,
            active: isActive,
            onTap: () => _pickLang(l.langNo, label),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SKPageHeader(
                title: '언어 선택',
                subtitle: '학습에 사용할 언어를 골라주세요.',
              ),
              const SizedBox(height: 16),
              Expanded(child: content),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 장르 스타일 언어 카드
// ─────────────────────────────────────────────────────────────
class _LanguageTile extends StatelessWidget {
  final int index;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.index,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // 기본 / 민트 / 다크 모두 잘 어울리도록 ColorScheme 기반
    final Color cardBg = active
        ? scheme.secondaryContainer
        : (isDark ? scheme.surfaceContainerHigh : theme.cardColor);
    final Color badgeBg = active
        ? scheme.primary.withOpacity(0.12)
        : scheme.secondaryContainer.withOpacity(isDark ? 0.35 : 0.6);
    final Color badgeText =
    active ? scheme.primary : scheme.onSecondaryContainer;
    final Color textColor =
    active ? scheme.onSecondaryContainer : scheme.onSurface;
    final Color borderColor =
    active ? Colors.transparent : scheme.outline.withOpacity(0.12);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // 왼쪽 번호 원
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: badgeBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: badgeText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // 언어 이름
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 오른쪽 체크/동그라미
              _buildCheck(active, scheme, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheck(bool active, ColorScheme scheme, bool isDark) {
    if (active) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: scheme.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check,
          size: 16,
          color: Colors.white,
        ),
      );
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: scheme.outline.withOpacity(isDark ? 0.7 : 0.5),
          width: 2,
        ),
      ),
    );
  }
}

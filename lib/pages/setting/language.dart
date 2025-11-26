// lib/pages/setting/language.dart
//
// ✅ 장르 페이지와 동일한 구조/스타일로 맞춘 언어 선택 페이지
//    - ApiClient.dio 사용
//    - SKPageHeader / SKPrimaryButton 사용
//    - 장르 카드 스타일 그대로 재사용

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

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

// i18n 코드 → Locale
Locale _toLocale(String code) {
  if (code.contains('-')) {
    final parts = code.split('-');
    return Locale(parts[0], parts[1]);
  }
  return Locale(code);
}

// 번호 → 표시명(폴백용)
const Map<int, String> _LANG_DISPLAY = {
  1: '한국어',
  2: '日本語',
  3: '中文',
  4: 'English',
  5: 'Español',
};

// 번호 → i18n 코드
const Map<int, String> _LANG_MAP = {
  1: 'ko',
  2: 'ja',
  3: 'zh-CN',
  4: 'en',
  5: 'es',
};

// ─────────────────────────────────────────────────────────────
// 언어 페이지
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

  @override
  void initState() {
    super.initState();
    _loadSelected();
    _fetchLanguages();
  }

  // 저장된 선택값 불러오기
  Future<void> _loadSelected() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _selected = prefs.getInt('selectedLangNo'));
  }

  // 언어 목록 호출 (백엔드가 i18n을 수행한다면 lng를 함께 전달)
  Future<void> _fetchLanguages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final lng = prefs.getString('lng') ?? 'ko';

      final res = await ApiClient.dio.get(
        '/saykorean/study/getlang',
        queryParameters: {'lng': lng},
        options: Options(headers: {'Accept-Language': lng}),
      );

      final raw = res.data;
      final list = (raw is List ? raw : (jsonDecode(raw as String) as List))
          .map((e) => LanguageDto.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() => _items = list);
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? 'language.error.load'.tr());
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'language.error.load'.tr());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // 언어 선택 저장 + locale 변경
  Future<void> _saveLanguage(int langNo, String name) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _LANG_MAP[langNo] ?? 'ko';

    await prefs.setInt('selectedLangNo', langNo);
    await prefs.setString('lng', code);

    // EasyLocalization locale 변경
    await context.setLocale(_toLocale(code));

    if (!mounted) return;

    setState(() => _selected = langNo);

    showFooterSnackBar(
      context,
      '선택한 언어: $name ($code) 저장됨',
    );

    // 필요하면 여기서 화면 이동
    // Navigator.of(context).pushNamedAndRemoveUntil('/info', (r) => false);
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
          "language.title".tr(),
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
    );
  }

  // 에러 UI (장르 페이지와 동일 패턴)
  Widget _buildError(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "common.errorOccurred".tr(),
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
            label: "common.retry".tr(),
            onPressed: _fetchLanguages,
          ),
        ],
      ),
    );
  }

  // 정상 컨텐츠 UI (장르 페이지와 동일 레이아웃)
  Widget _buildContent(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SKPageHeader(
            title: "language.title".tr(),
            subtitle: "study.language.select".tr(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text(
                "study.language.none".tr(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.6),
                ),
              ),
            )
                : ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) =>
              const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final l = _items[i];
                final selected = _selected == l.langNo;

                final displayName =
                    _LANG_DISPLAY[l.langNo] ?? l.langName;

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
                    onTap: () =>
                        _saveLanguage(l.langNo, displayName),
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
                              '${l.langNo}',
                              style: theme.textTheme.bodyMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: scheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              displayName,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(
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

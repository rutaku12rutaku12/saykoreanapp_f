// lib/pages/setting/genre.dart
//
// ✅ SayKorean 공통 테마 + ApiClient + SKPageHeader / SKPrimaryButton 적용 버전
//    그대로 붙여넣고, 필요한 곳에서 GenrePage()로 라우팅해서 사용하면 됨.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';
import 'package:easy_localization/easy_localization.dart';

// ─────────────────────────────────────────────────────────────
// DTO
// ─────────────────────────────────────────────────────────────

class GenreDto {
  final int genreNo;
  final String genreName;

  GenreDto({required this.genreNo, required this.genreName});

  factory GenreDto.fromJson(Map<String, dynamic> j) => GenreDto(
    genreNo: j['genreNo'] as int,
    genreName: (j['genreName'] ?? j['genreName_ko'] ?? '').toString(),
  );
}

// ─────────────────────────────────────────────────────────────
// 장르 페이지
// ─────────────────────────────────────────────────────────────

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
      // 저장된 언어 코드 (웹/앱에서 이미 관리 중이면 그 값 활용)
      final prefs = await SharedPreferences.getInstance();
      final lng = prefs.getString('lng') ?? 'ko';

      final res = await ApiClient.dio.get(
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

  // 탭 시 선택 저장
  Future<void> _saveGenre(int genreNo, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedGenreNo', genreNo);
    if (!mounted) return;

    setState(() => _selected = genreNo);

    showFooterSnackBar(
      context,
      '선택한 장르: $name (No.$genreNo) 저장됨',
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
          "genre.title".tr(),
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

  // 에러 UI
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
            onPressed: _fetchGenres,
          ),
        ],
      ),
    );
  }

  // 정상 컨텐츠 UI
  Widget _buildContent(ThemeData theme, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SKPageHeader(
            title: "genre.title".tr(),
            subtitle: "genre.selectHint".tr(),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _items.isEmpty
                ? Center(
              child: Text(
                "genre.empty".tr(),
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
                              g.genreName,
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

// lib/pages/store/store.dart

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart'; // ApiClient.dio 사용

// main.dart는 prefix로 가져오기 (테마 변경용)
import 'package:saykoreanapp_f/main.dart' as AppMain;

// UI 공통 (FooterSafeArea, themeColorNotifier 등)
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _loading = false;
  String? _error;

  int? _pointBalance; // 내 포인트 잔액
  bool _hasDarkTheme = false; // 다크 테마 보유 여부
  bool _hasMintTheme = false; // 민트 테마 보유 여부

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      _hasDarkTheme = prefs.getBool('hasDarkTheme') ?? false;
      _hasMintTheme = prefs.getBool('hasMintTheme') ?? false;

      _pointBalance = await _fetchPointBalance();

      setState(() {});
    } catch (e) {
      setState(() {
        _error = '스토어 정보를 불러오지 못했어요.\n잠시 후 다시 시도해 주세요.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1) 포인트 잔액 조회
  // ─────────────────────────────────────────────────────────────
  Future<int> _fetchPointBalance() async {
    try {
      final res = await ApiClient.dio.get(
        '/saykorean/store/point',
        options: Options(validateStatus: (status) => true),
      );

      debugPrint('[Store] point status = ${res.statusCode}, data = ${res.data}');

      if (res.statusCode == 200) {
        final data = res.data;
        if (data is int) return data;
        if (data is String) return int.tryParse(data) ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('point balance fetch error: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 테마 적용
  // ─────────────────────────────────────────────────────────────
  Future<void> _applyTheme(String themeKey) async {
    switch (themeKey) {
      case 'dark':
        await AppMain.setThemeMode(ThemeMode.dark);
        break;
      case 'mint':
        await AppMain.setThemeMode(ThemeMode.light);
        await AppMain.setThemeColor('mint');
        break;
      default:
        await AppMain.setThemeMode(ThemeMode.light);
        await AppMain.setThemeColor('default');
        break;
    }

    if (!mounted) return;

    String label;
    switch (themeKey) {
      case 'dark':
        label = "theme.changed.dark".tr();
        break;
      case 'mint':
        label = "theme.changed.mint".tr();
        break;
      default:
        label = "theme.changed.default".tr();
    }

    showFooterSnackBar(
      context,
      label,
      duration: Duration(seconds: 2),
    );




  }

  // ─────────────────────────────────────────────────────────────
  // 2) 다크 테마 구매 API
  // ─────────────────────────────────────────────────────────────
  Future<bool> _purchaseDarkTheme() async {
    try {
      final res = await ApiClient.dio.post(
        '/saykorean/store/theme/1/buy',
        options: Options(validateStatus: (status) => true),
      );

      debugPrint('[Store] buy dark status = ${res.statusCode}, data = ${res.data}');

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final success = data['success'] == true;
        if (success) {
          final newPoint = data['newPoint'];
          if (newPoint != null) {
            setState(() {
              _pointBalance = int.tryParse(newPoint.toString()) ?? _pointBalance;
            });
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('purchase dark theme error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3) 민트 테마 구매 API
  // ─────────────────────────────────────────────────────────────
  Future<bool> _purchaseMintTheme() async {
    try {
      final res = await ApiClient.dio.post(
        '/saykorean/store/theme/2/buy',
        options: Options(validateStatus: (status) => true),
      );

      debugPrint('[Store] buy mint status = ${res.statusCode}, data = ${res.data}');

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data as Map;
        final success = data['success'] == true;
        if (success) {
          final newPoint = data['newPoint'];
          if (newPoint != null) {
            setState(() {
              _pointBalance = int.tryParse(newPoint.toString()) ?? _pointBalance;
            });
          }
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('purchase mint theme error: $e');
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4) 다크 테마 구매 버튼
  // ─────────────────────────────────────────────────────────────
  Future<void> _onTapBuyDarkTheme() async {
    if (_pointBalance == null) return;

    const int price = 2000;

    if (_pointBalance! < price) {
      showFooterSnackBar(
        context,
        "store.buy.notEnough".tr(),
      );
      return;
    }


    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("store.buy.dark".tr()),
        content: Text("store.buy.dark.confirm".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("store.buy".tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final success = await _purchaseDarkTheme();

    setState(() => _loading = false);

    if (!success) {
      showFooterSnackBar(
        context,
        "store.buy.fail".tr(),
      );
      return;
    }


    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasDarkTheme', true);

    setState(() {
      _hasDarkTheme = true;
    });

    showFooterSnackBar(
      context,
      "store.buy.success.dark".tr(),
    );

  }

  // ─────────────────────────────────────────────────────────────
  // 5) 민트 테마 구매 버튼
  // ─────────────────────────────────────────────────────────────
  Future<void> _onTapBuyMintTheme() async {
    if (_pointBalance == null) return;

    const int price = 2000;

    if (_pointBalance! < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("store.buy.notEnough".tr())),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("store.buy.mint".tr()),
        content: Text("store.buy.mint.confirm".tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("common.cancel".tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text("store.buy".tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final success = await _purchaseMintTheme();

    setState(() => _loading = false);

    if (!success) {
      showFooterSnackBar(
        context,
        "store.buy.fail".tr(),
      );

      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasMintTheme', true);

    setState(() {
      _hasMintTheme = true;
    });

    showFooterSnackBar(
      context,
      "store.buy.success.mint".tr(),
    );

  }

  // ─────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isMintTheme = themeColorNotifier.value == 'mint';

    final bg = theme.scaffoldBackgroundColor;

    // 앱바/섹션 타이틀 컬러
    final Color mainTitleColor = isDark
        ? (theme.appBarTheme.foregroundColor ?? scheme.onSurface)
        : (isMintTheme
        ? const Color(0xFF2F7A69) // 민트 테마일 때
        : const Color(0xFFFFAAA5)); // 기본(핑크)

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: mainTitleColor),
        title: Text(
          "store.title".tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            color: mainTitleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: FooterSafeArea(
          child: _loading && _pointBalance == null
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? _buildErrorView(theme, scheme)
              : _buildContent(theme, scheme, isDark, isMintTheme, mainTitleColor),
        ),
      ),
    );
  }

  Widget _buildErrorView(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: scheme.error, size: 40),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _bootstrap,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEEE9),
                foregroundColor: const Color(0xFF6B4E42),
                elevation: 0,
              ),
              child: const Text("common.retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
      ThemeData theme,
      ColorScheme scheme,
      bool isDark,
      bool isMintTheme,
      Color mainTitleColor,
      ) {
    final balanceText =
    _pointBalance == null ? '불러오는 중...' : '${_pointBalance} P';

    // 포인트 글씨 색: 다크모드면 흰색, 민트테마면 민트, 기본은 핑크
    final Color pointTextColor = isDark
        ? Colors.white
        : (isMintTheme ? const Color(0xFF2F7A69) : const Color(0xFFFFAAA5));

    final Color sectionTitleColor = mainTitleColor;

    return RefreshIndicator(
      onRefresh: _bootstrap,
      color: const Color(0xFFFFAAA5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // 내 포인트 박스
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceVariant : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                isDark ? scheme.outline.withOpacity(0.4) : const Color(0xFFE5E7EB),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Color(0xFFFFC857), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "store.points".tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: sectionTitleColor,
                    ),
                  ),
                ),
                Text(
                  balanceText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: pointTextColor,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            "theme.section".tr(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: sectionTitleColor,
            ),
          ),
          const SizedBox(height: 12),

          _buildDefaultThemeItem(theme),
          const SizedBox(height: 12),
          _buildDarkThemeItem(theme, isDark),
          const SizedBox(height: 12),
          _buildMintThemeItem(theme, isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 기본 테마 카드 (항상 핑크 계열)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDefaultThemeItem(ThemeData theme) {
    const titleColor = Color(0xFFFFAAA5);
    const descColor = Color(0xFF6B4E42);
    const freeColor = Color(0xFFFFAAA5);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFE5CF),
                  Color(0xFFFFF3E0),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  right: 6,
                  top: 8,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(0xFFFFAAA5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 14,
                  top: 24,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                const Positioned(
                  left: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      _DefaultDot(),
                      SizedBox(width: 4),
                      _DefaultDot(),
                      SizedBox(width: 4),
                      _DefaultDot(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "theme.default".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "theme.default.desc".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: descColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: freeColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "store.free".tr(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: freeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 버튼 (항상 핑크 계열)
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: () => _applyTheme('default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFEEE9),
                foregroundColor: freeColor,
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text("theme.change".tr()),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 다크 테마 카드 (항상 브라운 계열, 버튼도 브라운)
  // ─────────────────────────────────────────────────────────────
  Widget _buildDarkThemeItem(ThemeData theme, bool isDarkMode) {
    const int price = 2000;
    final bool owned = _hasDarkTheme;
    final bool disabled = !owned && (_pointBalance ?? 0) < price;

    const Color titleColor = Color(0xFF6B4E42);
    const Color descColor = Color(0xFF7C5A48);
    // 다크 모드일 때 포인트 글씨는 흰색
    final Color priceColor = isDarkMode ? Colors.white : const Color(0xFF6B4E42);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF261E1B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3A2D28) : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF111827),
                  Color(0xFF1F2933),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 8,
                  right: 8,
                  top: 10,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF374151),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 18,
                  top: 26,
                  height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF4B5563),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 32,
                  top: 36,
                  height: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B7280),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: 12,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF111827),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "theme.dark".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "theme.dark.desc".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: descColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.stars,
                      size: 16,
                      color: Color(0xFFFFC857),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$price P',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 버튼 – 항상 브라운 계열 사용
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: disabled
                  ? null
                  : (owned ? () => _applyTheme('dark') : _onTapBuyDarkTheme),
              style: ElevatedButton.styleFrom(
                backgroundColor: owned
                    ? const Color(0xFF6B4E42) // 소유중이면 진한 브라운 풀 필
                    : const Color(0xFFFFEEE9), // 미소유면 연살구 배경
                foregroundColor: owned
                    ? Colors.white // 소유중일 때 텍스트 흰색
                    : const Color(0xFF6B4E42), // 미소유일 땐 브라운 텍스트
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                owned
                    ? "theme.change".tr()
                    : (_pointBalance != null && _pointBalance! < price
                    ? "store.lack".tr()
                    : "store.buy".tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 민트 테마 카드 (항상 민트 계열)
  // ─────────────────────────────────────────────────────────────
  Widget _buildMintThemeItem(ThemeData theme, bool isDarkMode) {
    const int price = 2000;
    final bool owned = _hasMintTheme;
    final bool disabled = !owned && (_pointBalance ?? 0) < price;

    const Color titleColor = Color(0xFF064E3B);
    const Color descColor = Color(0xFF047857);
    final Color priceColor = isDarkMode ? Colors.white : const Color(0xFF047857);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF261E1B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDarkMode ? const Color(0xFF3A2D28) : const Color(0xFFE5E7EB),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 썸네일
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA8E6CF),
                  Color(0xFFD0FFF5),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  left: 6,
                  right: 6,
                  top: 8,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F7A69),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 8,
                  right: 14,
                  top: 24,
                  height: 12,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: Row(
                    children: [
                      _mintDot(),
                      const SizedBox(width: 4),
                      _mintDot(),
                      const SizedBox(width: 4),
                      _mintDot(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),

          // 텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "theme.mint".tr(),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "theme.mint.desc".tr(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: descColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.stars,
                      size: 16,
                      color: Color(0xFF34D399),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$price P',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 버튼 – 민트 계열 고정
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: disabled
                  ? null
                  : (owned ? () => _applyTheme('mint') : _onTapBuyMintTheme),
              style: ElevatedButton.styleFrom(
                backgroundColor: owned
                    ? const Color(0xFF2F7A69)
                    : const Color(0xFFE0FFF5),
                foregroundColor:
                owned ? Colors.white : const Color(0xFF064E3B),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                owned
                    ? "theme.change".tr()
                    : (_pointBalance != null && _pointBalance! < price
                    ? "store.lack".tr()
                    : "store.buy".tr()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 민트 썸네일용 점
  Widget _mintDot() {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFF2F7A69),
        shape: BoxShape.circle,
      ),
    );
  }
}

// 기본 테마 썸네일용 점
class _DefaultDot extends StatelessWidget {
  const _DefaultDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: Color(0xFFFFAAA5),
        shape: BoxShape.circle,
      ),
    );
  }
}

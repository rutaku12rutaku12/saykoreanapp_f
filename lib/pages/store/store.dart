// lib/pages/store/store.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart'; // ApiClient.dio 사용
import 'package:saykoreanapp_f/main.dart' show setThemeMode, setThemeColor;

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _loading = false;
  String? _error;

  int? _pointBalance;          // 내 포인트 잔액
  bool _hasDarkTheme = false;  // 다크 테마 보유 여부 (로컬 캐시)
  bool _hasMintTheme = false;  // 민트 테마 보유 여부 (로컬 캐시)

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

      // 이미 구매한 적 있는지 (로컬에 저장된 플래그)
      _hasDarkTheme = prefs.getBool('hasDarkTheme') ?? false;
      _hasMintTheme = prefs.getBool('hasMintTheme') ?? false;

      // 포인트 잔액 불러오기
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
  //   GET /saykorean/store/point
  //   → 응답: 1234 (int)
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
        if (data is int) {
          return data;
        }
        if (data is String) {
          return int.tryParse(data) ?? 0;
        }
      }

      return 0;
    } catch (e) {
      debugPrint('point balance fetch error: $e');
      return 0;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 1-1) 테마 적용 (선택된 테마를 로컬에 저장)
  //   - themeKey 예: 'dark', 'mint', 'default'
  //   - 실제 앱 전체 테마 변경은 상위(MyApp 등)에서
  //     SharedPreferences의 selectedTheme를 읽어서 처리
  // ─────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────
  // 1-1) 테마 적용 (전역 themeMode/themeColor 사용)
  //   - 'dark'  : 다크 모드
  //   - 'mint'  : 라이트 + 민트 팔레트
  //   - 'default': 라이트 + 기본(핑크) 팔레트
  // ─────────────────────────────────────────────────────────────
  Future<void> _applyTheme(String themeKey) async {
    switch (themeKey) {
      case 'dark':
      // 다크 테마: ThemeMode.dark
        await setThemeMode(ThemeMode.dark);
        break;
      case 'mint':
      // 민트 테마: 라이트 모드 + 민트 색상
        await setThemeMode(ThemeMode.light);
        await setThemeColor('mint');
        break;
      default:
      // 기본 테마: 라이트 모드 + default 색상
        await setThemeMode(ThemeMode.light);
        await setThemeColor('default');
        break;
    }

    if (!mounted) return;

    String label;
    switch (themeKey) {
      case 'dark':
        label = '다크 테마로 변경했어요.';
        break;
      case 'mint':
        label = '민트 테마로 변경했어요.';
        break;
      default:
        label = '기본 테마로 변경했어요.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }


  // ─────────────────────────────────────────────────────────────
  // 2) 다크 테마 구매 API 호출
  //
  //   POST /saykorean/store/theme/1/buy
  //   응답: { "success": true, "newPoint": 900 }
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
  // 3) 민트 테마 구매 API 호출
  //
  //   POST /saykorean/store/theme/2/buy
  //   응답: { "success": true, "newPoint": 900 }
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
  // 4) 다크 테마 구매 버튼 핸들러
  // ─────────────────────────────────────────────────────────────
  Future<void> _onTapBuyDarkTheme() async {
    if (_pointBalance == null) return;

    const int price = 2000; // 테마 가격

    if (_pointBalance! < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트가 부족해요.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다크 테마 구매'),
        content: Text('$price 포인트를 사용해서 다크 테마를 구매할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('구매'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final success = await _purchaseDarkTheme();

    setState(() => _loading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매에 실패했어요. 다시 시도해 주세요.')),
      );
      return;
    }

    // 로컬 캐시 업데이트
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasDarkTheme', true);

    setState(() {
      _hasDarkTheme = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('다크 테마가 해금되었어요! 설정에서 변경할 수 있어요.')),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 5) 민트 테마 구매 버튼 핸들러
  // ─────────────────────────────────────────────────────────────
  Future<void> _onTapBuyMintTheme() async {
    if (_pointBalance == null) return;

    const int price = 2000;

    if (_pointBalance! < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트가 부족해요.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('민트 테마 구매'),
        content: Text('$price 포인트를 사용해서 민트 테마를 구매할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('구매'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final success = await _purchaseMintTheme();

    setState(() => _loading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매에 실패했어요. 다시 시도해 주세요.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasMintTheme', true);

    setState(() {
      _hasMintTheme = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('민트 테마가 해금되었어요! 설정에서 변경할 수 있어요.')),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bg = theme.scaffoldBackgroundColor;
    final titleColor =
    isDark ? scheme.onSurface : const Color(0xFF6B4E42);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: titleColor),
        title: Text(
          '스토어',
          style: theme.textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading && _pointBalance == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildErrorView(theme, scheme)
          : _buildContent(theme, scheme, isDark),
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
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, ColorScheme scheme, bool isDark) {
    final balanceText = _pointBalance == null
        ? '불러오는 중...'
        : '${_pointBalance} P';

    return RefreshIndicator(
      onRefresh: _bootstrap,
      color: const Color(0xFFFFAAA5),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        children: [
          // ── 내 포인트 박스
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? scheme.surfaceVariant : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? scheme.outline.withOpacity(0.4)
                    : const Color(0xFFE5E7EB),
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
                    '내 포인트',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  balanceText,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF6B4E42),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Text(
            '테마',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? scheme.onSurface : const Color(0xFF6B4E42),
            ),
          ),
          const SizedBox(height: 12),

          // 다크 테마 카드
          _buildDarkThemeItem(theme, scheme, isDark),
          const SizedBox(height: 12),

          // 민트 테마 카드
          _buildMintThemeItem(theme, scheme, isDark),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 다크 테마 아이템 카드
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildDarkThemeItem(
      ThemeData theme, ColorScheme scheme, bool isDark) {
    const int price = 2000;
    final bool owned = _hasDarkTheme;
    final bool disabled = !owned && (_pointBalance ?? 0) < price;

    final titleColor =
    isDark ? scheme.onSurface : const Color(0xFF111827);
    final descColor =
    isDark ? scheme.onSurface.withOpacity(0.7) : const Color(0xFF6B7280);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? scheme.outline.withOpacity(0.4)
              : const Color(0xFFE5E7EB),
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
          // 미리보기 썸네일 (다크)
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
                  '다크 테마',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '밤에도 눈 편하게 학습할 수 있는 고급스러운 다크 모드예요.',
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
                        color: const Color(0xFF6B4E42),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 버튼
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: disabled
                  ? null
                  : (owned
                  ? () => _applyTheme('dark')   // 이미 보유 → 테마 변경
                  : _onTapBuyDarkTheme),        // 미보유 → 구매
              style: ElevatedButton.styleFrom(
                backgroundColor: owned
                    ? (isDark
                    ? scheme.primaryContainer
                    : const Color(0xFFD1FAE5))
                    : const Color(0xFFFFEEE9),
                foregroundColor: owned
                    ? (isDark
                    ? scheme.onPrimaryContainer
                    : const Color(0xFF047857))
                    : const Color(0xFF6B4E42),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                owned
                    ? '테마 변경'
                    : (_pointBalance != null && _pointBalance! < price
                    ? '포인트 부족'
                    : '구매'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 민트 테마 아이템 카드 (핑크 대신 민트 위주 테마)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMintThemeItem(
      ThemeData theme, ColorScheme scheme, bool isDark) {
    const int price = 2000;
    final bool owned = _hasMintTheme;
    final bool disabled = !owned && (_pointBalance ?? 0) < price;

    final titleColor =
    isDark ? scheme.onSurface : const Color(0xFF064E3B);
    final descColor =
    isDark ? scheme.onSurface.withOpacity(0.7) : const Color(0xFF047857);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? scheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? scheme.outline.withOpacity(0.4)
              : const Color(0xFFE5E7EB),
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
          // 미리보기 썸네일 (민트 테마)
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFA8E6CF), // 민트
                  Color(0xFFD0FFF5), // 더 연한 민트
                ],
              ),
            ),
            child: Stack(
              children: [
                // 상단 바
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
                // 중간 카드
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
                // 하단 점 3개 (버튼 느낌)
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
                  '민트 테마',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '핑크 대신 민트 중심의 상큼한 파스텔 테마예요.\n맑고 산뜻한 분위기로 공부하고 싶을 때 좋아요.',
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
                        color: const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 버튼
          SizedBox(
            height: 40,
            child: ElevatedButton(
              onPressed: disabled
                  ? null
                  : (owned
                  ? () => _applyTheme('mint')
                  : _onTapBuyMintTheme),
              style: ElevatedButton.styleFrom(
                backgroundColor: owned
                    ? (isDark
                    ? const Color(0xFF064E3B)
                    : const Color(0xFFD1FAE5))
                    : const Color(0xFFE0FFF5),
                foregroundColor: owned
                    ? (isDark
                    ? Colors.white
                    : const Color(0xFF047857))
                    : const Color(0xFF064E3B),
                elevation: 0,
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                owned
                    ? '테마 변경'
                    : (_pointBalance != null && _pointBalance! < price
                    ? '포인트 부족'
                    : '구매'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 민트 썸네일용 점 1개
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

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:saykoreanapp_f/api/api.dart';

class StorePage extends StatefulWidget {
  const StorePage({super.key});

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  bool _loading = false;
  String? _error;

  int? _pointBalance;          // 내 포인트 잔액
  bool _hasDarkTheme = false;  // 다크 테마 구매 여부

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
      _pointBalance = await _fetchPointBalance();

      setState(() {});
    } catch (e) {
      setState(() => _error = '스토어 정보를 불러오지 못했어요.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ───────────────────────────────────────────────
  // 포인트 잔액 조회
  // GET /saykorean/point/balance → { point: 123 }
  // ───────────────────────────────────────────────
  Future<int> _fetchPointBalance() async {
    try {
      final res = await ApiClient.dio.get(
        '/saykorean/point/balance',
        options: Options(validateStatus: (status) => true),
      );

      if (res.statusCode == 200) {
        final data = res.data;

        if (data is Map && data['point'] != null) {
          return int.tryParse(data['point'].toString()) ?? 0;
        } else if (data is int) {
          return data;
        }
      }

      return 0; // 응답 형식이 불명확하면 기본값
    } catch (e) {
      return 0; // 예외 발생시에도 반드시 int 반환
    }
  }


  // ───────────────────────────────────────────────
  // 다크 테마 구매 요청
  // POST /saykorean/store/buy-dark-theme
  // ───────────────────────────────────────────────
  Future<bool> _purchaseDarkTheme() async {
    try {
      final res = await ApiClient.dio.post(
        '/saykorean/store/buy-dark-theme',
        data: {"itemCode": "DARK_THEME"},
        options: Options(validateStatus: (status) => true),
      );

      if (res.statusCode == 200 && res.data is Map) {
        final data = res.data;

        if (data['success'] == true) {
          final newPoint = data['newPoint'];
          if (newPoint != null) {
            setState(() => _pointBalance = int.tryParse(newPoint.toString()) ?? _pointBalance);
          }
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // 구매 버튼 클릭
  Future<void> _onTapBuyDarkTheme() async {
    if (_pointBalance == null) return;

    const price = 2000;

    if (_pointBalance! < price) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('포인트가 부족해요.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('다크 테마 구매'),
        content: const Text('2000 포인트로 다크 테마를 구매할까요?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('구매')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);

    final success = await _purchaseDarkTheme();

    setState(() => _loading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('구매에 실패했어요.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasDarkTheme', true);

    setState(() => _hasDarkTheme = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('다크 테마가 해금되었어요!')),
    );
  }

  // ───────────────────────────────────────────────
  // UI
  // ───────────────────────────────────────────────
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
        centerTitle: true,
        elevation: 0,
        backgroundColor: bg,
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
            Text(_error!, textAlign: TextAlign.center),
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
    final balanceText =
    _pointBalance == null ? '불러오는 중...' : '${_pointBalance} P';

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

          _buildDarkThemeItem(theme, scheme, isDark),
        ],
      ),
    );
  }

  // 다크 테마 아이템 카드
  Widget _buildDarkThemeItem(
      ThemeData theme, ColorScheme scheme, bool isDark) {
    const int price = 2000;
    final bool disabled = _hasDarkTheme || (_pointBalance ?? 0) < price;

    final titleColor =
    isDark ? scheme.onSurface : const Color(0xFF111827);
    final descColor =
    isDark ? scheme.onSurface.withOpacity(0.7) : const Color(0xFF6B7280);

    return Container(
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
          // 아이콘 영역
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1F2933),
                  Color(0xFF111827),
                ],
              ),
            ),
            child: const Icon(Icons.dark_mode, color: Colors.white, size: 30),
          ),

          const SizedBox(width: 14),

          // 텍스트 설명
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
                  '밤에도 눈 편하게 학습할 수 있는 다크 모드 테마예요.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: descColor,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.stars,
                        size: 16, color: Color(0xFFFFC857)),
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
              onPressed: disabled ? null : _onTapBuyDarkTheme,
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasDarkTheme
                    ? (isDark
                    ? scheme.primaryContainer
                    : const Color(0xFFD1FAE5))
                    : const Color(0xFFFFEEE9),
                foregroundColor: _hasDarkTheme
                    ? (isDark
                    ? scheme.onPrimaryContainer
                    : const Color(0xFF047857))
                    : const Color(0xFF6B4E42),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                _hasDarkTheme
                    ? '구매완료'
                    : ((_pointBalance ?? 0) < price ? '포인트 부족' : '구매'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

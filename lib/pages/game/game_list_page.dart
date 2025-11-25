// lib/pages/game/game_list_page.dart

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/game_api.dart';
import 'package:saykoreanapp_f/pages/game/game_play_page.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart'; // ✅ 공통 UI 헤더 사용

class GameListPage extends StatefulWidget {
  const GameListPage({super.key});

  @override
  _GameListPageState createState() => _GameListPageState();
}

class _GameListPageState extends State<GameListPage> {
  List<dynamic> _games = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  // 게임 목록 불러오기
  Future<void> _loadGames() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final games = await GameApi.getGameList();

      setState(() {
        _games = games;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '게임 목록을 불러오는데 실패했습니다.';
        _isLoading = false;
      });
      print('게임 목록 로드 실패: $e');
    }
  }

  // 게임 선택 시 플레이 페이지로 이동
  void _onGameTap(dynamic game) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GamePlayPage(
          gameNo: game['gameNo'],
          gameTitle: game['gameTitle'],
        ),
      ),
    );
  }

  // 게임 아이콘 결정
  IconData _getGameIcon(int gameNo) {
    switch (gameNo) {
      case 1:
        return Icons.sports_esports; // 토돌이 한글 받기
      case 2:
        return Icons.catching_pokemon; // 한글 수박게임
      default:
        return Icons.gamepad;
    }
  }

  // 게임 색상 결정 (아이콘/포인트 컬러용)
  Color _getGameColor(int gameNo) {
    switch (gameNo) {
      case 1:
        return const Color(0xFF667EEA); // 보라색
      case 2:
        return const Color(0xFF38ADA9); // 청록색
      default:
        return const Color(0xFFFFAAA5); // 코랄핑크
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '게임 선택',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.appBarTheme.foregroundColor ?? scheme.primary,
          ),
        ),
        iconTheme: IconThemeData(
          color: theme.appBarTheme.foregroundColor ?? scheme.primary,
        ),
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: scheme.primary,
        ),
      )
          : _errorMessage != null
          ? _buildError(theme, scheme)
          : _games.isEmpty
          ? _buildEmpty(theme, scheme)
          : _buildList(theme, scheme, isDark),
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: scheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: _loadGames,
                child: const Text('다시 시도'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.games_outlined,
              size: 64,
              color: scheme.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              '등록된 게임이 없습니다.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onBackground.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 SKPageHeader + 리스트 통합
  Widget _buildList(ThemeData theme, ColorScheme scheme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadGames,
      color: scheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        itemCount: _games.length + 1, // 0 = 헤더, 나머지 카드
        itemBuilder: (context, index) {
          if (index == 0) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                SKPageHeader(
                  title: '게임 선택',
                  subtitle: '재밌는 게임으로 한글을 더 익혀볼까요?',
                ),
                SizedBox(height: 16),
              ],
            );
          }

          final game = _games[index - 1];
          final gameNo = game['gameNo'] ?? 0;
          final gameTitle = game['gameTitle'] ?? '제목 없음';
          final gameColor = _getGameColor(gameNo);
          final gameIcon = _getGameIcon(gameNo);

          final cardColor =
          isDark ? scheme.surface : scheme.surfaceContainer;
          final iconBoxColor =
          isDark ? scheme.surfaceVariant : scheme.surface;
          final titleColor =
          isDark ? scheme.onSurface : const Color(0xFF333333);
          final subtitleColor = isDark
              ? scheme.onSurface.withOpacity(0.7)
              : const Color(0xFF999999);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Material(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              elevation: 2,
              child: InkWell(
                onTap: () => _onGameTap(game),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: cardColor,
                    border: Border.all(
                      color: scheme.outline.withOpacity(0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      // 게임 아이콘 박스
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: iconBoxColor,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                              color: Colors.black.withOpacity(0.06),
                            ),
                          ],
                        ),
                        child: Icon(
                          gameIcon,
                          size: 32,
                          color: gameColor,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // 게임 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameTitle,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: titleColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Game #$gameNo',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: subtitleColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios,
                        size: 20,
                        color: gameColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// lib/pages/game_list_page.dart

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/game_api.dart';
import 'package:saykoreanapp_f/pages/game/game_play_page.dart';

class GameListPage extends StatefulWidget {
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

    // ✅ 배경은 전역 테마가 정한 scaffoldBackgroundColor 사용
    final bgColor = theme.scaffoldBackgroundColor;
    final titleColor = isDark ? scheme.onSurface : const Color(0xFF333333);
    final iconColor = titleColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '게임 선택',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: titleColor,
          ),
        ),
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: iconColor),
      ),
      backgroundColor: bgColor,
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
          : _buildList(theme, scheme, isDark), // ✅ isDark까지 같이 전달
    );
  }

  Widget _buildError(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ElevatedButton(
            onPressed: _loadGames,
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme, ColorScheme scheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          ),
        ],
      ),
    );
  }

  // 🔥 여기서 isDark를 세 번째 인자로 받는다
  Widget _buildList(ThemeData theme, ColorScheme scheme, bool isDark) {
    return RefreshIndicator(
      onRefresh: _loadGames,
      color: scheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _games.length,
        itemBuilder: (context, index) {
          final game = _games[index];
          final gameNo = game['gameNo'] ?? 0;
          final gameTitle = game['gameTitle'] ?? '제목 없음';
          final gameColor = _getGameColor(gameNo);
          final gameIcon = _getGameIcon(gameNo);

          // ✅ 카드/텍스트 색상: 테마 surface/surfaceContainer 사용
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
              elevation: 3,
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
                              color: Colors.black.withOpacity(0.08),
                            ),
                          ],
                        ),
                        child: Icon(
                          gameIcon,
                          size: 32,
                          // 포인트 컬러만 gameColor
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
                      // 화살표 아이콘
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

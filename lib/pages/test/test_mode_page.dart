// lib/pages/test/test_mode_page.dart

// ✅ 시험 모드 선택 페이지
// - 정기시험 : 관리자가 만든 주제별 시험 목록
// - 무한모드 : 완료한 주제의 모든 문항(틀릴 때까지)
// - 하드모드 : 전체 DB의 모든 문항 (틀릴 때까지)

import 'package:flutter/material.dart';
import 'package:saykoreanapp_f/api/api.dart';
import 'package:saykoreanapp_f/pages/test/test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saykoreanapp_f/ui/saykorean_ui.dart';

class TestModePage extends StatefulWidget {
  const TestModePage({super.key});

  @override
  State<TestModePage> createState() => _TestModePageState();
}

class _TestModePageState extends State<TestModePage> {
  bool _loading = false;
  String? _error;
  int _langNo = 1;
  List<dynamic> _regularTests = const [];

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  // 1. 시험 목록 불러오기
  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      _langNo = prefs.getInt('selectedLangNo') ?? 1;

      // 완료한 주제(studyNo) 목록 가져오기
      final storedIds = prefs.getStringList('studies') ?? const <String>[];
      final List<int> completedStudyNos = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      print("📚 완료한 주제: $completedStudyNos");

      // 정기시험 목록 조회
      if (completedStudyNos.isEmpty) {
        setState(() => _regularTests = []);
        return;
      }

      // 완료한 주제별로 시험 조회
      final futures = completedStudyNos.map((id) => _fetchTestsByStudy(id));
      final results = await Future.wait(futures, eagerError: false);

      final merged = <dynamic>[];
      for (final list in results) {
        // testMode가 "REGULAR"인 시험만 필터링
        final regularOnly = list.where((test) {
          final mode = test['testMode'] as String?;
          return mode == null || mode == 'REGULAR';
        }).toList();
        merged.addAll(regularOnly);
      }

      setState(() {
        _regularTests = merged;
      });
    } catch (e, st) {
      print("TestModePage _bootstrap error: $e");
      print(st);
      setState(() {
        _error = '시험 목록을 불러오는 중 문제가 발생했습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  // 2. 시험목록 선택 불러오기
  Future<List<dynamic>> _fetchTestsByStudy(int studyNo) async {
    try {
      print("_fetchTestsByStudy(studyNo=$studyNo, langNo=$_langNo");
      final res = await ApiClient.dio.get(
        '/saykorean/test/by-study',
        queryParameters: {
          'studyNo': studyNo,
          'langNo': _langNo,
        },
      );

      print("▶ by-study($studyNo) status  = ${res.statusCode}");
      print("▶ by-study($studyNo) data    = ${res.data}");

      if (res.data is List) {
        return res.data as List;
      }
      return const [];
    } catch (e, st) {
      print("_fetchTestsByStudy error(studyNo=$studyNo): $e");
      print(st);
      return const [];
    }
  }

  // 정기시험 선택
  void _onTapRegularTest(dynamic test) {
    final rawTestNo = test['testNo'];
    final testNo = (rawTestNo is int)
        ? rawTestNo
        : (rawTestNo is num)
        ? rawTestNo.toInt()
        : int.tryParse(rawTestNo?.toString() ?? "0") ?? 0;

    print("정기시험 선택: testNo=$testNo");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestPage(
          testNo: testNo,
          testMode: "REGULAR",
        ),
      ),
    );
  }

  // ♾️ 무한모드 시작
  void _startInfiniteMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedIds = prefs.getStringList('studies') ?? const <String>[];
      final completedStudyNos = storedIds
          .map((s) => int.tryParse(s))
          .where((n) => n != null && n! > 0)
          .cast<int>()
          .toList();

      if (completedStudyNos.isEmpty) {
        _showDiaLog(
          '♾️ 무한모드',
          '완료한 주제가 없습니다.\n먼저 학습을 완료해주세요!',
        );
        return;
      }

      print("♾️ 무한모드 시작 - 완료한 주제: $completedStudyNos");

      // TestPage로 이동 (testNo는 0, testMode는 "INFINITE")
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TestPage(
            testNo: 0, // 무한모드는 testNo 사용 안 함
            testMode: "INFINITE",
          ),
        ),
      );
    } catch (e) {
      print("무한모드 시작 실패: $e");
      _showDiaLog('오류', '무한모드를 시작할 수 없습니다.');
    }
  }

  // 🔥 하드모드 시작
  void _startHardMode() async {
    print("🔥 하드모드 시작");

    // 확인 다이얼로그
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🔥 하드모드'),
        content: const Text(
          '재밌는한국어가 보유한 모든 문항이 출제됩니다.\n'
              '배우지 않은 내용도 포함될 수 있어요.\n'
              '도전하시겠어요?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('도전!'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // TestPage로 이동 (testNo는 0, testMode는 "HARD")
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestPage(
          testNo: 0, // 하드모드는 testNo 없음
          testMode: "HARD",
        ),
      ),
    );
  }

  void _showDiaLog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    // StudyPage 와 동일한 민트 테마 판별
    final bool isMintTheme = !isDark &&
        (themeColorNotifier.value == 'mint' ||
            bg.value == const Color(0xFFE7FFF6).value);

    // StudyPage 의 titleColor 규칙과 동일
    final Color titleColor = isDark
        ? scheme.onSurface
        : (isMintTheme ? const Color(0xFF2F7A69) : const Color(0xFF6B4E42));

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Text(
          '시험',
          style: theme.textTheme.titleLarge?.copyWith(
            color: titleColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: titleColor),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError(theme)
          : SafeArea(
        child: FooterSafeArea(
          child: SingleChildScrollView(
            padding:
            const EdgeInsets.fromLTRB(20, 10, 20, 24),
            child: _buildContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildError(ThemeData theme) {
    final scheme = theme.colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _error!,
            style:
            theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _bootstrap,
            style: ElevatedButton.styleFrom(
              backgroundColor: scheme.primaryContainer,
              foregroundColor: scheme.onPrimaryContainer,
              elevation: 0,
            ),
            child: const Text('다시 시도'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    // StudyPage 와 동일한 민트 판별
    final bool isMintTheme = !isDark &&
        (themeColorNotifier.value == 'mint' ||
            bg.value == const Color(0xFFE7FFF6).value);

    // StudyPage 의 section/subtitle 컬러 규칙과 유사하게 맞춤
    final Color sectionTitleColor = isDark
        ? scheme.onSurface
        : (isMintTheme ? const Color(0xFF2F7A69) : const Color(0xFF7C5A48));
    final Color sectionSubColor = isDark
        ? scheme.onSurface.withOpacity(0.7)
        : (isMintTheme ? const Color(0xFF4E8476) : const Color(0xFF9C7C68));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SKPageHeader(
          title: '시험 모드 선택',
          subtitle: '원하는 모드를 골라 실력을 테스트해보세요.',
        ),
        const SizedBox(height: 18),

        // ♾️ 무한모드
        _ModeTile(
          index: 1,
          emoji: '♾️',
          title: '무한모드',
          description: '완료한 주제에서 틀릴 때까지 도전!',
          onTap: _startInfiniteMode,
        ),
        const SizedBox(height: 8),

        // 🔥 하드모드
        _ModeTile(
          index: 2,
          emoji: '🔥',
          title: '하드모드',
          description: '전체 문항에서 틀릴 때까지 도전!',
          onTap: _startHardMode,
        ),
        const SizedBox(height: 26),

        Text(
          '📚 정기시험',
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: sectionTitleColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '주제별로 준비된 시험에 응시해보세요.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: sectionSubColor,
          ),
        ),
        const SizedBox(height: 12),

        if (_regularTests.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Text(
                '완료한 주제의 정기시험이 없습니다.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: sectionSubColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ..._regularTests.map(
                (test) => _RegularTestTile(
              test: test,
              onTap: () => _onTapRegularTest(test),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 무한/하드 모드 선택 카드 – StudyPage 목록과 같은 팔레트/레이아웃
// ─────────────────────────────────────────────────────────────

class _ModeTile extends StatelessWidget {
  final int index;
  final String emoji;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ModeTile({
    required this.index,
    required this.emoji,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    // ✅ 민트 테마 판별: themeColorNotifier 값 + 배경색 둘 다 사용
    final bool isMintTheme = (!isDark &&
        (themeColorNotifier.value == 'mint' ||
            bg.value == const Color(0xFFE7FFF6).value));

    // 👉 StudyPage._StudyTile 과 동일한 톤
    Color cardBg = const Color(0xFFFFF5ED);
    Color badgeBg = const Color(0xFFFBE3D6);
    Color badgeText = const Color(0xFF9C7C68);
    Color titleColor = const Color(0xFF6B4E42);
    Color descColor = const Color(0xFF9C7C68);
    Color arrowColor = const Color(0xFFCCB3A5);

    if (isMintTheme && !isDark) {
      // 🌿 민트 테마
      cardBg = const Color(0xFFF4FFFA);
      badgeBg = const Color(0xFFE7FFF6);
      badgeText = const Color(0xFF2F7A69);
      titleColor = const Color(0xFF2F7A69);
      descColor = const Color(0xFF4E8476);
      arrowColor = const Color(0x802F7A69);
    }

    if (isDark) {
      // 🌙 다크 테마
      cardBg = scheme.surfaceContainer;
      badgeBg = scheme.surfaceContainerHigh;
      badgeText = scheme.onSurface.withOpacity(0.8);
      titleColor = scheme.onSurface;
      descColor = scheme.onSurface.withOpacity(0.7);
      arrowColor = scheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 72, // StudyPage _StudyTile 과 동일
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // 왼쪽 번호 동그라미
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$index',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: badgeText,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // 텍스트 영역
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: descColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: arrowColor,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// 정기시험 카드 – StudyPage 리스트와 같은 카드 스타일
// ─────────────────────────────────────────────────────────────

class _RegularTestTile extends StatelessWidget {
  final dynamic test;
  final VoidCallback onTap;

  const _RegularTestTile({
    required this.test,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    final testNo = test['testNo'] ?? 0;
    final title =
    (test['testTitleSelected'] ?? test['testTitle'] ?? '시험 #$testNo')
        .toString();

    // ✅ 민트 테마 판별: themeColorNotifier 값 + 배경색 둘 다 사용
    final bool isMintTheme = (!isDark &&
        (themeColorNotifier.value == 'mint' ||
            bg.value == const Color(0xFFE7FFF6).value));

    // 👉 StudyPage._StudyTile 팔레트 그대로
    Color cardBg = const Color(0xFFFFF5ED);
    Color badgeBg = const Color(0xFFFBE3D6);
    Color badgeText = const Color(0xFF9C7C68);
    Color titleColor = const Color(0xFF6B4E42);
    Color subColor = const Color(0xFF9C7C68);
    Color arrowColor = const Color(0xFFCCB3A5);

    if (isMintTheme && !isDark) {
      cardBg = const Color(0xFFF4FFFA);
      badgeBg = const Color(0xFFE7FFF6);
      badgeText = const Color(0xFF2F7A69);
      titleColor = const Color(0xFF2F7A69);
      subColor = const Color(0xFF4E8476);
      arrowColor = const Color(0x802F7A69);
    }

    if (isDark) {
      cardBg = scheme.surfaceContainer;
      badgeBg = scheme.surfaceContainerHigh;
      badgeText = scheme.onSurface.withOpacity(0.8);
      titleColor = scheme.onSurface;
      subColor = scheme.onSurface.withOpacity(0.7);
      arrowColor = scheme.outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            height: 72, // StudyPage _StudyTile 과 동일
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 16),
                // 왼쪽 동그라미(아이콘)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: badgeBg,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.quiz_outlined,
                    size: 22,
                    color: badgeText,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '정기시험',
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: arrowColor,
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

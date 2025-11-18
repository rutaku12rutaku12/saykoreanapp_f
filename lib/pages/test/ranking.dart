import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 환경별 baseUrl 감지 (dart-define로 API_HOST 넘기면 그것을 우선 사용)
String _detectBaseUrl() {
  final env = const String.fromEnvironment('API_HOST'); // 예) --dart-define=API_HOST=http://192.168.0.10:8080
  if (env.isNotEmpty) return env;

  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080'; // 안드 에뮬레이터→호스트
  return 'http://localhost:8080';                        // iOS 시뮬레이터/데스크톱
}

final Dio dio = Dio(BaseOptions(
  baseUrl: _detectBaseUrl(),
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 10),
));

// ─────────────────────────────────────────────────────────────────────────────
// 마이페이지 스타일 랭킹 화면
class Ranking extends StatefulWidget {
  const Ranking({super.key});

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  static const Color _brown = Color(0xFF6B4E42);

  // [RK-03] 랭킹 분야별 조회 type
  // - accuracy    : 정답왕
  // - challenge   : 도전왕
  // - persistence : 끈기왕
  // - game        : 게임왕
  // - attendance  : 출석왕
  // - point       : 포인트왕
  String _rankType = "accuracy";              // 현재 선택된 랭킹 타입
  List<dynamic> _rankings = [];               // 랭킹 리스트
  bool _loading = false;                      // 로딩 여부
  String? _error;                             // 에러 메시지

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  String _getRankTitle() {
    switch (_rankType) {
      case "accuracy":
        return "🏆 정확도 왕";
      case "challenge":
        return "🔥 도전 왕";
      case "persistence":
        return "💪 끈기 왕";
      case "game":
        return "🎮 게임 왕";
      case "attendance":
        return "📅 출석 왕";
      case "point":
        return "💰 포인트 왕";
      default:
        return "랭킹";
    }
  }

  Future<void> _fetchRankings() async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final res = await dio.get(
        '/saykorean/rank',
        queryParameters: {'type': _rankType},
      );

      final data = res.data;
      setState(() {
        if (data is List) {
          _rankings = data;
        } else {
          _rankings = [];
        }
      });
    } on DioException catch (e) {
      debugPrint("📡 랭킹 요청 에러");
      debugPrint("▶ URI: ${e.response?.requestOptions.uri}");
      debugPrint("▶ Status: ${e.response?.statusCode}");
      debugPrint("▶ Body: ${e.response?.data}");

      setState(() {
        _error = "랭킹을 불러오는 중 오류가 발생했습니다.\n(${e.response?.statusCode})";
      });
    } catch (e) {
      debugPrint("알 수 없는 에러: $e");
      setState(() {
        _error = "랭킹을 불러오는 중 알 수 없는 오류가 발생했습니다.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  // 탭 버튼 (정확도 / 도전 / 끈기 / 게임 / 출석 / 포인트)
  Widget _buildTabButton(String type, String label, String emoji) {
    final bool isActive = _rankType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () {
            if (_rankType == type) return;
            setState(() {
              _rankType = type;
            });
            _fetchRankings();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFFFFE5CF) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive ? _brown : const Color(0xFFE0C9B5),
              ),
            ),
            child: Center(
              child: Text(
                "$emoji $label",
                style: TextStyle(
                  color: isActive ? _brown : const Color(0xFF9C7C68),
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 랭킹 리스트 (마이페이지 카드 스타일)
  Widget _buildRankingList() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Text(
            "랭킹 데이터가 아직 없어요.",
            style: TextStyle(fontSize: 13, color: Color(0xFF9C7C68)),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _rankings.length,
      itemBuilder: (context, index) {
        final rank = _rankings[index] as Map<String, dynamic>;
        return _RankCard(
          index: index,
          rankData: rank,
          rankType: _rankType,
        );
      },
    );
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2DE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5C8AA)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📊 랭킹 기준 안내",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: Color(0xFF7C5A48),
            ),
          ),
          SizedBox(height: 6),
          Text(
            "• 정확도 랭킹(정답 왕): 정답 / 전체 문항 비율이 높은 순",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
          Text(
            "• 도전 랭킹(도전 왕): 많이 풀어본(시도한) 문항 수 기준",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
          Text(
            "• 끈기 랭킹(끈기 왕): 재도전 평균, 유니크 문항 수 등을 종합 평가",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
          Text(
            "• 게임 랭킹(게임 왕): 게임 플레이 수, 점수 등을 기준으로 집계",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
          Text(
            "• 출석 랭킹(출석 왕): 출석(접속) 일수가 많은 순",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
          Text(
            "• 포인트 랭킹(포인트 왕): 누적 포인트가 높은 순",
            style: TextStyle(fontSize: 12, color: Color(0xFF9C7C68)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 여기서부터 테마 기반 배경 사용
    final bg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "랭킹",
          style: TextStyle(
            color: _brown,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: _brown),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "내 랭킹",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _brown,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "정확도 / 도전 / 끈기 / 게임 / 출석 / 포인트 랭킹으로 내 실력을 확인해요.",
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF9C7C68),
                ),
              ),
              const SizedBox(height: 16),

              // 탭 그룹 (2줄로 나눠서 6개)
              Row(
                children: [
                  _buildTabButton("accuracy", "정확도", "🏆"),
                  _buildTabButton("challenge", "도전", "🔥"),
                  _buildTabButton("persistence", "끈기", "💪"),
                ],
              ),
              Row(
                children: [
                  _buildTabButton("game", "게임", "🎮"),
                  _buildTabButton("attendance", "출석", "📅"),
                  _buildTabButton("point", "포인트", "💰"),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                _getRankTitle(),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7C5A48),
                ),
              ),
              const SizedBox(height: 8),

              // 랭킹 카드 리스트
              _buildRankingList(),

              // 기준 안내
              const SizedBox(height: 8),
              _buildInfoBox(),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 개별 랭킹 카드 (마이페이지 카드 스타일)
// ─────────────────────────────────────────────────────────────────────────────
class _RankCard extends StatelessWidget {
  final int index;
  final Map<String, dynamic> rankData;
  final String rankType;

  static const Color brown = Color(0xFF6B4E42);

  const _RankCard({
    required this.index,
    required this.rankData,
    required this.rankType,
  });

  String _medalEmoji() {
    if (index == 0) return "🥇";
    if (index == 1) return "🥈";
    if (index == 2) return "🥉";
    return "${index + 1}위";
  }

  String _subtitleText() {
    if (rankType == "accuracy") {
      final acc = rankData["accuracy"];
      final score = rankData["score"];
      final total = rankData["total"];
      return "정확도: ${acc ?? "-"}% · 정답 ${score ?? "-"} / ${total ?? "-"}";
    } else if (rankType == "challenge") {
      final total = rankData["total"];
      final score = rankData["score"];
      return "총 도전 문항: ${total ?? "-"} · 정답 ${score ?? "-"}";
    } else if (rankType == "persistence") {
      final avgRoundStr = "${rankData["avgRound"] ?? "0"}";
      final avgRound =
          double.tryParse(avgRoundStr.replaceAll(",", ".")) ?? 0.0;
      final uniqueItems = rankData["uniqueItems"];
      final totalAttempts = rankData["totalAttempts"];
      return "평균 재도전 ${avgRound.toStringAsFixed(1)}회 · 유니크 ${uniqueItems ?? "-"} · 시도 ${totalAttempts ?? "-"}";
    } else if (rankType == "game") {
      final total = rankData["total"]; // 총 게임 수
      final score = rankData["score"]; // 최고점 또는 누적점수
      return "게임 플레이 ${total ?? "-"}회 · 점수 ${score ?? "-"}";
    } else if (rankType == "attendance") {
      final total = rankData["total"]; // 출석 일수
      return "총 출석일수 ${total ?? "-"}일";
    } else if (rankType == "point") {
      final point = rankData["score"] ?? rankData["total"];
      return "보유 포인트 ${point ?? "-"}점";
    } else {
      return "";
    }
  }

  String _rightHighlightText() {
    if (rankType == "accuracy") {
      final acc = rankData["accuracy"];
      return acc != null ? "$acc%" : "-";
    } else if (rankType == "challenge") {
      final total = rankData["total"];
      return total != null ? "${total}문항" : "-";
    } else if (rankType == "persistence") {
      final avgRoundStr = "${rankData["avgRound"] ?? "0"}";
      final avgRound =
          double.tryParse(avgRoundStr.replaceAll(",", ".")) ?? 0.0;
      return "${avgRound.toStringAsFixed(1)}회";
    } else if (rankType == "game") {
      final score = rankData["score"];
      return score != null ? "${score}점" : "-";
    } else if (rankType == "attendance") {
      final total = rankData["total"];
      return total != null ? "${total}일" : "-";
    } else if (rankType == "point") {
      final point = rankData["score"] ?? rankData["total"];
      return point != null ? "${point}점" : "-";
    } else {
      return "-";
    }
  }

  @override
  Widget build(BuildContext context) {
    final nick = rankData["nickName"] ?? "-";
    final isTop3 = index < 3;
    final cardColor = Theme.of(context).cardColor; // 🔥 다크테마 카드색

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: isTop3 ? const Color(0xFFF5C37C) : Colors.transparent,
          width: isTop3 ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          // 메달 / 순위
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isTop3 ? const Color(0xFFFFF0D5) : const Color(0xFFFFE5CF),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              _medalEmoji(),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),

          // 닉네임 + 서브텍스트
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$nick",
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: brown,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _subtitleText(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9C7C68),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 오른쪽 강조 지표
          Text(
            _rightHighlightText(),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: brown,
            ),
          ),
        ],
      ),
    );
  }
}

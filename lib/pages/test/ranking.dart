import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
// 앱 시작
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SayKorean Ranking',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const Ranking(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// React Ranking.jsx → Flutter로 포팅
class Ranking extends StatefulWidget {
  const Ranking({super.key});

  @override
  State<Ranking> createState() => _RankingState();
}

class _RankingState extends State<Ranking> {
  String _rankType = "accuracy";              // rankType
  List<dynamic> _rankings = [];               // rankings
  bool _loading = false;                      // loading
  String? _error;                             // error message

  // 필요하면 검색도 추가 가능 (React: userNo, testItemNo, results)
  final TextEditingController _userNoCtrl = TextEditingController();
  final TextEditingController _testItemNoCtrl = TextEditingController();
  List<dynamic> _results = [];                // 검색 결과
  bool _searching = false;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _fetchRankings();
  }

  String _getRankTitle() {
    switch (_rankType) {
      case "accuracy":
      // `🏆 ${t("ranking.accyracyKing")}`
        return "🏆 정확도 왕";
      case "challenge":
        return "🔥 도전 왕";
      case "persistence":
        return "💪 끈기 왕";
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
    } catch (e) {
      debugPrint("랭킹 요청 에러: $e");
      setState(() {
        _error = "랭킹을 불러오는 중 오류가 발생했습니다.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _handleSearch() async {
    final userNo = _userNoCtrl.text.trim();
    final testItemNo = _testItemNoCtrl.text.trim();

    if (userNo.isEmpty && testItemNo.isEmpty) {
      setState(() {
        _searchError = "검색 조건을 입력해주세요.";
        _results = [];
      });
      return;
    }

    try {
      setState(() {
        _searchError = null;
        _searching = true;
      });

      String url;
      if (userNo.isNotEmpty && testItemNo.isNotEmpty) {
        url =
        '/saykorean/rank/search?userNo=$userNo&testItemNo=$testItemNo'; // React와 동일
      } else if (userNo.isNotEmpty) {
        url = '/saykorean/rank/search/user/$userNo';
      } else {
        url = '/saykorean/rank/search/item/$testItemNo';
      }

      final res = await dio.get(url);
      final data = res.data;
      setState(() {
        if (data is List) {
          _results = data;
        } else {
          _results = [];
        }
      });
    } catch (e) {
      debugPrint("검색 에러: $e");
      setState(() {
        _searchError = "조회 중 오류가 발생했습니다.";
      });
    } finally {
      setState(() {
        _searching = false;
      });
    }
  }

  Widget _buildTabButton(String type, String label, String emoji) {
    final bool isActive = _rankType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor:
            isActive ? Colors.teal.withOpacity(0.15) : Colors.grey[100],
          ),
          onPressed: () {
            if (_rankType == type) return;
            setState(() {
              _rankType = type;
            });
            _fetchRankings();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              "$emoji $label",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// 랭킹 테이블 (React의 <table> 부분 대응)
  Widget _buildRankingTable() {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(_error!)),
            ],
          ),
        ),
      );
    }

    if (_rankings.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("랭킹 데이터가 없습니다.")),
      );
    }

    // DataTable은 가로 스크롤 지원을 위해 두 번 감싸줌
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: _buildColumns(),
        rows: _buildRows(),
        headingRowColor: MaterialStateProperty.resolveWith(
              (states) => Colors.grey[100],
        ),
        dataRowMinHeight: 44,
        dataRowMaxHeight: 56,
        columnSpacing: 24,
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final List<DataColumn> cols = [
      const DataColumn(label: Text("순위")),
      const DataColumn(label: Text("닉네임")),
    ];

    if (_rankType == "accuracy") {
      cols.addAll(const [
        DataColumn(label: Text("정확도")),
        DataColumn(label: Text("정답 수")),
        DataColumn(label: Text("총 문항")),
      ]);
    } else if (_rankType == "challenge") {
      cols.addAll(const [
        DataColumn(label: Text("총 해결 문항")),
        DataColumn(label: Text("정답 수")),
      ]);
    } else if (_rankType == "persistence") {
      cols.addAll(const [
        DataColumn(label: Text("평균 재도전")),
        DataColumn(label: Text("유니크 문항 수")),
        DataColumn(label: Text("총 시도 수")),
      ]);
    }

    return cols;
  }

  List<DataRow> _buildRows() {
    return _rankings.asMap().entries.map((entry) {
      final index = entry.key;
      final rank = entry.value as Map<String, dynamic>;

      String place;
      if (index == 0) {
        place = "🥇";
      } else if (index == 1) {
        place = "🥈";
      } else if (index == 2) {
        place = "🥉";
      } else {
        place = "${index + 1}위";
      }

      final List<DataCell> cells = [
        DataCell(Text(place)),
        DataCell(Text("${rank["nickName"] ?? "-"}")),
      ];

      if (_rankType == "accuracy") {
        final accuracy = rank["accuracy"];
        final score = rank["score"];
        final total = rank["total"];

        cells.addAll([
          DataCell(
            Text(
              "${accuracy ?? "-"}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text("${score ?? "-"}")),
          DataCell(Text("${total ?? "-"}")),
        ]);
      } else if (_rankType == "challenge") {
        final total = rank["total"];
        final score = rank["score"];

        cells.addAll([
          DataCell(
            Text(
              "${total ?? "-"}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text("${score ?? "-"}")),
        ]);
      } else if (_rankType == "persistence") {
        final avgRoundStr = "${rank["avgRound"] ?? "0"}";
        final avgRound =
            double.tryParse(avgRoundStr.replaceAll(",", ".")) ?? 0.0;
        final uniqueItems = rank["uniqueItems"];
        final totalAttempts = rank["totalAttempts"];

        cells.addAll([
          DataCell(
            Text(
              "${avgRound.toStringAsFixed(1)}회",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataCell(Text("${uniqueItems ?? "-"}")),
          DataCell(Text("${totalAttempts ?? "-"}")),
        ]);
      }

      return DataRow(
        // 상위 3명 강조 (React: className="top3")
        color: MaterialStateProperty.resolveWith<Color?>((states) {
          if (index < 3) {
            return Colors.teal.withOpacity(0.06);
          }
          return null;
        }),
        cells: cells,
      );
    }).toList();
  }

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "📊 랭킹 기준 안내",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("• 정확도 랭킹: 정답 / 전체 문항 비율이 높은 순"),
          Text("• 도전 랭킹: 많이 풀어본(시도한) 문항 수 기준"),
          Text("• 끈기 랭킹: 재도전 평균, 유니크 문항 수 등을 종합 평가"),
        ],
      ),
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        const Text(
          "🔍 사용자 / 문항별 기록 검색",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _userNoCtrl,
                decoration: const InputDecoration(
                  labelText: "사용자번호 (userNo)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _testItemNoCtrl,
                decoration: const InputDecoration(
                  labelText: "문항번호 (testItemNo)",
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _searching ? null : _handleSearch,
              child: _searching
                  ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Text("검색"),
            ),
          ],
        ),
        if (_searchError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(child: Text(_searchError!)),
              ],
            ),
          ),
        ],
        if (_results.isNotEmpty) ...[
          const SizedBox(height: 12),
          const Text(
            "검색 결과",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 120,
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final item = _results[index] as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    title: Text("userNo: ${item["userNo"] ?? "-"} / "
                        "itemNo: ${item["testItemNo"] ?? "-"}"),
                    subtitle: Text(jsonEncode(item)),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("랭킹"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  const Text(
                    "랭킹 페이지",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // 탭 버튼 그룹 (accuracy / challenge / persistence)
                  Row(
                    children: [
                      _buildTabButton("accuracy", "정확도 랭킹", "🏆"),
                      _buildTabButton("challenge", "도전 랭킹", "🔥"),
                      _buildTabButton("persistence", "끈기 랭킹", "💪"),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Text(
                    _getRankTitle(),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: 8),

                  // 랭킹 테이블
                  _buildRankingTable(),

                  // 설명 박스
                  _buildInfoBox(),

                  // 검색 영역 (React handleSearch 대응)
                  _buildSearchSection(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

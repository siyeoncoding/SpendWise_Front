import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/category_summary.dart';
import '../services/api_service.dart';

class AnalysisScreen extends StatefulWidget {
  final String month; // YYYY-MM 형식

  const AnalysisScreen({required this.month, super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  List<CategorySummary> _summary = [];
  int? _goal;
  Map<String, dynamic>? _totalResult;
  Map<String, dynamic>? _categoryResult;

  bool _loading = true;

  // 한글 → 영문 키 매핑
  final Map<String, String> categoryMap = {
    "식비": "food",
    "교통": "transport",
    "문화": "culture",
    "의료": "health",
    "주거": "housing",
    "쇼핑": "shopping",
    "교육": "education",
    "기타": "etc",
  };

  @override
  void initState() {
    super.initState();
    fetchAnalysis();
  }

  Future<void> fetchAnalysis() async {
    try {
      final summary = await ApiService.fetchMonthlyCategorySummary(widget.month);
      final goal = await ApiService.fetchGoal(widget.month);

      final totalSpent = summary.fold<double>(0.0, (sum, e) => sum + e.total.toDouble());

      if (totalSpent == 0) {
        setState(() {
          _summary = summary;
          _goal = goal;
          _loading = false;
        });
        return;
      }

      // ✅ 모든 필드 0으로 초기화한 후 실제 값으로 덮어쓰기
      final ratioData = {
        for (var entry in categoryMap.entries)
          entry.value: 0.0,
        ...{
          for (var e in summary)
            if (categoryMap.containsKey(e.category))
              categoryMap[e.category]!: e.total / totalSpent
        }
      };

      final totalResult = await ApiService.predictTotalSpending(ratioData);
      final categoryResult = await ApiService.predictNextCategory(ratioData);

      setState(() {
        _summary = summary;
        _goal = goal;
        _totalResult = totalResult;
        _categoryResult = categoryResult;
        _loading = false;
      });
    } catch (e) {
      print("❌ 분석 데이터 로딩 실패: $e");
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('소비 분석')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📊 카테고리별 소비 비율", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (_summary.isEmpty)
              const Center(child: Text("해당 월의 소비 데이터가 없습니다."))
            else
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    centerSpaceRadius: 40,
                    sectionsSpace: 2,
                    sections: _summary.map((e) {
                      final total = _summary.fold<double>(0.0, (s, i) => s + i.total);
                      final ratio = e.total / total;
                      return PieChartSectionData(
                        value: e.total.toDouble(),
                        title: "${e.category}\n${(ratio * 100).toStringAsFixed(1)}%",
                        radius: 60,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
              ),

            const SizedBox(height: 24),

            if (_goal != null) ...[
              Text("🎯 목표 금액: ${NumberFormat('#,###').format(_goal)} 원", style: const TextStyle(fontSize: 16)),
              Text("📌 실제 지출: ${NumberFormat('#,###').format(_summary.fold(0, (s, i) => s + i.total))} 원"),
              const SizedBox(height: 16),
            ],

            if (_categoryResult != null) ...[
              const Text("🔮 다음달 소비 예측", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("▶ 예측 분야: ${_categoryResult!['predicted_category']}"),
              Text("▶ 피드백: ${_categoryResult!['feedback']}"),
              const SizedBox(height: 16),
            ],

            if (_totalResult != null) ...[
              const Text("💰 총 소비 예측", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("▶ 예상 소비액: ${_totalResult!['predicted_total']} 만원"),
              Text("▶ 인사이트: ${_totalResult!['feedback']}"),
            ]
          ],
        ),
      ),
    );
  }
}

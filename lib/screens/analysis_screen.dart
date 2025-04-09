import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';
import '../models/category_summary.dart';
import 'package:intl/intl.dart';
import 'analysis_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final String month;

  AnalysisScreen({required this.month});

  @override
  _AnalysisScreenState createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  Map<String, double> dataMap = {};

  @override
  void initState() {
    super.initState();
    _loadCategoryData(widget.month);
  }

  Future<void> _loadCategoryData(String monthStr) async {
    final list = await ApiService.fetchMonthlyCategorySummary(monthStr);

    setState(() {
      dataMap = {
        for (var item in list) item.category: item.total.toDouble()
      };
    });
  }

  String _formatCurrency(double amount) {
    return NumberFormat('#,###').format(amount.toInt()) + '원'; // 천 단위 구분 기호 추가
  }

  @override
  Widget build(BuildContext context) {
    final total = dataMap.values.fold(0.0, (sum, val) => sum + val);

    return Scaffold(
      appBar: AppBar(title: Text("소비 분석")),
      body: dataMap.isEmpty
          ? Center(child: Text("분석할 소비 데이터가 없습니다."))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ 차트
            Expanded(
              flex: 2,
              child: AspectRatio(
                aspectRatio: 1,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: _getChartSections(total),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            // ✅ 범례 리스트
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "총 소비 금액: ${_formatCurrency(total)}", // 포맷팅된 금액 사용
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  ..._getSortedEntries().map((entry) {
                    final percentage = (entry.value / total) * 100;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getColorForCategory(entry.key),
                            ),
                          ),
                          Expanded(child: Text(entry.key)),
                          Text(
                            '${_formatCurrency(entry.value)} (${percentage.toStringAsFixed(1)}%)', // 포맷팅된 금액 사용
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> categoryColors = Colors.primaries;

  // ✅ 퍼센트 텍스트로 표시
  List<PieChartSectionData> _getChartSections(double total) {
    final List<String> keys = dataMap.keys.toList();

    return List.generate(keys.length, (i) {
      final category = keys[i];
      final value = dataMap[category]!;
      final percent = (value / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: _getColorForCategory(category),
        value: value,
        radius: 60,
        title: '$percent%',
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      );
    });
  }

  Color _getColorForCategory(String category) {
    return categoryColors[dataMap.keys.toList().indexOf(category) % categoryColors.length];
  }

  List<MapEntry<String, double>> _getSortedEntries() {
    var sortedEntries = dataMap.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries;
  }
}

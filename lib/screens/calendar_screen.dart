import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../models/spending.dart';
import 'add_spending_screen.dart';
import 'analysis_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _totalSpendingMap = {};
  List<Spending> _spendingList = [];

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchSpendingsBySelectedDay();
  }

  Future<void> _fetchSummary() async {
    final summaryMap = await ApiService.fetchTotalSpendingsByDate();
    setState(() {
      _totalSpendingMap = summaryMap;
    });
  }

  Future<void> _fetchSpendingsBySelectedDay() async {
    if (_selectedDay == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final list = await ApiService.fetchSpendingsByDate(formatted);
    setState(() {
      _spendingList = list;
    });
  }

  Color _getSpendingColor(int total) {
    if (total < 10000) return Colors.green;
    if (total < 30000) return Colors.yellow;
    return Colors.redAccent;
  }

  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount) + '원'; // 천 단위 구분 기호 추가
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('소비 내역 캘린더'),
        actions: [
          IconButton(
            icon: Icon(Icons.pie_chart),
            tooltip: '소비 분석',
            onPressed: () {
              final selectedMonth = DateFormat('yyyy-MM').format(_focusedDay);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AnalysisScreen(month: selectedMonth)),
              );
            },
          )
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            locale: 'ko_KR',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2100, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
              _fetchSpendingsBySelectedDay();
            },
            onPageChanged: (focusedDay) {
              setState(() {
                _focusedDay = focusedDay;
              });
            },
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final normalizedDay = DateTime(day.year, day.month, day.day);
                final total = _totalSpendingMap[normalizedDay];

                if (total == null) return null;

                final color = _getSpendingColor(total);
                return Positioned(
                  top: 4,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedDay != null && _spendingList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                "오늘의 총 소비: ${_formatCurrency(_spendingList.fold(0, (sum, e) => sum + e.amount))}",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _spendingList.isEmpty
                ? Center(child: Text('선택한 날짜에 소비 내역이 없습니다.'))
                : ListView.builder(
              itemCount: _spendingList.length,
              itemBuilder: (context, index) {
                final item = _spendingList[index];
                return ListTile(
                  title: Text('${item.category} - ${_formatCurrency(item.amount)}'), // 포맷팅된 금액 사용
                  subtitle: Text(item.memo ?? ''),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: _selectedDay == null
          ? null
          : FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddSpendingScreen(prefilledDate: _selectedDay!),
            ),
          ).then((_) {
            _fetchSummary();
            _fetchSpendingsBySelectedDay();
          });
        },
        label: Text('소비 등록', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF9EC6F3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

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
    _checkGoalExceeded();
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

  Future<void> _checkGoalExceeded() async {
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);
    final goal = await ApiService.fetchGoal(monthStr);

    if (goal != null) {
      final totalSpent = _totalSpendingMap.values.fold(0, (sum, e) => sum + e);
      if (totalSpent > goal) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('⚠️ 목표 초과'),
            content: Text('이번 달 소비가 설정한 목표를 초과했습니다!'),
            actions: [
              TextButton(
                child: Text('확인'),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
        );
      }
    }
  }

  void _showGoalSettingDialog() async {
    final TextEditingController _controller = TextEditingController();
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);

    final currentGoal = await ApiService.fetchGoal(monthStr);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('소비 목표 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentGoal != null)
              Text('현재 목표: ${NumberFormat('#,###').format(currentGoal)}원',
                  style: TextStyle(fontWeight: FontWeight.bold))
            else
              Text('소비 목표가 설정되지 않았습니다.'),
            SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '새로운 목표 금액을 입력하세요',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('저장'),
            onPressed: () async {
              final input = _controller.text.trim();
              if (input.isNotEmpty) {
                final success = await ApiService.setGoal(int.parse(input), monthStr);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('소비 목표가 저장되었습니다.')),
                  );
                  Navigator.pop(context);
                  _fetchSummary();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('목표 저장 실패')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Color _getSpendingColor(int total) {
    if (total < 10000) return Colors.green;
    if (total < 30000) return Colors.yellow;
    return Colors.redAccent;
  }

  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount) + '원';
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
          ),
          IconButton(
            icon: Icon(Icons.flag), // ✅ 소비 목표 설정 버튼 추가
            tooltip: '소비 목표 설정',
            onPressed: _showGoalSettingDialog,
          ),
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
                  title: Text('${item.category} - ${_formatCurrency(item.amount)}'),
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
              builder: (context) => AddSpendingScreen(prefilledDate: _selectedDay!),
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

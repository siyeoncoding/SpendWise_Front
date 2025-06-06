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
    _selectedDay = _focusedDay;
    _fetchSummary().then((_) => _checkGoalExceeded());
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

  Future<void> _checkGoalExceeded() async {
    final now = DateTime.now();
    final monthStr = DateFormat('yyyy-MM').format(now);
    final goal = await ApiService.fetchGoal(monthStr);

    if (goal != null) {
      final currentMonthTotal = _totalSpendingMap.entries
          .where((entry) => DateFormat('yyyy-MM').format(entry.key) == monthStr)
          .fold(0, (sum, entry) => sum + entry.value);

      if (currentMonthTotal > goal) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('⚠️ 목표 초과'),
            content: Text('이번 달 소비가 설정한 목표를 초과했습니다!'),
            actions: [
              TextButton(
                child: const Text('확인'),
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
        title: const Text('소비 목표 설정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentGoal != null)
              Text(
                '현재 목표: ${NumberFormat('#,###').format(currentGoal)}원',
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            else
              const Text('소비 목표가 설정되지 않았습니다.'),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '새로운 목표 금액을 입력하세요',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text('저장'),
            onPressed: () async {
              final input = _controller.text.trim();
              if (input.isNotEmpty) {
                try {
                  final response = await ApiService.setGoal(
                    int.parse(input),
                    monthStr,
                  );

                  final total = response['total_spending'];
                  final goal = response['goal'];
                  final messageText = '현재 총 소비: ${NumberFormat('#,###').format(total)}원\n목표: ${NumberFormat('#,###').format(goal)}원';

                  Navigator.pop(context); // 설정창 닫기

                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("소비 목표 등록 결과"),
                      content: Text(messageText),
                      actions: [
                        TextButton(
                          child: const Text("확인"),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  );

                  _fetchSummary();

                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('목표 저장 실패: ${e.toString()}')),
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
    if (total < 30000) return Colors.orange;
    return Colors.redAccent;
  }

  String _formatCurrency(int amount) {
    return NumberFormat('#,###').format(amount) + '원';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('소비 내역 캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.pie_chart),
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
            icon: const Icon(Icons.flag),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          Expanded(
            child: _spendingList.isEmpty
                ? const Center(child: Text('선택한 날짜에 소비 내역이 없습니다.'))
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
        label: const Text('소비 등록', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF9EC6F3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import '../models/spending.dart';
import 'add_spending_screen.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, int> _totalSpendingMap = {}; // 날짜별 소비 총합
  List<Spending> _spendingList = []; // 선택한 날짜 소비 리스트

  @override
  void initState() {
    super.initState();
    _fetchSummary();
    _fetchSpendingsBySelectedDay(); // 오늘 날짜 소비 불러오기
  }

  // ✅ 날짜별 소비 총합 불러오기
  Future<void> _fetchSummary() async {
    final summaryMap = await ApiService.fetchTotalSpendingsByDate();
    setState(() {
      _totalSpendingMap = summaryMap;
    });
  }

  // ✅ 선택한 날짜의 소비 내역 불러오기
  Future<void> _fetchSpendingsBySelectedDay() async {
    if (_selectedDay == null) return;

    final formatted = DateFormat('yyyy-MM-dd').format(_selectedDay!);
    final list = await ApiService.fetchSpendingsByDate(formatted);
    setState(() {
      _spendingList = list;
    });
  }

  // ✅ 총액에 따른 색상 반환
  Color _getSpendingColor(int total) {
    if (total < 10000) return Colors.green;
    if (total < 30000) return Colors.yellow;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('소비 내역 캘린더')),
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
                "총 소비: ${_spendingList.fold(0, (sum, e) => sum + e.amount)}원",
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
                  title: Text('${item.category} - ${item.amount}원'),
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

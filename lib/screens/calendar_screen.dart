import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/api_service.dart';
import 'add_spending_screen.dart';
import '../models/spending.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}
 //
class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<Spending>> _spendingMap = {};
  Map<DateTime, int> _dailyTotals = {}; // 날짜별 총합

  @override
  void initState() {
    super.initState();
    _loadSpendingData();
  }

  Future<void> _loadSpendingData() async {
    final summary = await ApiService.fetchSummaryForCalendar();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todaySpendings = await ApiService.fetchSpendingsByDate(today); // 기본값

    setState(() {
      _dailyTotals = summary;
      _selectedDay = DateTime.now();
      _focusedDay = DateTime.now();
      _spendingMap = {
        _selectedDay!: todaySpendings,
      };
    });
  }

  Future<void> _updateSpendingsForSelectedDay(DateTime day) async {
    final formatted = DateFormat('yyyy-MM-dd').format(day);
    final spendings = await ApiService.fetchSpendingsByDate(formatted);

    setState(() {
      _selectedDay = day;
      _focusedDay = day;
      _spendingMap[day] = spendings;
    });
  }

  Color _getColorForAmount(int total) {
    if (total < 10000) return Colors.yellow.shade200;
    if (total < 30000) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  Color _getMarkerColor(DateTime day) {
    final total = _dailyTotals[DateTime(day.year, day.month, day.day)];
    if (total == null || total == 0) return Colors.transparent;
    return _getColorForAmount(total);
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
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final color = _getMarkerColor(day);
                if (color == Colors.transparent) return null;
                return Positioned(
                  bottom: 4,
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
            onDaySelected: (selectedDay, focusedDay) {
              _updateSpendingsForSelectedDay(selectedDay);
            },
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _selectedDay != null &&
                _spendingMap[_selectedDay] != null &&
                _spendingMap[_selectedDay]!.isNotEmpty
                ? ListView.builder(
              itemCount: _spendingMap[_selectedDay]!.length,
              itemBuilder: (context, index) {
                final spending = _spendingMap[_selectedDay]![index];
                return ListTile(
                  leading: Icon(Icons.circle, color: Colors.blueAccent, size: 12),
                  title: Text('${spending.category} - ${spending.amount}원'),
                  subtitle: spending.memo != null
                      ? Text(spending.memo!)
                      : null,
                );
              },
            )
                : Center(child: Text('선택한 날짜에 소비 내역이 없습니다.')),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_selectedDay != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddSpendingScreen(prefilledDate: _selectedDay),
              ),
            ).then((_) => _loadSpendingData()); // 돌아오면 갱신
          }
        },
        label: Text('소비 등록', style: TextStyle(color: Colors.white)),
        icon: Icon(Icons.add, color: Colors.white),
        backgroundColor: Color(0xFF9EC6F3),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

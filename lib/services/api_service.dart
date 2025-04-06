import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/spending.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static final storage = FlutterSecureStorage();

  // 로그인
  static Future<String?> login(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'username': userId, 'password': password},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      print('❌ 로그인 실패: ${response.body}');
      return null;
    }
  }

  // 소비 등록
  static Future<bool> addSpending(String category, int amount, String memo, String date) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'category': category,
        'amount': amount,
        'memo': memo,
        'date': date,
      }),
    );

    if (response.statusCode == 200) {
      print('✅ 소비 등록 성공');
      return true;
    } else {
      print('❌ 소비 등록 실패: ${response.body}');
      return false;
    }
  }

  // 📌 날짜별 소비 내역 조회
  static Future<List<Spending>> fetchSpendingsByDate(String date) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending?date=$date');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Spending.fromJson(e)).toList();
    } else {
      print('❌ 날짜 소비 내역 조회 실패: ${response.body}');
      return [];
    }
  }

  // 📌 전체 소비 요약 (캘린더용 총합)
  static Future<Map<DateTime, int>> fetchSummaryForCalendar() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending/summary');

    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        for (var item in data)
          DateTime.parse(item['date']): item['total_amount'] as int,
      };
    } else {
      print('❌ 소비 총합 조회 실패: ${response.body}');
      return {};
    }
  }
}

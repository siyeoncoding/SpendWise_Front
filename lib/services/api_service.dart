import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/spending.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000'; // 에뮬레이터에서 localhost
  static final storage = FlutterSecureStorage();

  // 🔐 로그인 요청
  static Future<String?> login(String userId, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/login/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': userId,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'];
    } else {
      print('❌ 로그인 실패: ${response.body}');
      return null;
    }
  }

  // ✅ 소비 내역 등록
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
      print('✅ 소비 등록 성공!');
      return true;
    } else {
      print('❌ 소비 등록 실패: ${response.body}');
      return false;
    }
  }

  // 📦 특정 날짜의 소비 내역 조회
  static Future<List<Spending>> fetchSpendingsByDate(String date) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending?date=$date');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((item) => Spending.fromJson(item)).toList();
    } else {
      print('❌ 날짜별 소비 조회 실패: ${response.body}');
      return [];
    }
  }

  // 📈 날짜별 총 소비 금액 조회 (캘린더 색상용)
  static Future<Map<DateTime, int>> fetchTotalSpendingsByDate() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending-summary');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      final Map<DateTime, int> result = {};
      for (var item in data) {
        try {
          final date = DateTime.parse(item['date']);
          final normalized = DateTime(date.year, date.month, date.day);
          result[normalized] = item['total_amount'];
        } catch (e) {
          print('❌ 날짜 파싱 실패: $e');
        }
      }
      return result;
    } else {
      print('❌ 소비 총합 조회 실패: ${response.body}');
      return {};
    }
  }









}

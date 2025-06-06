import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../models/spending.dart';
import '../models/category_summary.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8000';
  static final storage = FlutterSecureStorage();

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
      final token = data['access_token'];
      await storage.write(key: 'access_token', value: token);
      return token;
    } else {
      print('❌ 로그인 실패: ${response.body}');
      return null;
    }
  }

  static Future<bool> addSpending(String category, int amount, String memo, String date) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
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

  static Future<List<Spending>> fetchSpendingsByDate(String date) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending?date=$date');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => Spending.fromJson(e)).toList();
    } else {
      print('❌ 소비 조회 실패: ${response.body}');
      return [];
    }
  }

  static Future<Map<DateTime, int>> fetchTotalSpendingsByDate() async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending-summary/daily');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      final Map<DateTime, int> result = {};

      for (var item in data) {
        final date = DateTime.parse(item['date']);
        result[DateTime(date.year, date.month, date.day)] = item['total_amount'];
      }
      return result;
    } else {
      print('❌ 날짜별 소비 조회 실패: ${response.body}');
      return {};
    }
  }

  static Future<List<CategorySummary>> fetchMonthlyCategorySummary(String month) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/spending-summary/monthly?month=$month');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((e) => CategorySummary.fromJson(e)).toList();
    } else {
      print('❌ 소비 분석 API 차트 실패: ${response.body}');
      return [];
    }
  }

  static Future<Map<String, dynamic>> setGoal(int goalAmount, String month) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/goal');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'goal_amount': goalAmount,
        'month': month,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data;
    } else {
      print('❌ 목표 설정 실패: ${response.body}');
      throw Exception('목표 설정 실패');
    }
  }

  static Future<int?> fetchGoal(String month) async {
    final token = await storage.read(key: 'access_token');
    final url = Uri.parse('$baseUrl/goal?month=$month');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['goal_amount'];
    } else if (response.statusCode == 404) {
      return null;
    } else {
      print('❌ 목표 조회 실패: ${response.body}');
      return null;
    }
  }

  static Future<Map<String, dynamic>> predictTotalSpending(Map<String, double> input) async {
    final url = Uri.parse('$baseUrl/predict-total');

    final completeInput = {
      "food": input["food"] ?? 0,
      "transport": input["transport"] ?? 0,
      "culture": input["culture"] ?? 0,
      "health": input["health"] ?? 0,
      "housing": input["housing"] ?? 0,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(completeInput),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('❌ 총 소비 예측 실패: ${response.body}');
      throw Exception('총 소비 예측 실패');
    }
  }

  static Future<Map<String, dynamic>> predictNextCategory(Map<String, double> input) async {
    final url = Uri.parse('$baseUrl/predict-next-month');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(input),
    );

    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } else {
      print('❌ 다음달 카테고리 예측 실패: ${response.body}');
      throw Exception('다음달 카테고리 예측 실패');
    }
  }
}

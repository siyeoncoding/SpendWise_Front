import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final storage = FlutterSecureStorage();
  final String baseUrl = "http://10.0.2.2:8000";

  Future<String> fetchMyInfo() async {
    final token = await storage.read(key: 'access_token');
    print("🐤 저장된 토큰: $token");
    final response = await http.get(
      Uri.parse('$baseUrl/user/me'),
      headers: {"Authorization": "Bearer $token"},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["message"];
    } else {
      return "인증 실패";
    }
  }

  void logout(BuildContext context) async {
    await storage.delete(key: 'access_token');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("내 정보"),
        actions: [
          IconButton(onPressed: () => logout(context), icon: Icon(Icons.logout))
        ],
      ),
      body: FutureBuilder<String>(
        future: fetchMyInfo(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting)
            return Center(child: CircularProgressIndicator());
          return Center(child: Text(snapshot.data ?? '에러 발생'));
        },
      ),
    );
  }
}

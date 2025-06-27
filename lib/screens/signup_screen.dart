import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();

  final String baseUrl = "http://10.0.2.2:8000";

  Future<void> signUp() async {
    final response = await http.post(
      Uri.parse('$baseUrl/user/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': _userIdController.text,
        'password': _passwordController.text,
        'full_name': _fullNameController.text,
        'email': _emailController.text,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 성공')));
      Navigator.pop(context); // 로그인 화면으로 이동
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('회원가입 실패')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("회원가입")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(children: [
          TextField(controller: _userIdController, decoration: InputDecoration(labelText: 'User ID')),
          TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          TextField(controller: _fullNameController, decoration: InputDecoration(labelText: 'Full Name')),
          TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
          SizedBox(height: 20),
          ElevatedButton(onPressed: signUp, child: Text('회원가입')),
        ]),
      ),
    );
  }
}

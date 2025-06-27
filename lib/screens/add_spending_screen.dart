import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../utils/spending_categories.dart';

class AddSpendingScreen extends StatefulWidget {

  final DateTime? prefilledDate; // 선택한 날짜 전달

  AddSpendingScreen({this.prefilledDate});


  @override
  _AddSpendingScreenState createState() => _AddSpendingScreenState();
}

class _AddSpendingScreenState extends State<AddSpendingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.prefilledDate ?? DateTime.now(); // 전달된 날짜로 초기화
  }

  Future<void> _submitSpending() async {
    if (_formKey.currentState!.validate()) {
      final category = _categoryController.text;
      final amount = int.parse(_amountController.text);
      final memo = _memoController.text;
      final date = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final success = await ApiService.addSpending(category, amount, memo, date);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('소비 내역이 등록되었습니다!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('소비 내역 등록'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // ✅ 카테고리 드롭다운으로 변경
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty ? _categoryController.text : null,
                items: spendingCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _categoryController.text = value!;
                  });
                },
                decoration: InputDecoration(labelText: '카테고리'),
                validator: (value) =>
                value == null || value.isEmpty ? '카테고리를 선택하세요' : null,
              ),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(labelText: '금액'),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? '금액을 입력하세요' : null,
              ),
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(labelText: '메모 (선택)'),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Text('선택한 날짜: ${DateFormat('yyyy-MM-dd').format(_selectedDate)}'),
                  TextButton(onPressed: _pickDate, child: Text('날짜 선택')),
                ],
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitSpending,
                child: Text('저장하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

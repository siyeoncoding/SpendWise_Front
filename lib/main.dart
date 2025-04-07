import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/login_screen.dart';
import 'screens/add_spending_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/auth_selection_screen.dart';

/*
void main() {
  runApp(MaterialApp(
    home: AddSpendingScreen(), // ✅ 소비 등록 화면만 단독 실행
  ));
}
*/

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR', null); // ✅ 로케일 초기화
  runApp(MyApp());

}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      localizationsDelegates: [ // ✅ 여기!
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('ko', 'KR')], // ✅ 한국어 지원 추가
      home: AuthSelectionScreen(), // ✅ 로그인 화면이 첫 화면
    );
  }
}



/*import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'screens/login_screen.dart';
import 'screens/calendar_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<Widget> _getStartScreen() async {
    final token = await storage.read(key: 'access_token');
    if (token != null && token.isNotEmpty) {
      return CalendarScreen();
    }
    return LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SpendWise',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: FutureBuilder(
        future: _getStartScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data as Widget;
          } else {
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
        },
      ),
    );
  }
}
*/
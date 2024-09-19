import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mokshayani/screen/auth_service.dart';
import 'package:mokshayani/screen/chat_screen.dart';
import 'package:mokshayani/screen/discover_screen.dart';
import 'package:mokshayani/screen/libaray_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Chat',
      theme: ThemeData.dark(),
      initialRoute: '/auth',
      routes: {
        '/auth': (context) => AuthScreen(),
        '/home': (context) => ChatbotUI(),
        '/discover': (context) => DiscoverScreen(),
        '/library': (context) => LibraryScreen(),
      },
    );
  }
}

import 'calendar_check_worker.dart';
import 'login_screen.dart';

import 'package:flutter/material.dart';


void main() async {
  runApp(const MyApp());
  initializeCalendarCheckWorker();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          // primarySwatch: Colors.amber,
          ),
      home: const LoginScreen(title: 'Flutter Max Demo Home Page'),
    );
  }
}
import 'package:flutter/material.dart';
import 'main/HomeScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'GlacialIndifference',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home: const HomeScreen(),
    );
  }
}

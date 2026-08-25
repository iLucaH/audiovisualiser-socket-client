import 'package:flutter/material.dart';
import 'package:flutter_test_app/ui/home/home.dart';

void main() {
  runApp(const MyProfileApp());
}

class MyProfileApp extends StatelessWidget {
  const MyProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeView());
  }
}
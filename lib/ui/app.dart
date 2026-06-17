import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/root_screen.dart';

class CarplayApp extends StatelessWidget {
  const CarplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'carplay-audio',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const RootScreen(),
    );
  }
}

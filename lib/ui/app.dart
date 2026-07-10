import 'package:flutter/material.dart';
import 'theme.dart';
import 'screens/root_screen.dart';

class CarplayApp extends StatelessWidget {
  const CarplayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BMW Connect',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const RootScreen(),
    );
  }
}

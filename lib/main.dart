import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/audio_controller.dart';
import 'ui/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final controller = AudioController();
  await controller.init();

  runApp(
    ChangeNotifierProvider.value(
      value: controller,
      child: const CarplayApp(),
    ),
  );
}

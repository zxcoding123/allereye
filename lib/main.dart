import 'package:flutter/material.dart';
import 'helpers/appSettings.dart';
import 'main/HomeScreen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSettings.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettings.instance;
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        theme: settings.theme,
        // Apply the in-app font size on top of the system text scale.
        builder: (context, child) {
          final systemScale = MediaQuery.textScalerOf(context).scale(1);
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(systemScale * settings.textScale),
            ),
            child: child!,
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}

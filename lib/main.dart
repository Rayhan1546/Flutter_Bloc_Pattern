import 'package:flutter/material.dart';
import 'package:junie_ai_test/di/register_modules.dart';
import 'package:junie_ai_test/presentation/navigation/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register all dependency injection modules
  await registerModules();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = AppNavigation.createRouter();

    return MaterialApp.router(
      title: 'GitHub Repos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

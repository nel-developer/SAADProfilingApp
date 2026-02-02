import 'package:flutter/material.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'package:da_project_1/screens/splash/splash_screen.dart';
import 'package:da_project_1/theme/da_theme.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: DATheme.themeData,
      routes: AppRoutes.getRoutes(),
      home: const SplashScreen(),
    );
  }
}
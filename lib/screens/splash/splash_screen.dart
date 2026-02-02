import 'dart:async';
import 'package:flutter/material.dart';
import 'package:da_project_1/routes/app_routes.dart';
import 'dart:math';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const double _refWidth = 393.0;
  static const double _refHeight = 852.0;

  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 5), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    });
  }

  double _scale(BuildContext context) {
    final scaleW =
        (MediaQuery.of(context).size.width / _refWidth).clamp(0.5, 2.0);
    final scaleH =
        (MediaQuery.of(context).size.height / _refHeight).clamp(0.5, 2.0);
    return min(scaleW, scaleH);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _scale(context);
    final logoWidth = _refWidth * 0.45 * scale;

    return Scaffold(
      body: Stack(
        children: [
          /// BACKGROUND IMAGE
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          /// LOGO
          Center(
            child: Image.asset(
              'assets/images/da_logo.png',
              width: logoWidth,
            ),
          ),
        ],
      ),
    );
  }
}
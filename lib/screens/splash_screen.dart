import 'package:flutter/material.dart';
import 'dart:async';
import 'welcome_screen.dart';
import '../widgets/home_icon_painter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFCCBC),
              Color(0xFFFFAB91),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Custom house with couch icon
              CustomPaint(
                size: Size(200, 180),
                painter: HomeIconPainter(color: Colors.white),
              ),
              const SizedBox(height: 40),
              // App name
              Text(
                'DECOR',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),
              Text(
                'MATE',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: 10,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
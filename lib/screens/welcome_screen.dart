import 'package:flutter/material.dart';
import '../widgets/home_icon_painter.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Color(0xFFFFF5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Custom house with couch icon
                CustomPaint(
                  size: Size(180, 160),
                  painter: HomeIconPainter(color: Color(0xFFFFAB91)),
                ),
                const SizedBox(height: 40),
                // App name
                Text(
                  'DECOR',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFFAB91),
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                ),
                Text(
                  'MATE',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFFFFAB91),
                    letterSpacing: 10,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 40),
                // Description
                Text(
                  'Transform your space with style.\nYour perfect decor companion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                // Log In button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to login
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFFAB91),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Sign Up button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Navigate to sign up
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFFFAB91),
                      side: BorderSide(color: Color(0xFFFFAB91), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
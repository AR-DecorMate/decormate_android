import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../auth/login.dart';
import '../auth/signup.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(child:Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Logo
              SvgPicture.asset(
                'assets/logo/logo.svg',
                width: 175,
                height: 147.48,
                colorFilter: ColorFilter.mode(
                  Color(0xFFF4B5A4),
                  BlendMode.srcIn,
                ),
              ),

              const SizedBox(height: 40),

              // DECOR text
              Text(
                'DECOR',
                style: TextStyle(
                  fontSize: 58.85,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF4B5A4),
                  letterSpacing: 2,
                  height: 1.0,
                ),
              ),

              // MATE text
              Text(
                'MATE',
                style: TextStyle(
                  fontSize: 33.91,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFF4B5A4),
                  letterSpacing: 0.37 * 33.91,
                  height: 1.0,
                ),
              ),

              const SizedBox(height: 40),

              // Tagline
              Text(
                'Transform your space with style.\nYour perfect decor companion.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF4B4544),
                  height: 1.5,
                ),
              ),

              const Spacer(),

              // Log In button
              SizedBox(
                width: 250,
                height: 56,
                child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFF4B5A4),
                    foregroundColor: Color(0xFFCC7861),
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

              const SizedBox(height: 8),

              // Sign Up button
              SizedBox(
                width: 250,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpScreen()),
                  );},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFAF0E6),
                    foregroundColor: Color(0xFFDCBEB6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
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
          )),
        ),
      ),
    );
  }
}
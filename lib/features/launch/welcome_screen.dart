import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                SvgPicture.asset(
                  'assets/logo/logo.svg',
                  width: 175,
                  height: 147.48,
                  colorFilter: const ColorFilter.mode(
                    AppColors.primaryPink,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'DECOR',
                  style: TextStyle(
                    fontSize: 58.85,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryPink,
                    letterSpacing: 2,
                    height: 1.0,
                  ),
                ),
                const Text(
                  'MATE',
                  style: TextStyle(
                    fontSize: 33.91,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryPink,
                    letterSpacing: 0.37 * 33.91,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  AppStrings.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.subtleText,
                    height: 1.5,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: 250,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryPink,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => context.push('/signup'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.backgroundBeige,
                      foregroundColor: AppColors.hintColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.large),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

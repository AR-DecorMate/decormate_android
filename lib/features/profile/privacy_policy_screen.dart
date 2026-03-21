import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: const Text("Privacy Policy", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Privacy Policy", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkText)),
            SizedBox(height: 16),
            Text(
              "Last updated: 2024",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            SizedBox(height: 20),
            _Section(
              title: "Information We Collect",
              body: "DecorMate collects information you provide directly, including your name, email address, profile photo, and any designs or posts you share. "
                  "We also collect usage data such as how you interact with our features, including AR visualization sessions and AI design consultations.",
            ),
            _Section(
              title: "How We Use Your Information",
              body: "We use your information to provide and improve DecorMate's services, including personalized design recommendations, AR experiences, and community features. "
                  "Your data helps us understand user preferences and enhance our AI-powered design suggestions.",
            ),
            _Section(
              title: "Data Storage & Security",
              body: "Your data is stored securely using Firebase services with industry-standard encryption. "
                  "We implement appropriate security measures to protect against unauthorized access, alteration, or destruction of your personal information.",
            ),
            _Section(
              title: "Third-Party Services",
              body: "DecorMate uses third-party services including Google Firebase for authentication and data storage, "
                  "and Google's Generative AI for design recommendations. These services have their own privacy policies.",
            ),
            _Section(
              title: "Your Rights",
              body: "You can access, update, or delete your personal information through the app's settings. "
                  "You may also request a copy of your data or ask us to delete your account entirely.",
            ),
            _Section(
              title: "Contact Us",
              body: "If you have questions about this privacy policy, please contact us through the Help & Support section in the app.",
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkText)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(fontSize: 14, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }
}

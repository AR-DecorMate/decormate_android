import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
        title: const Text("Help & Support", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            "Frequently Asked Questions",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
          ),
          const SizedBox(height: 20),
          _faqItem(
            "How do I use AR visualization?",
            "Browse our furniture catalog, select an item, and tap 'View in AR'. "
                "Point your camera at the floor or surface where you'd like to place the item. "
                "The 3D model will appear, and you can move, rotate, and scale it.",
          ),
          _faqItem(
            "How does the AI Design Assistant work?",
            "Tap the chat icon on any screen to open the AI assistant. "
                "You can ask for design recommendations, color palette suggestions, "
                "room layout ideas, and more. The AI learns from your preferences to provide personalized tips.",
          ),
          _faqItem(
            "How do I save designs?",
            "When viewing an item, tap the bookmark icon to save it to your collection. "
                "You can find all saved designs in the 'Saved' tab.",
          ),
          _faqItem(
            "How do I share my designs?",
            "Go to the Community tab and tap the '+' button to create a new post. "
                "You can upload photos of your designs and add captions to share with the community.",
          ),
          _faqItem(
            "How do I delete my account?",
            "Go to Profile → Settings → Delete Account. Please note that this action is irreversible "
                "and will permanently remove all your data.",
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.backgroundBeige,
              borderRadius: BorderRadius.circular(AppRadius.card),
            ),
            child: const Column(
              children: [
                Icon(Icons.email_outlined, color: AppColors.accent, size: 36),
                SizedBox(height: 12),
                Text("Still need help?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                  "Contact us at support@decormate.app",
                  style: TextStyle(color: AppColors.accent, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _faqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundBeige,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.darkText)),
        iconColor: AppColors.accent,
        children: [Text(answer, style: const TextStyle(color: Colors.grey, fontSize: 13, height: 1.5))],
      ),
    );
  }
}

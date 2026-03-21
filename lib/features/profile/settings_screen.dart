import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../core/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.darkText),
          onPressed: () => context.pop(),
        ),
        title: const Text("Settings", style: TextStyle(color: AppColors.primaryPink)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _settingsTile(
            icon: Icons.notifications_outlined,
            title: "Notifications",
            subtitle: "Manage notification preferences",
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.language,
            title: "Language",
            subtitle: "English",
            onTap: () {},
          ),
          _settingsTile(
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            subtitle: "Read our privacy policy",
            onTap: () => context.push('/profile/privacy'),
          ),
          _settingsTile(
            icon: Icons.help_outline,
            title: "Help & Support",
            subtitle: "Get help with the app",
            onTap: () => context.push('/profile/help'),
          ),
          const SizedBox(height: 30),
          _settingsTile(
            icon: Icons.delete_forever,
            title: "Delete Account",
            subtitle: "Permanently delete your account",
            isDestructive: true,
            onTap: () => _showDeleteAccountDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDestructive ? Colors.red.withOpacity(0.05) : AppColors.backgroundBeige,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: ListTile(
        leading: Icon(icon, color: isDestructive ? Colors.red : AppColors.accent),
        title: Text(title, style: TextStyle(color: isDestructive ? Colors.red : AppColors.darkText, fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: TextStyle(color: isDestructive ? Colors.red.withOpacity(0.7) : Colors.grey, fontSize: 13)),
        trailing: Icon(Icons.chevron_right, color: isDestructive ? Colors.red : Colors.grey),
        onTap: onTap,
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Account"),
        content: const Text("This will permanently delete your account and all associated data. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(authServiceProvider).deleteAccount();
                if (context.mounted) context.go('/welcome');
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFF4B5A4);
    const Color darkText = Color(0xFF363130);
    const Color iconColor = Color(0xFFCC7861);
    const Color iconCircleColor = Color(0xFFFAF0E6);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: darkText),
                      onPressed: () {
                        if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'My Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: primaryPink,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: iconColor),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const CircleAvatar(
                radius: 50,
                backgroundColor: iconCircleColor,
                // TODO: Replace with user's profile image
                child: Icon(Icons.person, size: 50, color: iconColor),
              ),
              const SizedBox(height: 10),
              const Text(
                'Madison Smith',
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'ID: 25030024',
                style: TextStyle(
                  fontFamily: "League Spartan",
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: primaryPink.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTopOption(Icons.design_services_outlined, 'My Designs'),
                      _buildTopOption(Icons.favorite_border, 'Liked Posts'),
                      _buildTopOption(Icons.person_outline, 'Edit Profile'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              _buildListTile(Icons.privacy_tip_outlined, 'Privacy Policy'),
              _buildListTile(Icons.notifications_outlined, 'Notifications'),
              _buildListTile(Icons.settings_outlined, 'Settings'),
              _buildListTile(Icons.help_outline, 'Help'),
              _buildListTile(Icons.logout, 'Logout', color: Colors.red),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopOption(IconData icon, String label) {
    const Color iconColor = Color(0xFFCC7861);
    const Color darkText = Color(0xFF363130);
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontFamily: "Poppins",
            color: darkText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String title, {Color color = const Color(0xFF363130)}) {
    const Color iconCircleColor = Color(0xFFFAF0E6);
    const Color iconColor = Color(0xFFCC7861);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: iconCircleColor,
            ),
            child: Icon(icon, color: title == 'Logout' ? Colors.red : iconColor),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: "Poppins",
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );
  }
}

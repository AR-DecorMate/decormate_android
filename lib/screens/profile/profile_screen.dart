import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Update this path to where your HomeScreen (and PlaceholderScreen) is located:
import 'package:decormate_android/screens/home/home_screen.dart';
import '../launch/welcome_screen.dart'; // Keep your existing logout import
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFF4B5A4);
    const Color darkText = Color(0xFF363130);
    const Color iconColor = Color(0xFFCC7861);
    const Color iconCircleColor = Color(0xFFFAF0E6);

    // Get current user
    final User? currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // --- APP BAR ---
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
                    // --- CLICKABLE EDIT ICON ---
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, color: iconColor),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PlaceholderScreen(
                                title: "Edit Profile Details"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // --- PROFILE IMAGE ---
              const CircleAvatar(
                radius: 50,
                backgroundColor: iconCircleColor,
                child: Icon(Icons.person, size: 50, color: iconColor),
              ),

              const SizedBox(height: 10),

              // --- DYNAMIC NAME & EMAIL FETCHING ---
              currentUser == null
                  ? const Text("Guest User", style: TextStyle(color: darkText))
                  : StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(currentUser.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                          height: 20,
                          width: 20,
                          child:
                          CircularProgressIndicator(strokeWidth: 2)),
                    );
                  }

                  String name = "No Name";
                  String email = currentUser.email ?? "";

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var data =
                    snapshot.data!.data() as Map<String, dynamic>;
                    name = data['name'] ?? "User";
                  }

                  return Column(
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontFamily: "Poppins",
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        email,
                        style: const TextStyle(
                          fontFamily: "League Spartan",
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              // --- STATISTICS ROW (CLICKABLE) ---
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
                      _buildTopOption(context, Icons.design_services_outlined,
                          'My Designs'),
                      _buildTopOption(
                          context, Icons.favorite_border, 'Liked Posts'),
                      _buildTopOption(
                          context, Icons.person_outline, 'Edit Profile'),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- MENU OPTIONS (CLICKABLE) ---
              _buildListTile(
                  context, Icons.privacy_tip_outlined, 'Privacy Policy'),
              _buildListTile(
                  context, Icons.notifications_outlined, 'Notifications'),
              _buildListTile(context, Icons.settings_outlined, 'Settings'),
              _buildListTile(context, Icons.help_outline, 'Help'),

              // --- LOGOUT BUTTON (LOGIC RETAINED) ---
              GestureDetector(
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const WelcomeScreen()),
                          (Route<dynamic> route) => false,
                    );
                  }
                },
                child: _buildListTile(context, Icons.logout, 'Logout',
                    color: Colors.red, isLogout: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // UPDATED: Now requires Context and wraps in GestureDetector
  Widget _buildTopOption(BuildContext context, IconData icon, String label) {
    const Color iconColor = Color(0xFFCC7861);
    const Color darkText = Color(0xFF363130);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlaceholderScreen(title: label),
          ),
        );
      },
      child: Column(
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
      ),
    );
  }

  // UPDATED: Now requires Context and wraps in InkWell (unless logout)
  Widget _buildListTile(BuildContext context, IconData icon, String title,
      {Color color = const Color(0xFF363130), bool isLogout = false}) {
    const Color iconCircleColor = Color(0xFFFAF0E6);
    const Color iconColor = Color(0xFFCC7861);

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: iconCircleColor,
            ),
            child:
            Icon(icon, color: title == 'Logout' ? Colors.red : iconColor),
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
          if (!isLogout)
            const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
        ],
      ),
    );

    if (isLogout) {
      return content;
    } else {
      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaceholderScreen(title: title),
            ),
          );
        },
        child: content,
      );
    }
  }
}
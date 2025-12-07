import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  static const Color orange = Color(0xFFCC7861);
  static const Color textDark = Color(0xFF363130);

  // ───────────────────────────────────────────────────────────────
  // SAMPLE POSTS (replace these with Firebase later)
  // ───────────────────────────────────────────────────────────────
  final List<Map<String, dynamic>> posts = [
    {
      "user": "Angela",
      "avatar": "assets/images/home/profile1.jpg",
      "caption": "My latest minimalist living room design! ✨",
      "image": "assets/images/home/livingRoom.jpg",
      "likes": 41,
      "liked": false,
    },
    {
      "user": "Mark",
      "avatar": "assets/images/home/profile2.jpg",
      "caption": "Trying out a boho bedroom theme 🌿",
      "image": "assets/images/home/bedroom.jpg",
      "likes": 27,
      "liked": false,
    },
    {
      "user": "Sarah",
      "avatar": "assets/images/home/profile3.jpg",
      "caption": "Modern kitchen setup — thoughts? 👇",
      "image": "assets/images/home/kitchen.jpg",
      "likes": 52,
      "liked": false,
    },
  ];

  // ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),

              // TITLE
              Center(child:
              const Text(
                "Community",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFCC7861),
                ),
              )),

              const SizedBox(height: 6),

              Expanded(
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    return _buildPostCard(posts[index], index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // POST CARD
  // ───────────────────────────────────────────────────────────────
  Widget _buildPostCard(Map<String, dynamic> post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // USER INFO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: AssetImage(post["avatar"]),
                ),
                const SizedBox(width: 12),
                Text(
                  post["user"],
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    color: textDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Image.asset(
              post["image"],
              height: 260,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 10),

          // CAPTION
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text(
              post["caption"],
              style: const TextStyle(
                fontFamily: "Poppins",
                fontSize: 14,
                color: textDark,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // BUTTON ROW
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // LIKE BUTTON
                IconButton(
                  icon: Icon(
                    post["liked"] ? Icons.favorite : Icons.favorite_border,
                    color: post["liked"] ? orange : Colors.grey,
                    size: 30,
                  ),
                  onPressed: () {
                    setState(() {
                      post["liked"] = !post["liked"];
                      post["likes"] += post["liked"] ? 1 : -1;
                    });
                  },
                ),

                Text(
                  "${post["likes"]}",
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    color: textDark,
                    fontSize: 14,
                  ),
                ),

                const SizedBox(width: 18),

                // COMMENT BUTTON
                IconButton(
                  icon: const Icon(Icons.mode_comment_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    _openCommentsSheet(post);
                  },
                ),

                const SizedBox(width: 18),

                // SHARE BUTTON
                IconButton(
                  icon: const Icon(Icons.share_outlined,
                      color: Colors.grey, size: 28),
                  onPressed: () {
                    Share.share("Check out this design on DecorMate!");
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // COMMENT BOTTOM SHEET
  // ───────────────────────────────────────────────────────────────
  void _openCommentsSheet(Map post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SizedBox(
          height: 650,
          width:350,
          child: Column(
            children: [
              const SizedBox(height: 14),
              Container(
                height: 5,
                width: 55,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),

              const Text(
                "Comments",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                "No comments yet. Be the first!",
                style: TextStyle(
                  fontFamily: "Poppins",
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

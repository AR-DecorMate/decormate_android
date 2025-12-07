import 'package:decormate_android/screens/community/community_screen.dart';
import 'package:decormate_android/screens/profile/profile_screen.dart';
import 'package:decormate_android/screens/saved_designs/saved_designs_screen.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreenBody(),
    const CommunityScreen(),
    const SavedDesignsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color iconColor = Color(0xFFCC7861);

    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        currentIndex: _selectedIndex,
        selectedItemColor: iconColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: "Community"),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: "Saved"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------------
// HOME BODY
// ----------------------------------------------------------------------
class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> trending = [
    {
      'title': 'Minimalist Living Room',
      'author': 'By Angela',
      'image': 'assets/images/home/livingRoom.jpg',
    },
    {
      'title': 'Bohemian Bedroom',
      'author': 'By Mark',
      'image': 'assets/images/home/bedroom.jpg',
    },
    {
      'title': 'Modern Kitchen',
      'author': 'By Sarah',
      'image': 'assets/images/home/kitchen.jpg',
    },
  ];

  final List<Map<String, dynamic>> categories = [
    {'name': 'Sofa', 'icon': Icons.weekend},
    {'name': 'Bed', 'icon': Icons.bed},
    {'name': 'Table', 'icon': Icons.table_bar},
    {'name': 'Chair', 'icon': Icons.chair_alt},
    {'name': 'Lamps', 'icon': Icons.light},
    {'name': 'Frames', 'icon': Icons.filter_frames},
    {'name': 'Fan', 'icon': Icons.toys},
    {'name': 'Lights', 'icon': Icons.lightbulb},
    {'name': 'Curtains', 'icon': Icons.storefront},
    {'name': 'Washbasin', 'icon': Icons.bathroom},
    {'name': 'Tap', 'icon': Icons.water_drop},
    {'name': 'Windows', 'icon': Icons.window},
    {'name': 'Decor', 'icon': Icons.brush},
    {'name': 'Chandelier', 'icon': Icons.wb_incandescent},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 1000);
  }

  @override
  Widget build(BuildContext context) {
    const Color orange = Color(0xFFCC7861);
    const Color textDark = Color(0xFF363130);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 55),

            // 👋 WELCOME TEXT
            const Center(
              child: Text(
                "Welcome, Madison!",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: orange,
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 🔥 AR VISUALIZER CARD
            _buildArCard(),

            const SizedBox(height: 30),

            // CATEGORIES TITLE
            const Text(
              "Categories",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 15),

            // CATEGORY SCROLL (14 ITEMS)
            SizedBox(
              height: 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(width: 14),
                itemBuilder: (_, index) {
                  return Column(
                    children: [
                      Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5EDE7),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(
                          categories[index]['icon'],
                          color: orange,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        categories[index]['name'],
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: textDark,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // TRENDING TITLE
            const Text(
              "Trending Designs",
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),

            const SizedBox(height: 15),

            // 🔥 INFINITE CAROUSEL
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index % trending.length;
                  });
                },
                itemBuilder: (_, index) {
                  final design = trending[index % trending.length];
                  return _buildTrendingCard(
                      design['title']!, design['author']!, design['image']!);
                },
              ),
            ),

            const SizedBox(height: 10),

            // ORANGE DOTS INDICATOR
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(trending.length,
                      (index) => _buildDot(index, orange)),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // DOT INDICATOR
  // -------------------------------------------------------------------
  Widget _buildDot(int index, Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: _currentPage == index ? color : color.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  // -------------------------------------------------------------------
  // AR CARD
  // -------------------------------------------------------------------
  Widget _buildArCard() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage("assets/images/home/arch3.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Visualize Your Dream Space",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.view_in_ar),
              label: const Text("Try AR Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFCC7861),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------
  // TRENDING CARD
  // -------------------------------------------------------------------
  Widget _buildTrendingCard(String title, String author, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                author,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

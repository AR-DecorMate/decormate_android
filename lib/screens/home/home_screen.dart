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
    const Scaffold(body: Center(child: Text('Search Screen'))), // Placeholder for Search
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Saved',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeScreenBody extends StatefulWidget {
  const HomeScreenBody({super.key});

  @override
  State<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends State<HomeScreenBody> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

   final List<Map<String, String>> likedDesigns = [
    {
      'title': 'Minimalist Living Room',
      'author': 'By Angela',
      'imageUrl': 'https://images.unsplash.com/photo-1554995207-c18c203602cb'
    },
    {
      'title': 'Bohemian Bedroom',
      'author': 'By Mark',
      'imageUrl': 'https://images.unsplash.com/photo-1522771739844-6a9f6d5f14af'
    },
    {
      'title': 'Modern Kitchen',
      'author': 'By Sarah',
      'imageUrl': 'https://images.unsplash.com/photo-1600585154340-be6161a56a0c'
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page!.round();
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryPink = Color(0xFFF4B5A4);
    const Color darkText = Color(0xFF363130);
    const Color iconColor = Color(0xFFCC7861);
    const Color iconCircleColor = Color(0xFFFAF0E6);

    return Stack(
      children: [
        ClipPath(
          clipper: OvalTopClipper(),
          child: Container(
            height: 200,
            color: primaryPink.withOpacity(0.2),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),
                const Text(
                  'Discover & Create',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: darkText,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                _buildArCard(primaryPink),
                const SizedBox(height: 30),
                const Text(
                  'Categories',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['Bedroom', 'Living Room', 'Kitchen', 'Dining', 'Office']
                        .map((cat) => _buildCategoryChip(cat, iconCircleColor, darkText))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Most Liked Designs',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
                ),
                const SizedBox(height: 15),
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: likedDesigns.length,
                    itemBuilder: (context, index) {
                      final design = likedDesigns[index];
                      return _buildLikedDesignCard(design['title']!, design['author']!, design['imageUrl']!);
                    },
                  ),
                ),
                const SizedBox(height: 10),
                 Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(likedDesigns.length, (index) => _buildDot(index, context, iconColor)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Container _buildDot(int index, BuildContext context, Color color) {
    return Container(
      height: 10,
      width: _currentPage == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _currentPage == index ? color : color.withOpacity(0.5),
      ),
    );
  }

  Widget _buildArCard(Color primaryColor) {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1567016376408-0226e4d0c1ea'),
          fit: BoxFit.cover,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, spreadRadius: 1)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            'Visualize Your Dream Space',
            style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black45, blurRadius: 10)]),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            icon: const Icon(Icons.view_in_ar_outlined),
            label: const Text('Try AR Now'),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, Color backgroundColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Chip(
        label: Text(label, style: TextStyle(fontFamily: 'Poppins', color: textColor, fontWeight: FontWeight.w500)),
        backgroundColor: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildLikedDesignCard(String title, String author, String imageUrl) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                author,
                style: const TextStyle(fontFamily: 'Poppins', color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OvalTopClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 40);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

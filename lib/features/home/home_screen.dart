import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../core/providers/user_provider.dart';

class HomeScreenBody extends ConsumerStatefulWidget {
  const HomeScreenBody({super.key});

  @override
  ConsumerState<HomeScreenBody> createState() => _HomeScreenBodyState();
}

class _HomeScreenBodyState extends ConsumerState<HomeScreenBody> {
  late PageController _pageController;
  int _currentPage = 0;

  final List<Map<String, String>> trending = [
    {'title': 'Minimalist Living Room', 'author': 'By Angela', 'image': 'assets/images/home/livingRoom.jpg'},
    {'title': 'Bohemian Bedroom', 'author': 'By Mark', 'image': 'assets/images/home/bedroom.jpg'},
    {'title': 'Modern Kitchen', 'author': 'By Sarah', 'image': 'assets/images/home/kitchen.jpg'},
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 35),

              // WELCOME TEXT
              Center(
                child: userAsync.when(
                  data: (user) => Text(
                    "Welcome, ${user?.name ?? 'Guest'}!",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                  loading: () => const Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                  error: (_, __) => const Text(
                    "Welcome!",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // AR VISUALIZER CARD
              _buildArCard(context),

              const SizedBox(height: 30),

              const Text(
                "Categories",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 15),

              // CATEGORIES
              SizedBox(
                height: 100,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, index) {
                    return GestureDetector(
                      onTap: () => context.push('/category/${categories[index]['name']}'),
                      child: Column(
                        children: [
                          Container(
                            width: 75,
                            height: 75,
                            decoration: BoxDecoration(
                              color: AppColors.fieldBg,
                              borderRadius: BorderRadius.circular(AppRadius.input),
                            ),
                            child: Icon(categories[index]['icon'], color: AppColors.accent, size: 32),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            categories[index]['name'],
                            style: const TextStyle(fontSize: 12, color: AppColors.darkText),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                "Trending Designs",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkText),
              ),
              const SizedBox(height: 15),

              // TRENDING CAROUSEL
              SizedBox(
                height: 220,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index % trending.length);
                  },
                  itemBuilder: (_, index) {
                    final design = trending[index % trending.length];
                    return _buildTrendingCard(design['title']!, design['author']!, design['image']!);
                  },
                ),
              ),

              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(trending.length, (index) => _buildDot(index)),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        color: _currentPage == index ? AppColors.accent : AppColors.accent.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  Widget _buildArCard(BuildContext context) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        image: const DecorationImage(
          image: AssetImage("assets/images/home/arch3.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          color: Colors.black.withOpacity(0.2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Visualize Your Dream Space",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 8, color: Colors.black)],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.push('/ar-space'),
              icon: const Icon(Icons.view_in_ar),
              label: const Text("Try AR Now"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.accent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCard(String title, String author, String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.card),
        image: DecorationImage(image: AssetImage(imagePath), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          gradient: LinearGradient(
            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Text(author, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

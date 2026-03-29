import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/constants.dart';
import '../../shared/widgets/ai_chat_fab.dart';

class HomeShell extends StatelessWidget {
  final Widget child;

  const HomeShell({super.key, required this.child});

  static const _tabs = ['/home', '/community', '/saved', '/profile'];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _tabs.indexWhere((t) => location.startsWith(t));
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);
    final location = GoRouterState.of(context).matchedLocation;
    final showAiFab = !location.startsWith('/community');

    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      floatingActionButton: showAiFab ? const AiChatFab() : null,
      bottomNavigationBar: BottomNavigationBar(
        onTap: (i) => context.go(_tabs[i]),
        currentIndex: index,
        selectedItemColor: AppColors.accent,
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

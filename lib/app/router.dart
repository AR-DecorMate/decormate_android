import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/providers/auth_provider.dart';
import '../features/launch/splash_screen.dart';
import '../features/launch/onboarding_screen.dart';
import '../features/launch/welcome_screen.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/home/home_shell.dart';
import '../features/home/home_screen.dart';
import '../features/community/community_screen.dart';
import '../features/saved_designs/saved_designs_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/profile/edit_profile_screen.dart';
import '../features/profile/my_designs_screen.dart';
import '../features/profile/liked_posts_screen.dart';
import '../features/profile/settings_screen.dart';
import '../features/profile/privacy_policy_screen.dart';
import '../features/profile/help_screen.dart';
import '../features/catalog/category_screen.dart';
import '../features/catalog/item_detail_screen.dart';
import '../features/ar/ar_space_screen.dart';
import '../features/ar/ar_placement_screen.dart';
import '../features/community/create_post_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    redirect: (context, state) async {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final location = state.matchedLocation;

      // While auth is loading, stay on splash
      if (isLoading && location == '/splash') return null;

      final publicRoutes = ['/splash', '/onboarding', '/welcome', '/login', '/signup', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(location);

      if (user != null && isPublicRoute) {
        return '/home';
      }

      if (user == null && !isPublicRoute && !isLoading) {
        final prefs = await SharedPreferences.getInstance();
        final seenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
        return seenOnboarding ? '/welcome' : '/onboarding';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main app shell with bottom navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreenBody()),
          ),
          GoRoute(
            path: '/community',
            pageBuilder: (context, state) => const NoTransitionPage(child: CommunityScreen()),
          ),
          GoRoute(
            path: '/saved',
            pageBuilder: (context, state) => const NoTransitionPage(child: SavedDesignsScreen()),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),

      // Full-screen routes (outside bottom nav shell)
      GoRoute(
        path: '/category/:categoryId',
        builder: (context, state) {
          final categoryId = state.pathParameters['categoryId']!;
          return CategoryScreen(categoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/item/:itemId',
        builder: (context, state) {
          final itemId = state.pathParameters['itemId']!;
          return ItemDetailScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/ar-space',
        builder: (context, state) {
          final itemId = state.uri.queryParameters['itemId'];
          return ArSpaceScreen(itemId: itemId);
        },
      ),
      GoRoute(
        path: '/ar-placement',
        builder: (context, state) {
          final modelPath = state.uri.queryParameters['model'] ?? '';
          final itemName = state.uri.queryParameters['name'] ?? 'Furniture';
          return ArPlacementScreen(modelPath: modelPath, itemName: itemName);
        },
      ),
      GoRoute(
        path: '/create-post',
        builder: (context, state) {
          final imageUrl = state.uri.queryParameters['imageUrl'];
          return CreatePostScreen(preImageUrl: imageUrl);
        },
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/profile/my-designs',
        builder: (context, state) => const MyDesignsScreen(),
      ),
      GoRoute(
        path: '/profile/liked-posts',
        builder: (context, state) => const LikedPostsScreen(),
      ),
      GoRoute(
        path: '/profile/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile/privacy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/profile/help',
        builder: (context, state) => const HelpScreen(),
      ),
    ],
  );
});

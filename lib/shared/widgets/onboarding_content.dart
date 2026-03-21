class OnboardingContent {
  String image;
  String title;
  String description;

  OnboardingContent({required this.image, required this.title, required this.description});
}

List<OnboardingContent> contents = [
  OnboardingContent(
    title: 'Comfortable Space',
    image: 'assets/images/onboarding/onBoardingA.png',
    description: 'Visualize furniture in your room before buying. Make confident design decisions with real-time AR preview.',
  ),
  OnboardingContent(
    title: 'Quality Furniture',
    image: 'assets/images/onboarding/onBoardingB.png',
    description: 'Browse a curated catalog of sofas, tables, beds, lamps, and more. Find the perfect piece for every room.',
  ),
  OnboardingContent(
    title: 'Expert Design',
    image: 'assets/images/onboarding/onBoardingC.png',
    description: 'Get instant AI-powered design advice. Ask about color palettes, furniture placement, and styling tips.',
  ),
  OnboardingContent(
    title: 'Your Dream Home',
    image: 'assets/images/onboarding/onBoardingD.png',
    description: 'Save your favorite designs, share with the community, and turn your interior vision into reality.',
  ),
];

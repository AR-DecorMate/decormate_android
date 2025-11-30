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
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  ),
  OnboardingContent(
    title: 'Quality Furniture',
    image: 'assets/images/onboarding/onBoardingB.png',
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  ),
  OnboardingContent(
    title: 'Expert Design',
    image: 'assets/images/onboarding/onBoardingC.png',
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  ),
  OnboardingContent(
    title: 'Your Dream Home',
    image: 'assets/images/onboarding/onBoardingD.png',
    description: "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.",
  ),
];

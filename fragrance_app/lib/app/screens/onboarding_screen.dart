import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../core/core.dart';
import '../../shared/shared.dart';
import '../router/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  int _currentIndex = 0;

  final List<OnboardingItem> _pages = [
    OnboardingItem(
      image: AppAssets.onboarding1,
      title: 'Discover Your Style',
      description: 'Explore a curated collection designed just for your unique taste and preference.',
    ),
    OnboardingItem(
      image: AppAssets.onboarding2,
      title: 'Seamless Experience',
      description: 'Enjoy a smooth, fast, and delightful journey tailored for effortless navigation.',
    ),
    OnboardingItem(
      image: AppAssets.onboarding3,
      title: 'Get Started Today',
      description: 'Join us now and unlock everything ESSENCE has to offer.',
    ),
  ];

  Future<void> _completeOnboarding(BuildContext context) async {
    await AppPreferences.setHasSeenOnboarding(true);
    if (!context.mounted) return;
    context.go(Routes.main);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConst.spaceXL,
            vertical: AppConst.spaceLG,
          ),
          child: Column(
            children: [
              const SizedBox(height: AppConst.spaceXL),
              const SizedBox(height: AppConst.spaceXL),
              const SizedBox(height: AppConst.spaceXL),

              // 2. Carousel Slider (Only Image, Title, Description move)
              CarouselSlider.builder(
                carouselController: _carouselController,
                itemCount: _pages.length,
                options: CarouselOptions(
                  height: 400,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: false,
                  onPageChanged: (index, reason) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final page = _pages[index];
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppImage(
                        image: page.image,
                        type: ImageType.asset,
                        width: 240,
                        height: 240,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: AppConst.spaceLG),
                      Text(
                        page.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: AppConst.spaceSM),
                      Text(
                        page.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),

              const Spacer(),

              // 3. Static Indicator and Bottom Controls
              Column(
                children: [
                  // Stationary Smooth Page Indicator
                  AnimatedSmoothIndicator(
                    activeIndex: _currentIndex,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      activeDotColor: colorScheme.primary,
                      dotColor: colorScheme.outline,
                    ),
                  ),

                  const SizedBox(height: AppConst.spaceXL),
                  const SizedBox(height: AppConst.spaceXL),
                  const SizedBox(height: AppConst.spaceXL),

                  // Bottom Bar with Next Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: _currentIndex < _pages.length - 1
                            ? TextButton(
                                onPressed: () => _completeOnboarding(context),
                                child: Text(
                                  'Skip',
                                  style: TextStyle(
                                    color: colorScheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            : const SizedBox(
                                height: 48,
                              ), // Keeps layout balanced when skip is hidden
                      ),

                      // Optional back or branding space if needed, keeping it empty for clean layout
                      const SizedBox.shrink(),

                      ElevatedButton(
                        onPressed: () async {
                          if (_currentIndex < _pages.length - 1) {
                            await _carouselController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            await _completeOnboarding(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppConst.spaceXL,
                            vertical: AppConst.spaceMD,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppConst.borderRadiusSM,
                          ),
                        ),
                        child: Text(
                          _currentIndex == _pages.length - 1
                              ? 'Get Started'
                              : 'Next',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  const OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

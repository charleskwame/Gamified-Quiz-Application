import 'package:flutter/material.dart';
import '../models/onboarding_page_data.dart';

class OnboardingTourScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingTourScreen({super.key, required this.onComplete});

  @override
  State<OnboardingTourScreen> createState() => _OnboardingTourScreenState();
}

class _OnboardingTourScreenState extends State<OnboardingTourScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color colorBg = Color(0xFFECF8F8);
  static const Color colorPrimary = Color(0xFF003F91);
  static const Color colorDark = Color(0xFF011627);
  static const Color colorLight = Color(0xFFFBFBFB);

  @override
  Widget build(BuildContext context) {
    final pages = OnboardingPageData.pages;
    final isLastPage = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Button Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.topRight,
                child: isLastPage
                    ? const SizedBox(height: 48) // Keep space
                    : TextButton(
                        onPressed: widget.onComplete,
                        style: TextButton.styleFrom(
                          foregroundColor: colorPrimary,
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
            ),

            // Content PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final page = pages[index];
                  return OnboardingPageContent(
                    data: page,
                    colorPrimary: colorPrimary,
                    colorDark: colorDark,
                  );
                },
              ),
            ),

            // Indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 8.0,
                    width: _currentPage == index ? 24.0 : 8.0,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? colorPrimary
                          : colorPrimary.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24.0, 0, 24.0, 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: colorDark,
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 60),

                  // Next / Get Started Button
                  if (isLastPage)
                    ElevatedButton(
                      onPressed: widget.onComplete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        foregroundColor: colorLight,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        foregroundColor: colorLight,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Next',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPageContent extends StatefulWidget {
  final OnboardingPageData data;
  final Color colorPrimary;
  final Color colorDark;

  const OnboardingPageContent({
    super.key,
    required this.data,
    required this.colorPrimary,
    required this.colorDark,
  });

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Styled circular container for Icon
          ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: widget.colorPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: widget.colorPrimary.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                widget.data.icon,
                size: 60,
                color: const Color(0xFFFBFBFB),
              ),
            ),
          ),
          const SizedBox(height: 48),
          
          // Title
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              widget.data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.colorDark,
                fontSize: 26,
                fontWeight: FontWeight.w900,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description
          FadeTransition(
            opacity: _fadeAnimation,
            child: Text(
              widget.data.description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: widget.colorDark.withOpacity(0.7),
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

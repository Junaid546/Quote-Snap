import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'SNAP A PHOTO.',
      'subtitle': 'GET A QUOTE.',
      'description': 'Generate professional estimates instantly',
      'icon': Icons
          .camera_alt_rounded, // Temporary stand-in for complex illustration
      'iconColor': Colors.white.withAlpha(230),
    },
    {
      'title': 'SEND IN SECONDS.',
      'subtitle': '',
      'description': 'WhatsApp or Email your quote directly to clients',
      'icon': Icons.send_rounded, // Temporary stand-in
      'iconColor': AppColors.success,
    },
    {
      'title': 'WIN MORE JOBS.',
      'subtitle': '',
      'description': 'Track all quotes, clients and earnings in one place',
      'icon': Icons.dashboard_rounded, // Temporary stand-in
      'iconColor': AppColors.primary,
    },
  ];

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    context.go('/login');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // Strict enforcement
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _completeOnboarding,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        color: const Color(0xFF8A8F9E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Placeholder (mimicking descriptions)
                        Expanded(
                          child: Center(
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (slide['iconColor'] as Color)
                                        .withAlpha(26),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                slide['icon'],
                                size: 80,
                                color: slide['iconColor'],
                              ),
                            ),
                          ),
                        ),

                        // Text Content
                        const SizedBox(height: 48),
                        Text(
                          slide['title'],
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (slide['subtitle'].isNotEmpty)
                          Text(
                            slide['subtitle'],
                            style: GoogleFonts.barlowCondensed(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 16),
                        Text(
                          slide['description'],
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: const Color(0xFF8A8F9E),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 64),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Controls Layer
            Padding(
              padding: const EdgeInsets.all(AppSpacing.p24),
              child: Column(
                children: [
                  // Dot Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == index ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : const Color(0xFF2A2D3A), // Gray dot
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary Action Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEC5B13), Color(0xFFFF8C42)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.transparent, // Let gradient show
                        shadowColor:
                            Colors.transparent, // Disable default shadow
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

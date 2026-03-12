import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // Tagline animation
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _progressController,
        curve: const Interval(0.5, 1.0, curve: Curves.easeIn),
      ),
    );

    _progressController.addListener(() {
      setState(() {});
    });

    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Start animation
    _progressController.forward();

    // Check auth status
    final user = FirebaseAuth.instance.currentUser;

    // Check onboarding status
    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

    // Wait for the minimal animation duration
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    if (user != null) {
      context.go('/home/dashboard');
    } else if (!onboardingDone) {
      context.go('/onboarding');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1117), // Enforce background explicitly
      body: Stack(
        children: [
          // Subtle radial orange glow
          Positioned.fill(
            child: Center(
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withAlpha(38),
                      const Color(0xFF0F1117).withAlpha(0),
                    ],
                    stops: const [0.0, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Logo (document + bolt)
                        SizedBox(
                          width: 80,
                          height: 100,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Document Icon
                              Positioned(
                                top: 0,
                                child: Icon(
                                  Icons.description_rounded,
                                  size: 72,
                                  color: Colors.white.withAlpha(77),
                                ),
                              ),
                              // Lightning Bolt
                              const Positioned(
                                bottom: 0,
                                right: 0,
                                child: Icon(
                                  Icons.bolt_rounded,
                                  size: 64,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // App Name
                        Text(
                          'QUOTESNAP',
                          style: GoogleFonts.barlowCondensed(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        // Tagline
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            'WIN JOBS FASTER',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8A8F9E),
                              letterSpacing: 4.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Progress Bar Area
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40.0,
                    vertical: 48.0,
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'SYSTEM INITIALIZING',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8A8F9E),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${(_progressAnimation.value * 100).toInt()}%',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(1.5),
                        child: LinearProgressIndicator(
                          value: _progressAnimation.value,
                          minHeight: 3,
                          backgroundColor: Colors.white.withAlpha(26),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

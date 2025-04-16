import 'package:eventure/core/constants/colors.dart';
import 'package:eventure/core/helpers/device_utility.dart';
import 'package:eventure/src/bottom_navigation_screen.dart';
import 'package:eventure/src/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Text animation controller
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Setup animations
    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    );

    _textAnimation = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    );

    // Start animations sequentially
    _logoController.forward().then((_) => _textController.forward());

    // Check auth after animations complete
    Future.delayed(const Duration(milliseconds: 3000), () {
      _checkAuth();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final user = Supabase.instance.client.auth.currentUser;

    if (user != null) {
      // Already logged in
      Get.offAll(() => const BottomNavigationScreen());
    } else {
      // Not logged in
      Get.offAll(() => const LoginScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          IDeviceUtils.isDarkMode(context) ? IColors.dark : IColors.light,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animation
            ScaleTransition(
              scale: _logoAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: IDeviceUtils.isDarkMode(context)
                        ? IColors.light
                        : Colors.black12,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: IDeviceUtils.isDarkMode(context)
                            ? IColors.light
                            : IColors.dark)),
                child: Image.asset(
                  'assets/images/logo.png', // Replace with your logo asset
                  // If you don't have a logo asset, use a placeholder icon
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.event_available_rounded,
                    size: 80,
                    color: IColors.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App name animation
            FadeTransition(
              opacity: _textAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_textAnimation),
                child: Column(
                  children: [
                    Text(
                      'Eventure',
                      style: TextStyle(
                        color: IDeviceUtils.isDarkMode(context)
                            ? Colors.white
                            : IColors.black,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your Journey to Great Events',
                      style: TextStyle(
                        color: IDeviceUtils.isDarkMode(context)
                            ? Colors.white
                            : IColors.black,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            FadeTransition(
              opacity: _textAnimation,
              child: const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

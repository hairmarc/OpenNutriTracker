import 'dart:async';

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';

/// First screen shown on launch: the GO Calorie logo, then a route on to the
/// main screen (returning user) or onboarding (first run).
///
/// The native launch screen (Android `launch_background`, iOS
/// `LaunchScreen.storyboard`) paints the same canvas colour behind the Flutter
/// engine while it boots, so the hand-off into this splash is seamless.
class SplashScreen extends StatefulWidget {
  /// Whether the user has already completed onboarding. Decides where the
  /// splash routes once it is on screen.
  final bool userInitialized;

  const SplashScreen({super.key, required this.userInitialized});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _logoSize = 168.0;
  static const _hold = Duration(milliseconds: 600);

  bool _navigated = false;
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _holdTimer = Timer(_hold, _goNext);
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _goNext() {
    if (_navigated || !mounted) return;
    _navigated = true;
    Navigator.of(context).pushReplacementNamed(widget.userInitialized
        ? NavigationOptions.mainRoute
        : NavigationOptions.onboardingRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_logoSize * 0.25),
          child: Image.asset(
            'assets/icon/go_calorie_icon.png',
            width: _logoSize,
            height: _logoSize,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}

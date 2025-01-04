import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'SignIn.dart';

import 'package:summarify/Pages/BottomNav.dart';

class ImageSplashScreen extends StatefulWidget {
  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<ImageSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward().then((_) async {
      // Check login status after the splash screen
      bool isLoggedIn = await _checkLoginStatus();

      // Delay for 2 seconds before navigating
      Timer(Duration(seconds: 2), () {
        if (isLoggedIn) {
          // Navigate to Home Screen if logged in
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainPage()),
          );
        } else {
          // Navigate to Sign In screen if not logged in
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        }
      });
    });
  }

  // This function checks whether the user is logged in using Firebase Auth
  Future<bool> _checkLoginStatus() async {
    User? user = FirebaseAuth.instance.currentUser;
    return user != null; // Return true if the user is logged in
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Opacity(
                opacity: _animation.value,
                child: Transform(
                  transform: Matrix4.identity()
                    ..scale(1 + _animation.value * 0.2),
                  alignment: Alignment.center,
                  child: Image.asset(
                    'assets/background/Splash.jpeg',
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
          Container(
            color: Colors.black
                .withOpacity(0.4), // Overlay to enhance text visibility
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _fadeAnimation.value,
                      child: Text(
                        'Summarify',
                        style: TextStyle(
                          fontFamily: 'DancingScript', 
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black.withOpacity(0.6),
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

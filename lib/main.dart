import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:summarify/Pages/BottomNav.dart';
import 'package:summarify/Pages/SignIn.dart';
import 'package:summarify/Pages/SplashScreen.dart';
import 'package:summarify/Utilities/theme_provider.dart';
import 'package:summarify/API/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebase(); // Ensure Firebase is initialized
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,  // Use the persisted theme
            home:ImageSplashScreen(),
            );
        },
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:summarify/API/firebase_service.dart';

import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';

class DetailPage extends StatelessWidget {
  final Map<String, dynamic> result;

  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;

  DetailPage({required this.result});

  void _shareResult(String text) {
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    _firebaseService.logUserActivity('User reviewing Summary');
    // Create a string to share
    final String shareContent = '''
      Title: ${result['title']}
      Summary: ${result['summary']}
      MCQ Questions: ${result['mcq_questions']?.join(', ')}
      Brief Questions: ${result['brief_questions']?.join(', ')}
    ''';

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background/Bg.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Gradient Overlay
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF73AEF5).withOpacity(0.6),
                  Color(0xFF61A4F1).withOpacity(0.6),
                  Color(0xFF478DE0).withOpacity(0.6),
                  Color(0xFF398AE5).withOpacity(0.6),
                ],
                stops: [0.1, 0.4, 0.7, 0.9],
              ),
            ),
          ),
          // Content Container
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              top: 60.0, // Adjust this value for the top padding
              bottom: 16.0, // Bottom padding
              left: 16.0, // Left padding
              right: 16.0, // Right padding
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: Offset(0, 4), // changes position of shadow
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      '${result['title']}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: themeProvider.isDarkMode
                            ? Colors.white
                            : Colors.black,
                      ),
                    ),
                    SizedBox(height: 15),

                    Text(
                      '    ${result['summary'].toString()}', // Adds 4 spaces before the text
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black),
                    ),
                    SizedBox(height: 10),
                    // MCQ Questions
                    Text(
                      'MCQ Questions:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black // Change text color to black
                          ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List<String>.from(result['mcq_questions'] ?? [])
                          .map((q) => Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  q,
                                  style: TextStyle(
                                      color: themeProvider.isDarkMode
                                          ? Colors.white
                                          : Colors.black),
                                ),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 10),
                    // Brief Questions
                    Text(
                      'Brief Questions:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black // Change text color to black
                          ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children:
                          List<String>.from(result['brief_questions'] ?? [])
                              .map((q) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      q,
                                      style: TextStyle(
                                          color: themeProvider.isDarkMode
                                              ? Colors.white
                                              : Colors.black),
                                    ),
                                  ))
                              .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _shareResult(shareContent),
        child: Icon(Icons.share),
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue, // You can change the color as needed
      ),
    );
  }
}

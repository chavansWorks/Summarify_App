import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summarify/Utilities/Custom_Button.dart';
import 'package:summarify/Utilities/theme_provider.dart';
import 'package:summarify/API/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPopup extends StatelessWidget {
  final CollectionReference feedbackCollection =
      FirebaseFirestore.instance.collection('feedbacks');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;

  void saveFeedback(BuildContext context, String feedback) async {
    String userId = _auth.currentUser?.uid ?? '';

    await feedbackCollection.add({
      'feedback': feedback,
      'timestamp': FieldValue.serverTimestamp(),
      'userId': userId,
    });

    _firebaseService.logUserActivity('User provided feedback');
    // Show thank you popup
    showDialog(
      context: context,
      builder: (context) => ThankYouPopup(),
    );

    // Close feedback popup after showing thank you popup
    Future.delayed(Duration(seconds: 3), () {
      Navigator.of(context).pop(); // Close the thank you popup
      Navigator.of(context).pop(); // Close the feedback popup
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return AlertDialog(
      title: Text('Feedback'),
      content: Container(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'How satisfied are you with your experience using Summarify?',
              style: TextStyle(
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                FeedbackButton(
                  icon: Icons.sentiment_very_dissatisfied,
                  label: 'Bad',
                  onPressed: () => saveFeedback(context, 'Bad'),
                ),
                FeedbackButton(
                  icon: Icons.sentiment_dissatisfied,
                  label: 'Poor',
                  onPressed: () => saveFeedback(context, 'Poor'),
                ),
                FeedbackButton(
                  icon: Icons.sentiment_neutral,
                  label: 'Neutral',
                  onPressed: () => saveFeedback(context, 'Neutral'),
                ),
                FeedbackButton(
                  icon: Icons.sentiment_satisfied,
                  label: 'Good',
                  onPressed: () => saveFeedback(context, 'Good'),
                ),
                FeedbackButton(
                  icon: Icons.sentiment_very_satisfied,
                  label: 'Awesome',
                  onPressed: () => saveFeedback(context, 'Awesome'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: <Widget>[
        SizedBox(
          height: 50,
          width: 80,
          child: CustomButton(
            text: 'Close',
            onPressed: () {
              Navigator.of(context).pop();
            },
            isOutlined: false,
            isGradient: false,
            isCircular: false,
            color: themeProvider.isDarkMode ? Colors.black : Colors.white,
            backgroundColor:
                themeProvider.isDarkMode ? Colors.grey[800]! : Colors.blue,
          ),
        ),
      ],
    );
  }
}

class FeedbackButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  FeedbackButton(
      {required this.icon, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      child: Column(
        children: [
          GestureDetector(
            onTap: onPressed,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: Colors.blue[600],
                size: 25,
              ),
            ),
          ),
          SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ThankYouPopup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Thank You',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        'We appreciate your feedback!😊',
        style: TextStyle(
          fontSize: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

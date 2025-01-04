import 'package:flutter/material.dart';
import 'package:summarify/API/firebase_service.dart';
import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';

class EditResultPage extends StatefulWidget {
  final Map<String, dynamic> result;
  final Function(Map<String, dynamic>) onSave;

  EditResultPage({required this.result, required this.onSave});

  @override
  _EditResultPageState createState() => _EditResultPageState();
}

class _EditResultPageState extends State<EditResultPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController =
        TextEditingController(text: _formatContent(widget.result));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  String _getCardContent(Map<String, dynamic> result) {
    final title = result['title'] ?? 'No title available';
    final summary = result['summary']?.toString() ?? 'No summary available';
    final mcqQuestions =
        List<String>.from(result['mcq_questions'] ?? []).join('\n');
    final briefQuestions =
        List<String>.from(result['brief_questions'] ?? []).join('\n');

    return '''
$title

Summary:
$summary

MCQ Questions:
$mcqQuestions

Brief Questions:
$briefQuestions
''';
  }

  String _formatContent(Map<String, dynamic> result) {
    final title = result['title'] ?? 'No title available';
    final summary = result['summary']?.toString() ?? 'No summary available';
    final mcqQuestions =
        List<String>.from(result['mcq_questions'] ?? []).join('\n');
    final briefQuestions =
        List<String>.from(result['brief_questions'] ?? []).join('\n');

    return '''
$title

$summary

MCQ Questions:
$mcqQuestions

Brief Questions:
$briefQuestions
''';
  }

  void _save() {
    final updatedResult = _parseContent(_contentController.text);
    widget.onSave(updatedResult);
    _firebaseService.logUserActivity('User edited Summary');
    Navigator.pop(context);
  }

  Map<String, dynamic> _parseContent(String content) {
    final lines = content.split('\n');
    final title = lines[0];
    final summaryIndex = lines.indexOf('Summary:') + 1;
    final mcqIndex = lines.indexOf('MCQ Questions:') + 1;
    final briefIndex = lines.indexOf('Brief Questions:') + 1;

    final summaryLines = lines.sublist(summaryIndex, mcqIndex - 1);
    final mcqLines = lines.sublist(mcqIndex, briefIndex - 1);
    final briefLines = lines.sublist(briefIndex);

    return {
      'title': title,
      'summary': summaryLines.join('\n'),
      'mcq_questions': mcqLines,
      'brief_questions': briefLines,
    };
  }

  void _cancel() {
    Navigator.pop(context); // Just go back without saving
  }

  // void _toggleTheme() {
  //   // Use ThemeProvider to toggle the theme
  //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            "Edit Summary",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 26,
            ),
          ),
        ),
        backgroundColor: Colors.transparent, // Makes the background transparent
        elevation: 0, // Removes the shadow beneath the AppBar
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
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
          Padding(
            padding: const EdgeInsets.only(
                right: 16.0, left: 16.0, top: 80, bottom: 16.0),
            child: Column(
              children: [
                Expanded(
                  child: Card(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[900]
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        cursorColor: Colors.blue,
                        controller: _contentController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        style: TextStyle(
                            fontSize: 15,
                            color: themeProvider.isDarkMode
                                ? Colors.white
                                : Colors.black),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 10,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _cancel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800], // Save button color
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue, width: 2),
                        minimumSize: Size(90, 50),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[800], // Save button color
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.blue, width: 2),
                        minimumSize: Size(90, 50),
                      ),
                      child: Text(
                        'Save',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

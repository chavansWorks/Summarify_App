import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:summarify/API/firebase_service.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_picker/file_picker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:summarify/Pages/EditScreen.dart';
import 'dart:io';
import 'package:translator/translator.dart';
import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';

class SummarizeContent extends StatefulWidget {
  List<Map<String, dynamic>> summarizeContent;

  SummarizeContent({required this.summarizeContent});

  @override
  _SummarizeContentState createState() => _SummarizeContentState();
}

class _SummarizeContentState extends State<SummarizeContent> {
  final FirebaseService _firebaseService = FirebaseService();
  final GoogleTranslator _translator = GoogleTranslator();
  String _currentLanguageCode = 'en'; // Default language is English

  void initState() {
    super.initState();
    // Log initial activity
    _firebaseService.logUserActivity('User got Summary');
  }

  Future<String> _translateText(String text, String targetLanguage) async {
    try {
      // Perform translation
      final translation = await _translator.translate(text, to: targetLanguage);
      return translation.text;
    } catch (e) {
      // Handle errors
      print('Error during translation: $e');
      return 'Translation error';
    }
  }

  void _toggleLanguage(String selectedLanguageCode) {
    setState(() {
      // Set _currentLanguageCode to the selected language
      _currentLanguageCode = selectedLanguageCode;
      _updateTranslatedResults(); // Update translations
    });
  }

  Future<void> _updateTranslatedResults() async {
    List<Map<String, dynamic>> translatedResults = [];

    for (var result in widget.summarizeContent) {
      try {
        // Translate text fields
        String translatedSummary = await _translateText(
          result['summary']?.toString() ?? 'No summary available',
          _currentLanguageCode,
        );
        String translatedTitle = await _translateText(
          result['title']?.toString() ?? 'No title available',
          _currentLanguageCode,
        );

        // Translate list fields (if needed)
        List<String> translatedMcqQuestions = await Future.wait(
            (result['mcq_questions'] as List<dynamic>? ?? []).map((item) =>
                _translateText(item.toString(), _currentLanguageCode)));

        List<String> translatedBriefQuestions = await Future.wait(
            (result['brief_questions'] as List<dynamic>? ?? []).map((item) =>
                _translateText(item.toString(), _currentLanguageCode)));

        translatedResults.add({
          'title': translatedTitle,
          'summary': translatedSummary,
          'mcq_questions': translatedMcqQuestions,
          'brief_questions': translatedBriefQuestions,
          'timestamp': result['timestamp'] ?? DateTime.now().toUtc().toString(),
        });
      } catch (e) {
        // Handle errors during translation
        print('Error translating fields: $e');
      }
    }

    // Update state with translated results
    setState(() {
      widget.summarizeContent = translatedResults;
    });
  }

  void _shareContent(String text) {
    Share.share(text);
  }

  Future<void> _saveSingleContent(Map<String, dynamic> result) async {
    try {
      final formattedResult = {
        'title': result['title'] ?? 'No title available',
        'summary': result['summary']?.toString() ?? 'No summary available',
        'mcq_questions': List<String>.from(
            result['mcq_questions'] ?? []), // Ensure this is a list of strings
        'brief_questions': List<String>.from(result['brief_questions'] ??
            []), // Ensure this is a list of strings
        'timestamp': result['timestamp'] ??
            DateTime.now()
                .toUtc()
                .toString() // Default to current time if not provided
      };

      await _firebaseService
          .saveResults([formattedResult]); // Save only this result
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summary saved successfully',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
        ),
      );
    } catch (e) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save result',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
        ),
      );
    }
  }

  Future<void> _saveMultipleContent() async {
    try {
      await _firebaseService.saveResults(widget.summarizeContent);
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summaries saved successfully',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
        ),
      );
      _firebaseService.logUserActivity('User Saved All summaries');
    } catch (e) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save results',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
        ),
      );
    }
  }

  void _copyContent(String text) {
    Clipboard.setData(ClipboardData(text: text));
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Copied to clipboard',
          style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        behavior: SnackBarBehavior
            .floating, // Makes the snackbar float above the bottom
        margin:
            EdgeInsets.only(left: 20.0, right: 20.0), // Adjust margin as needed
      ),
    );
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

  void _editContent(Map<String, dynamic> result) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditResultPage(
          result: result,
          onSave: (updatedResult) {
            setState(() {
              final index = widget.summarizeContent.indexOf(result);
              widget.summarizeContent[index] = updatedResult;
            });
          },
        ),
      ),
    );
  }

  Future<void> generatePDF(BuildContext context) async {
    // Check if the current language is not English
    if (_currentLanguageCode != 'en') {
      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Language Notice'),
            content: Text(
                'Please switch to English for PDF generation. More languages coming soon!'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return; // Stop the PDF generation if the language is not English
    }

    // Prompt user for the PDF title
    final titleController = TextEditingController();
    String? pdfTitle = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter PDF Title'),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(hintText: 'Enter title here'),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // User cancelled
              },
            ),
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context)
                    .pop(titleController.text); // User provided a title
              },
            ),
          ],
        );
      },
    );

    if (pdfTitle == null || pdfTitle.isEmpty) {
      // If no title is provided, show an error or return
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF title is required',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(left: 20.0, right: 20.0),
        ),
      );
      return;
    }

    final pdf = pw.Document();

    // Define text styles
    final headerStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 18,
      color: PdfColors.blue800,
    );

    final normalTextStyle = pw.TextStyle(
      fontSize: 14,
      color: PdfColors.black,
    );

    final sectionTitleStyle = pw.TextStyle(
      fontWeight: pw.FontWeight.bold,
      fontSize: 16,
      color: PdfColors.blue900,
    );

    // Function to add questions and handle pagination
    void addQuestionsToPdf(String title, List<String> questions) {
      const questionsPerPage = 40;
      final totalPages = (questions.length / questionsPerPage).ceil();

      for (int pageIndex = 0; pageIndex < totalPages; pageIndex++) {
        final start = pageIndex * questionsPerPage;
        final end = start + questionsPerPage > questions.length
            ? questions.length
            : start + questionsPerPage;
        final pageQuestions = questions.sublist(start, end);

        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(16.0),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(title, style: sectionTitleStyle),
                    pw.SizedBox(height: 20),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: pageQuestions
                          .map((q) => pw.Padding(
                                padding: const pw.EdgeInsets.symmetric(
                                    vertical: 10.0),
                                child: pw.Text(q, style: normalTextStyle),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      }
    }

    for (var result in widget.summarizeContent) {
      List<String> mcqQuestions =
          List<String>.from(result['mcq_questions'] ?? []);
      List<String> briefQuestions =
          List<String>.from(result['brief_questions'] ?? []);

      // Adding title and summary
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Padding(
              padding: const pw.EdgeInsets.all(16.0),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(result['title'] ?? 'No title available',
                      style: headerStyle),
                  pw.SizedBox(height: 20),
                  pw.Text('Summary:', style: sectionTitleStyle),
                  pw.SizedBox(height: 5),
                  pw.Text(
                      result['summary']?.toString() ?? 'No summary available',
                      style: normalTextStyle),
                  pw.SizedBox(height: 10),
                ],
              ),
            );
          },
        ),
      );

      // Add MCQ Questions
      addQuestionsToPdf('MCQ Questions:', mcqQuestions);

      // Add Brief Questions
      addQuestionsToPdf('Brief Questions:', briefQuestions);
    }

    // Save the PDF to a file
    final result = await FilePicker.platform.getDirectoryPath();

    if (result != null) {
      final path =
          '$result/$pdfTitle.pdf'; // Use the provided title for the file name
      final file = File(path);
      await file.writeAsBytes(await pdf.save());

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('PDF Generated'),
          content: Text('PDF has been saved to $path'),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Operation Cancelled'),
          content: Text('No folder was selected.'),
          actions: [
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<Map<String, dynamic>> _translateFields(
      Map<String, dynamic> result, String targetLanguage) async {
    final translator =
        GoogleTranslator(); // Assuming you use this for translation
    try {
      final title = await translator.translate(
          result['title'] ?? 'No title available',
          to: targetLanguage);
      final summary = await translator.translate(
          result['summary']?.toString() ?? 'No summary available',
          to: targetLanguage);

      // Ensure mcq_questions and brief_questions are lists of strings
      final mcqQuestions =
          List<String>.from(result['mcq_questions'] ?? []).join('\n');
      final briefQuestions =
          List<String>.from(result['brief_questions'] ?? []).join('\n');

      final translatedMcqQuestions =
          await translator.translate(mcqQuestions, to: targetLanguage);
      final translatedBriefQuestions =
          await translator.translate(briefQuestions, to: targetLanguage);

      return {
        'title': title.text,
        'summary': summary.text,
        'mcq_questions': translatedMcqQuestions.text
            .split('\n'), // Convert back to list of strings
        'brief_questions': translatedBriefQuestions.text
            .split('\n'), // Convert back to list of strings
        'timestamp': result['timestamp'] ??
            DateTime.now().toUtc().toString(), // Preserve timestamp
      };
    } catch (e) {
      print('Error during translation: $e');
      return {
        'title': 'Translation error',
        'summary': 'Translation error',
        'mcq_questions': ['Translation error'],
        'brief_questions': ['Translation error'],
        'timestamp': DateTime.now().toUtc().toString(),
      };
    }
  }

  // void _toggleTheme() {
  //   // Use ThemeProvider to toggle the theme
  //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  // }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    Widget _buildMenuItem(String title, IconData icon) {
      return Row(
        children: [
          Icon(icon, color: Colors.blue), // Customize icon color
          SizedBox(width: 8.0), // Add spacing between icon and text
          Text(
            title,
            style: TextStyle(
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.only(left: 40.0),
          child: Center(
            child: FutureBuilder<String>(
              future: _translateText("Summary", _currentLanguageCode),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator(); // Show a  spinner while waiting
                } else if (snapshot.hasError) {
                  return Text('Error'); // Handle errors
                } else {
                  return Text(
                    snapshot.data ?? 'Summary',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 26,
                    ),
                  );
                }
              },
            ),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              _currentLanguageCode == 'en'
                  ? Icons.translate
                  : _currentLanguageCode == 'es'
                      ? Icons.translate
                      : Icons.g_translate,
              color: Colors.white,
            ),
            onSelected: _toggleLanguage,
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem(
                  value: 'en',
                  child: _buildMenuItem('English', Icons.language),
                ),
                PopupMenuItem(
                  value: 'hi',
                  child: _buildMenuItem('Hindi', Icons.language),
                ),
                PopupMenuItem(
                  value: 'mr',
                  child: _buildMenuItem('Marathi', Icons.language),
                ),
                PopupMenuItem(
                  value: 'te',
                  child: _buildMenuItem('Telugu', Icons.language),
                ),
                PopupMenuItem(
                  value: 'kn',
                  child: _buildMenuItem('Kannada', Icons.language),
                ),
                PopupMenuItem(
                  value: 'es',
                  child: _buildMenuItem('Spanish', Icons.language),
                ),
                PopupMenuItem(
                  value: 'fr',
                  child: _buildMenuItem('French', Icons.language),
                ),
                PopupMenuItem(
                  value: 'ko',
                  child: _buildMenuItem('Korean', Icons.language),
                ),
              ];
            },
          ),
        ],
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
            padding: const EdgeInsets.all(16.0),
            child: widget.summarizeContent.isEmpty
                ? FutureBuilder<String>(
                    future: _translateText(
                        'No summary available', _currentLanguageCode,),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error'));
                      } else {
                        return Center(
                            child:
                                Text(snapshot.data ?? 'No summary available',style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ));
                      }
                    },
                  )
                : ListView.builder(
                    padding: EdgeInsets.only(bottom: 80.0),
                    itemCount: widget.summarizeContent.length,
                    itemBuilder: (context, index) {
                      final result = widget.summarizeContent[index];
                      final cardContent = _getCardContent(result);
                      final padding = index == 0
                          ? EdgeInsets.only(top: 65.0)
                          : EdgeInsets.zero;

                      return Padding(
                        padding: padding,
                        child: Card(
                          color: themeProvider.isDarkMode
                              ? Colors.grey[900]
                              : Colors.white,
                          margin: EdgeInsets.symmetric(vertical: 8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FutureBuilder<String>(
                                  future: _translateText(
                                      result['title'] ?? 'No title available',
                                      _currentLanguageCode),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('');
                                    } else if (snapshot.hasError) {
                                      return Text('Error');
                                    } else {
                                      return Text(
                                        snapshot.data ?? 'No title available',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: 10),
                                FutureBuilder<String>(
                                  future: _translateText(
                                    result['summary']?.toString() ??
                                        'No summary available',
                                    _currentLanguageCode,
                                  ),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<String> snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                          child: CircularProgressIndicator());
                                    } else if (snapshot.hasError) {
                                      return Center(
                                          child:
                                              Text('Error: ${snapshot.error}'));
                                    } else {
                                      String text = snapshot.data ?? 'No data';
                                      // Add a leading space here
                                      return Text(
                                        '      $text',
                                        style: TextStyle(fontSize: 15),
                                      );
                                    }
                                  },
                                ),
                                SizedBox(height: 20),
                                FutureBuilder<String>(
                                  future: _translateText(
                                      'MCQ Questions:', _currentLanguageCode),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('');
                                    } else if (snapshot.hasError) {
                                      return Text('Error');
                                    } else {
                                      return Text(
                                        snapshot.data ?? 'MCQ Questions:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      );
                                    }
                                  },
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List<String>.from(
                                          result['mcq_questions'] ?? [])
                                      .map((q) => FutureBuilder<String>(
                                            future: _translateText(
                                                q, _currentLanguageCode),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text(''),
                                                );
                                              } else if (snapshot.hasError) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text('Error'),
                                                );
                                              } else {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text(
                                                    snapshot.data ?? q,
                                                    style:
                                                        TextStyle(fontSize: 15),
                                                  ),
                                                );
                                              }
                                            },
                                          ))
                                      .toList(),
                                ),
                                SizedBox(height: 20),
                                FutureBuilder<String>(
                                  future: _translateText(
                                      'Brief Questions:', _currentLanguageCode),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Text('');
                                    } else if (snapshot.hasError) {
                                      return Text('Error');
                                    } else {
                                      return Text(
                                        snapshot.data ?? 'Brief Questions:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      );
                                    }
                                  },
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: List<String>.from(
                                          result['brief_questions'] ?? [])
                                      .map((q) => FutureBuilder<String>(
                                            future: _translateText(
                                                q, _currentLanguageCode),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text(''),
                                                );
                                              } else if (snapshot.hasError) {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text('Error'),
                                                );
                                              } else {
                                                return Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(vertical: 4.0),
                                                  child: Text(
                                                    snapshot.data ?? q,
                                                    style:
                                                        TextStyle(fontSize: 15),
                                                  ),
                                                );
                                              }
                                            },
                                          ))
                                      .toList(),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: Icon(Icons.edit),
                                      onPressed: () {
                                        _editContent(result);
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.copy),
                                      onPressed: () async {
                                        // Ensure _translateText is awaited and results are used correctly
                                        final translatedText =
                                            await _translateText(cardContent,
                                                _currentLanguageCode);
                                        _copyContent(translatedText);
                                        _firebaseService.logUserActivity(
                                            'User Copied Summary');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.share),
                                      onPressed: () async {
                                        final translatedText =
                                            await _translateText(cardContent,
                                                _currentLanguageCode);

                                        _shareContent(translatedText);
                                        _firebaseService.logUserActivity(
                                            'User Shared Summary');
                                      },
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.save),
                                      onPressed: () async {
                                        try {
                                          if (result.isNotEmpty &&
                                              _currentLanguageCode.isNotEmpty) {
                                            final translatedFields =
                                                await _translateFields(result,
                                                    _currentLanguageCode);
                                            print(
                                                'Translated fields: $translatedFields'); // Debug log

                                            await _saveSingleContent(
                                                translatedFields);

                                            _firebaseService.logUserActivity(
                                                'User Saved Summary');
                                          } else {
                                            print(
                                                'Invalid Summary or language code');
                                          }
                                        } catch (e) {
                                          print('Error in onPressed: $e');
                                        }
                                      },
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        overlayColor: Colors.black,
        overlayOpacity: 0.5,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        buttonSize: const Size(56.0, 56.0),
        visible: true,
        closeManually: false,
        children: [
          SpeedDialChild(
            child: Icon(Icons.picture_as_pdf),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            label: 'Generate PDF',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: () => {
              generatePDF(context),
              _firebaseService.logUserActivity('User Generated PDF')
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.save),
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            label: 'Save All Summaries',
            labelStyle: TextStyle(fontSize: 18.0),
            onTap: _saveMultipleContent,
          ),
        ],
      ),
    );
  }
}

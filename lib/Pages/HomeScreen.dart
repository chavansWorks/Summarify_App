import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:summarify/Pages/DashBoard.dart';
import 'package:summarify/API/firebase_service.dart';
import 'package:summarify/Pages/Summaries_History.dart';
import 'package:summarify/Utilities/Custom_Button.dart';
import 'package:summarify/Pages/SummarizeContentScreen.dart';
import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

class SummaryPage extends StatefulWidget {
  @override
  _SummaryPageState createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  TextEditingController _textEditingController = TextEditingController();
  List<File> _files = [];
  File? _singleFile;
  String _textInput = '';
  double _summaryLength = 0.5;
  int _detailLevel = 2;

  void initState() {
    super.initState();
    // Log initial activity
    _firebaseService.logUserActivity('User entered Home Screen');
  }

  Future<void> _pickFiles(String userId) async {
    final summarizeContent = await FilePicker.platform.pickFiles(
      allowMultiple: true,
    );

    if (summarizeContent != null) {
      List<File> selectedFiles = [];
      bool invalidFile = false;

      for (var path in summarizeContent.paths) {
        if (path != null) {
          File file = File(path);
          String fileExtension = path.split('.').last.toLowerCase();

          if (['pptx', 'txt', 'docx', 'pdf'].contains(fileExtension)) {
            selectedFiles.add(file);
          } else {
            invalidFile = true;
            break;
          }
        }
      }

      if (invalidFile) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Summarify supports pptx, txt, docx, pdf files only.',
              style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 40.0, left: 20.0, right: 20.0),
          ),
        );

        _firebaseService.logUserActivity('Invalid file type selected');
      } else {
        setState(() {
          if (selectedFiles.isNotEmpty) {
            _files = selectedFiles.length > 1 ? selectedFiles : [];
            _singleFile =
                selectedFiles.length == 1 ? selectedFiles.first : null;
            _firebaseService.logUserActivity(
                'Picked ${selectedFiles.length} valid file(s)');
          } else {
            _firebaseService.logUserActivity('No valid files selected');
          }
        });

        // Print the file paths
        for (var file in selectedFiles) {
          print('Selected file path: ${file.path}');
        }

        // Upload files to Firebase Storage with user ID
        await _uploadFiles(selectedFiles, userId);
      }
    } else {
      // No files selected
      _firebaseService.logUserActivity('No files selected');
    }
  }

  Future<void> _uploadFiles(List<File> files, String userId) async {
    for (var file in files) {
      try {
        // Create a reference to the location you want to upload to
        String filePath =
            'Uploaded_Doc/$userId/${file.uri.pathSegments.last}'; // Include user ID in the path
        Reference storageRef = FirebaseStorage.instance.ref(filePath);

        // Upload the file
        UploadTask uploadTask = storageRef.putFile(file);
        TaskSnapshot snapshot = await uploadTask;

        // Check for errors
        if (snapshot.state == TaskState.success) {
          print('File uploaded successfully: ${file.path}');
          // Optionally, get the download URL
          String downloadUrl = await snapshot.ref.getDownloadURL();
          print('Download URL: $downloadUrl');
        } else {
          print('Upload failed for file: ${file.path}');
        }
      } catch (e) {
        print('Error uploading file: $e');
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error uploading file: $e',
              style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 40.0, left: 20.0, right: 20.0),
          ),
        );
      }
    }
  }

  bool _isLoading = false;

  Future<void> _uploadDocuments() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true; // Start loading
    });

    var baseUrl =
        'https://cb1c-2401-4900-1727-5bb4-30be-f52d-f525-b657.ngrok-free.app';
    var uri = Uri.parse(_files.isNotEmpty
        ? '$baseUrl/api/summarize_multiple'
        : '$baseUrl/api/summarize');

    List<Map<String, dynamic>> summarizeContent = [];
    List<Map<String, dynamic>> errors = [];

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    if (_textInput.isEmpty && (_files.isEmpty && _singleFile == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please pick a file or enter text',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior
              .floating, // Makes the snackbar float above the bottom
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjust margin as needed
        ),
      );
      setState(() {
        _isLoading = false; // Stop loading
      });
      return;
    }

    if (_textInput.isNotEmpty) {
      // Count the number of lines by splitting on newline characters
      List<String> lines = _textInput.split('.');
      print(lines.length);
      // Check if the input contains more than 5 lines
      if (lines.length < 10) {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please provide at least 10 lines of text.',
              style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor: themeProvider.isDarkMode
                ? Colors.black
                : Colors.white, // Updated message
            behavior: SnackBarBehavior
                .floating, // Makes the snackbar float above the bottom
            margin: EdgeInsets.only(
                bottom: 40.0,
                left: 20.0,
                right: 20.0), // Adjust margin as needed
          ),
        );
        setState(() {
          _isLoading = false; // Stop loading
        });
        return;
      }
      String userId = _auth.currentUser?.uid ?? '';
      // Proceed to upload the valid text input to Firestore
      _firestore.collection('user_inputs').add({
        'text': _textInput,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': userId,
      }).then((_) {
        // Clear the text input after successful upload
        _textEditingController.clear();
      }).catchError((error) {
        // Handle any errors
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload text: $error',
              style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.only(bottom: 40.0, left: 20.0, right: 20.0),
          ),
        );
      });
      // If you want to continue with the upload process after this check, you can proceed here
    }

    try {
      var request = http.MultipartRequest('POST', uri)
        ..fields['summaryLength'] = _summaryLength.toString()
        ..fields['detailLevel'] = _detailLevel.toString();

      if (_files.isNotEmpty) {
        for (var file in _files) {
          request.files
              .add(await http.MultipartFile.fromPath('documents', file.path));
        }
      } else if (_singleFile != null) {
        request.files.add(
            await http.MultipartFile.fromPath('document', _singleFile!.path));
      } else if (_textInput.isNotEmpty) {
        request.fields['text'] = _textInput;
      } else {
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please pick a file or enter text',
              style: TextStyle(
                  color:
                      themeProvider.isDarkMode ? Colors.white : Colors.black),
            ),
            backgroundColor:
                themeProvider.isDarkMode ? Colors.black : Colors.white,
            behavior: SnackBarBehavior
                .floating, // Makes the snackbar float above the bottom
            margin: EdgeInsets.only(
                bottom: 40.0,
                left: 20.0,
                right: 20.0), // Adjust margin as needed
          ),
        );
        setState(() {
          _isLoading = false; // Stop loading
        });
        return;
      }
      // Show loading dialog
      _showLoadingDialog(context);

      var response = await request.send();
      final responseData = await response.stream.bytesToString();
      print("Response status code: ${response.statusCode}");
      print("Response data: $responseData");

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);

        if (_files.isNotEmpty) {
          // Handling multiple documents response
          for (var summary in data['summaries']) {
            summarizeContent.add({
              'title': summary['title'] ?? 'No title available',
              'summary': summary['summary'] ?? 'No summary available',
              'mcq_questions': summary['mcq_questions'] ?? [],
              'brief_questions': summary['brief_questions'] ?? [],
            });
          }
        } else {
          // Handling single document response
          summarizeContent.add({
            'title': data['title'] ?? 'No title available',
            'summary': data['summary'] ?? 'No summary available',
            'mcq_questions': data['mcq_questions'] ?? [],
            'brief_questions': data['brief_questions'] ?? [],
          });
        }
        // Log user activity
        _firebaseService
            .logUserActivity('Uploaded documents for summarization');
      } else {
        errors.add({
          'error':
              'Failed to upload document with status code ${response.statusCode}'
        });
      }
    } catch (e) {
      errors.add({'error': 'Exception: $e'});
      // Log user activity
      _firebaseService
          .logUserActivity('Error occurred during document upload: $e');
    }

    if (errors.isNotEmpty) {
      print("Errors: $errors");
    }
    // Close loading dialog and reset loading state
    Navigator.of(context).pop();
    setState(() {
      _isLoading = false; // Stop loading
    });
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            SummarizeContent(summarizeContent: summarizeContent),
      ),
    );
  }

  // void _toggleTheme() {
  //   // Use ThemeProvider to toggle the theme
  //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  // }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(
                  child: Text(
                "Please wait...",
                style: TextStyle(fontSize: 16),
              )),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    String userId = _auth.currentUser?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Summarify',
          style: TextStyle(
              fontFamily: 'DancingScript', // Use the Dancing Script font
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.white : Colors.black),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu,
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      drawer: NavBar(),
      backgroundColor: themeProvider.isDarkMode
          ? Color.fromARGB(255, 25, 25, 25)
          : Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_files.isNotEmpty || _singleFile != null) ...[
                SizedBox(height: 10),
                Text(
                  'Selected Files:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 5),
                SizedBox(
                  height: 60, // Adjust the height as needed
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_files.isNotEmpty)
                        ..._files.map((file) {
                          String fileName = file.path.split('/').last;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                OpenFile.open(file.path);
                              },
                              child: Chip(
                                label: Text(
                                  fileName.length > 20
                                      ? fileName.substring(0, 20) + '...'
                                      : fileName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                deleteIcon: Icon(
                                  Icons.cancel,
                                  color: themeProvider.isDarkMode
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                onDeleted: () {
                                  setState(() {
                                    _files.remove(file);
                                    if (_files.isEmpty) _singleFile = null;
                                  });
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      if (_singleFile != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () {
                              OpenFile.open(_singleFile!.path);
                            },
                            child: Chip(
                              label: Text(
                                _singleFile!.path.split('/').last.length > 20
                                    ? _singleFile!.path
                                            .split('/')
                                            .last
                                            .substring(0, 20) +
                                        '...'
                                    : _singleFile!.path.split('/').last,
                                overflow: TextOverflow.ellipsis,
                              ),
                              deleteIcon: Icon(
                                Icons.cancel,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              onDeleted: () {
                                setState(() {
                                  _singleFile = null;
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
              ],
              SizedBox(height: 5),
              Container(
                padding: EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: themeProvider.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  border: Border.all(
                    color: themeProvider.isDarkMode
                        ? Colors.grey[600]!
                        : Colors.grey[400]!,
                    width: 1.0,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: _textEditingController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Enter text for summarization...',
                        hintStyle: TextStyle(
                            color: themeProvider.isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[600]),
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                        filled: true,
                        fillColor: themeProvider.isDarkMode
                            ? Colors.grey[800]
                            : Colors.grey[200],
                      ),
                      style: TextStyle(
                          color: themeProvider.isDarkMode
                              ? Colors.white
                              : Colors.black),
                      onChanged: (value) {
                        setState(() {
                          _textInput = value;
                        });
                      },
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: _textEditingController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: themeProvider.isDarkMode
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _textEditingController.clear();
                                });
                              },
                            )
                          : SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Summary Length',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor:
                      themeProvider.isDarkMode ? Colors.white : Colors.blue,
                  inactiveTrackColor: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  thumbColor: Colors.blue,
                  overlayColor: Colors.blue.withOpacity(0.2),
                  valueIndicatorColor: Colors.blue,
                  valueIndicatorTextStyle: TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: _summaryLength,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  label: _summaryLength.toString(),
                  onChanged: (value) {
                    setState(() {
                      _summaryLength = value;
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Detail Level',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.black),
              ),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor:
                      themeProvider.isDarkMode ? Colors.white : Colors.blue,
                  inactiveTrackColor: themeProvider.isDarkMode
                      ? Colors.grey[700]
                      : Colors.grey[300],
                  thumbColor: Colors.blue,
                  overlayColor: Colors.blue.withOpacity(0.2),
                  valueIndicatorColor: Colors.blue,
                  valueIndicatorTextStyle: TextStyle(color: Colors.white),
                ),
                child: Slider(
                  value: _detailLevel.toDouble(),
                  min: 0,
                  max: 5,
                  divisions: 5,
                  label: _detailLevel.toString(),
                  onChanged: (value) {
                    setState(() {
                      _detailLevel = value.toInt();
                    });
                  },
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: SizedBox(
                        height: 50,
                        child: CustomButton(
                          text: 'Pick Documents',
                          onPressed: () => _pickFiles(userId),
                          isOutlined: false,
                          isGradient: false,
                          isCircular: true,
                          color: themeProvider.isDarkMode
                              ? Colors.black
                              : Colors.white,
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.grey[800]!
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: SizedBox(
                        height: 50,
                        child: CustomButton(
                          text: 'Summarize', // Show empty text when loading
                          onPressed:
                              _uploadDocuments, // Disable the button when loading
                          isOutlined: false,
                          isGradient: false,
                          isCircular:
                              true, // Show loading when _isLoading is true
                          color: themeProvider.isDarkMode
                              ? Colors.black
                              : Colors.white,
                          backgroundColor: themeProvider.isDarkMode
                              ? Colors.grey[800]!
                              : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textEditingController.dispose(); // Dispose of the controller
    super.dispose();
  }
}

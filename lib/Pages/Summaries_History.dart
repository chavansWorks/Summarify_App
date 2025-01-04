import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summarify/API/firebase_service.dart';
import 'ReviewSummaries.dart'; // Import the DetailPage
import '../Utilities/theme_provider.dart'; // Import your ThemeProvider
import 'package:intl/intl.dart'; // Import intl package for date formatting
import 'package:lottie/lottie.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _historyFuture;
  List<Map<String, dynamic>> _allResults = [];
  List<Map<String, dynamic>> _filteredResults = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _historyFuture = _firebaseService.getHistory();
    _historyFuture.then((history) {
      setState(() {
        _allResults = history;
        _filteredResults = history; // Initialize with all results
      });
    });
  }

  void _search() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final results = await _firebaseService.searchHistory(query);
      setState(() {
        _filteredResults = results;
      });
    } else {
      // If the search query is empty, show all results
      _historyFuture.then((history) {
        setState(() {
          _filteredResults = history;
        });
      });
    }
  }

  void _deleteResult(String documentId) async {
    if (documentId.isEmpty) {
      print('Invalid document ID');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid document ID.',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating, // Makes the snackbar float
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjusts position
        ),
      );

      return;
    }

    try {
      await _firebaseService.deleteResult(documentId);
      setState(() {
        _filteredResults
            .removeWhere((result) => result['documentId'] == documentId);
      });
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Summary deleted successfully',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior: SnackBarBehavior.floating, // Makes the snackbar float
          margin: EdgeInsets.only(
              bottom: 50.0, left: 20.0, right: 20.0), // Adjusts position
        ),
      );
    } catch (e) {
      print('Error deleting result: $e');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete the result. Please try again.',
            style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black),
          ),
          backgroundColor:
              themeProvider.isDarkMode ? Colors.black : Colors.white,
          behavior:
              SnackBarBehavior.floating, // Makes it float above the bottom
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjusts position
        ),
      );
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference <= 7) {
      return DateFormat('EEEE').format(date); // Day of the week
    } else {
      return DateFormat('MMMM d, yyyy').format(date); // Full date
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

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

          Column(
            children: [
              SizedBox(
                height: 60,
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    _search();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25.0),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                    suffixIcon: IconButton(
                      icon: Icon(Icons.search,
                          color:
                              isDarkMode ? Colors.white70 : Colors.grey[600]),
                      onPressed: () {
                        _search();
                      },
                    ),
                  ),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _historyFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      print('Error fetching history: ${snapshot.error}');
                      return Center(child: Text('Error fetching history'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Lottie Animation
                            Lottie.asset(
                              'assets/Animation.json', // Add your Lottie animation file here
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                            // Space between animation and text
                            SizedBox(
                                height:
                                    10), // Reduce height for a more compact look
                            // "No history available" Text
                            Text(
                              'No history available',
                              style: TextStyle(
                                fontSize: 18.0,
                                color: Colors.white,
                              ),
                            ),
                            // Extra space at the bottom if needed
                            SizedBox(
                                height:
                                    100), // Increase or decrease height as needed
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: _filteredResults.length,
                      itemBuilder: (context, index) {
                        final result = _filteredResults[index];
                        final documentId =
                            result['documentId']; // Retrieve document ID
                        final timestamp =
                            result['timestamp'] as Timestamp; // Get timestamp

                        return Card(
                          margin: EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          elevation: 5.0,
                          color: isDarkMode ? Colors.grey[800] : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                          ),
                          child: Container(
                            height: 120.0, // Fixed height for the card
                            child: Stack(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.all(16.0),
                                  title: Text(
                                    '${result['title'] ?? 'No title available'}', // Provide a default value if title is null
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15.0,
                                      color: isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                    maxLines:
                                        2, // Limit the text to a single line
                                    overflow: TextOverflow
                                        .ellipsis, // Show "..." when text overflows
                                  ),
                                  subtitle: Text(
                                    '    ${result['summary'].toString()}',
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[700],
                                      fontSize: 14.0,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    "",
                                    style: TextStyle(
                                      color: isDarkMode
                                          ? Colors.white70
                                          : Colors.grey[600],
                                      fontSize: 12.0,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            DetailPage(result: result),
                                      ),
                                    );
                                  },
                                ),
                                Positioned(
                                  top: 30.0,
                                  right: 8.0,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 40.0,
                                        height: 40.0,
                                        decoration: BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.delete,
                                              color: Colors.white),
                                          onPressed: () {
                                            _deleteResult(documentId);
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                          height:
                                              20.0), // Space between icon and date
                                      Text(
                                        _formatTimestamp(timestamp),
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white70
                                              : Colors.grey[600],
                                          fontSize: 12.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

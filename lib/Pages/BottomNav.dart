import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:summarify/Pages/HomeScreen.dart';
import 'package:summarify/Pages/Summaries_History.dart';
import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    SummaryPage(),
    HistoryPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: themeProvider.isDarkMode
            ? Color.fromARGB(255, 25, 25, 25) // Dark mode background
            : Colors.blue[800]!, // Light mode background
        color: themeProvider.isDarkMode
            ? Colors.grey[850]! // Dark mode button color
            : Colors.white, // Light mode button color
        buttonBackgroundColor: themeProvider.isDarkMode
            ? Colors.grey[850]! // Dark mode button background color
            : Colors.white, // Light mode button background color
        height: 60.0,
        index: _selectedIndex,
        items: <Widget>[
          _buildIcon(Icons.home, _selectedIndex == 0, themeProvider.isDarkMode),
          _buildIcon(
              Icons.history, _selectedIndex == 1, themeProvider.isDarkMode),
        ],
        onTap: _onItemTapped,
        animationDuration: Duration(milliseconds: 300),
        animationCurve: Curves.easeInOut,
      ),
    );
  }

  Widget _buildIcon(IconData icon, bool isSelected, bool isDarkMode) {
    return Container(
      padding: EdgeInsets.all(8.0), // Adjust padding as needed
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? (isDarkMode
                ? Colors.blue[600]
                : Colors.blue[100]) // Selected icon background color
            : Colors.transparent, // Unselected icon background color
        border: Border.all(
          color: isSelected
              ? (isDarkMode
                  ? Colors.blue[300]!
                  : Colors.blue[800]!) // Selected icon border color
              : Colors.transparent, // Unselected icon border color
          width: 2.0, // Outline width
        ),
      ),
      child: Icon(
        icon,
        size: 25,
        color: isSelected
            ? (isDarkMode
                ? Colors.white
                : Colors.blue[800]) // Selected icon color
            : (isDarkMode
                ? Colors.grey[400]
                : Colors.grey), // Unselected icon color
      ),
    );
  }
}

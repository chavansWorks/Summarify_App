import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:summarify/Pages/Aboutus.dart';
import 'package:summarify/Pages/Feedback.dart';
import 'package:summarify/Pages/ProfilePage.dart';
import 'package:summarify/Pages/SignIn.dart';
import 'package:summarify/Utilities/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:summarify/API/firebase_service.dart';

class NavBar extends StatefulWidget {
  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;
  late Future<Map<String, dynamic>> _userProfile;

  @override
  void initState() {
    super.initState();
    _userProfile = getUserProfile();
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      String userId = FirebaseAuth.instance.currentUser?.uid ?? 'guest_user';
      DocumentSnapshot documentSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        return documentSnapshot.data() as Map<String, dynamic>? ?? {};
      } else {
        return {};
      }
    } catch (e) {
      throw e;
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseService().signOut(context);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    } catch (e) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oops! We encountered an error while signing you out. Please try again.',
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

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: FutureBuilder<Map<String, dynamic>>(
        future: _userProfile,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          var userProfile = snapshot.data ?? {};
          String profileImageUrl = userProfile['profileImageUrl'] ??
              'https://cdn-icons-png.flaticon.com/512/149/149071.png';

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text(userProfile['fullName'] ?? 'No Name'),
                accountEmail: Text(userProfile['email'] ?? 'No Email'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.grey,
                  backgroundImage: NetworkImage(profileImageUrl),
                  child: profileImageUrl.isEmpty
                      ? Icon(Icons.person, size: 50.0, color: Colors.white)
                      : null,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  image: DecorationImage(
                    fit: BoxFit.fill,
                    image: NetworkImage(
                        'https://wallpapers.com/images/hd/profile-background-4yoef4rdwnf1ynie.jpg'),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.account_circle_rounded),
                title: Text('Profile'),
                onTap: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => ProfilePage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => AboutUsPage()),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                onTap: () => null,
              ),
              ListTile(
                  leading: Icon(Icons.feedback),
                  title: Text('Feedback'),
                  onTap: () => {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return FeedbackPopup();
                          },
                        )
                      }),
              Divider(),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () => null,
              ),
              ListTile(
                leading: Icon(Icons.description),
                title: Text('Theme'),
                trailing: IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Provider.of<ThemeProvider>(context).isDarkMode
                        ? Icon(
                            Icons.nightlight_round,
                            key: ValueKey('dark'),
                            color: Colors
                                .yellow[700], // Custom color for dark mode
                            size: 28,
                          )
                        : Icon(
                            Icons.wb_sunny,
                            key: ValueKey('light'),
                            color: Colors
                                .orange[700], // Custom color for light mode
                            size: 28,
                          ),
                  ),
                  onPressed: () {
                    Provider.of<ThemeProvider>(context, listen: false)
                        .toggleTheme();
                  },
                ),
              ),
              Divider(),
              ListTile(
                title: Text('LogOut'),
                leading: Icon(Icons.exit_to_app),
                onTap: _signOut,
              ),
            ],
          );
        },
      ),
    );
  }
}

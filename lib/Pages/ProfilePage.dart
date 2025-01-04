import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:summarify/Pages/BottomNav.dart';
import 'dart:io';
import 'package:summarify/Utilities/theme_provider.dart';
import 'package:summarify/API/firebase_service.dart';

import 'package:flutter/services.dart'; 

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _status = true; // Tracks if the profile is in edit mode

  final FirebaseService _firebaseService = FirebaseService();
  late Future<List<Map<String, dynamic>>> _logUserActivity;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileNumberController;
  String? _emailError;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController();
    _emailController = TextEditingController();
    _mobileNumberController = TextEditingController();
    _loadUserProfile();

    _firebaseService.logUserActivity('User entered Profile Screen');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      DocumentSnapshot documentSnapshot =
          await _firestore.collection('users').doc(userId).get();

      if (documentSnapshot.exists) {
        var userProfile = documentSnapshot.data() as Map<String, dynamic>;
        _fullNameController.text = userProfile['fullName'] ?? '';
        _emailController.text = userProfile['email'] ?? '';
        _mobileNumberController.text = userProfile['mobileNumber'] ?? '';
        _profileImageUrl = userProfile['profileImageUrl'];
        setState(() {});
      }
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _updateProfile() async {
    String fullName = _fullNameController.text;
    String email = _emailController.text;
    String mobileNumber = _mobileNumberController.text;

    if (!_isValidEmail(email)) {
      setState(() {
        _emailError = 'Email must end with @gmail.com';
      });
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Email must end with @gmail.com',
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
      return;
    } else {
      setState(() {
        _emailError = null;
      });
    }

    try {
      String userId = _auth.currentUser?.uid ?? '';

      DocumentReference userDocRef = _firestore.collection('users').doc(userId);
      DocumentSnapshot userDoc = await userDocRef.get();

      if (userDoc.exists) {
        // Update existing user data
        await userDocRef.update({
          'fullName': fullName,
          'email': email,
          'mobileNumber': mobileNumber,
          'profileImageUrl': _profileImageUrl,
        });

        // Update Firebase Auth email if changed
        User? user = _auth.currentUser;
        if (user != null && user.email != email) {
          await user.updateEmail(email);
        }

        _firebaseService.logUserActivity('Profile Details Edited Successfully');
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile updated successfully',
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
      } else {
        // Insert new user data
        await userDocRef.set({
          'fullName': fullName,
          'email': email,
          'mobileNumber': mobileNumber,
          'profileImageUrl': _profileImageUrl,
        });

        _firebaseService.logUserActivity('New User Profile Created');
        final themeProvider =
            Provider.of<ThemeProvider>(context, listen: false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Profile created successfully',
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
      }

      await _loadUserProfile();

      setState(() {
        _status = true;
        FocusScope.of(context).unfocus();
      });
    } catch (e) {
      _firebaseService.logUserActivity('User Tried to Edit Profile Details');
      print('Error updating profile: $e');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Something went wrong while updating your profile. Please try again.',
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
    }
  }

  // void _toggleTheme() {
  //   // Use ThemeProvider to toggle the theme
  //   Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
  // }

  bool _isValidEmail(String email) {
    return email.endsWith('@gmail.com');
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      File imageFile = File(pickedFile.path);
      await _uploadImage(imageFile);
    }
  }

  Future<void> _uploadImage(File imageFile) async {
    try {
      String userId = _auth.currentUser?.uid ?? '';
      String fileName = '${userId}_profile_image.jpg';
      Reference ref = _storage.ref().child('profile_images').child(fileName);

      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot taskSnapshot = await uploadTask;
      String downloadUrl = await taskSnapshot.ref.getDownloadURL();

      setState(() {
        _profileImageUrl = downloadUrl;
      });

      // Update profile image URL in Firestore
      await _firestore.collection('users').doc(userId).update({
        'profileImageUrl': downloadUrl,
      });
      _firebaseService.logUserActivity('Profile photo updated');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile image uploaded successfully',
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
    } catch (e) {
      _firebaseService.logUserActivity('User Trying to updated Profile photo');
      print('Error uploading image: $e');
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Oops! Something went wrong while uploading the image. Please try again',
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
    }
  }

  Widget _getActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 25.0, vertical: 45.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          ElevatedButton(
            onPressed: () {
              setState(() {
                _status = true;
                FocusScope.of(context).unfocus();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800], // Save button color
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.blue, width: 2),
              minimumSize: Size(120, 50),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(fontSize: 18),
            ),
          ),
          ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[800], // Save button color
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.blue, width: 2),
              minimumSize: Size(120, 50),
            ),
            child: Text(
              'Save',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getEditIcon() {
    return GestureDetector(
      child: CircleAvatar(
        backgroundColor: Colors.blue,
        radius: 20.0,
        child: Icon(
          Icons.edit,
          color: Colors.white,
          size: 21.0,
        ),
      ),
      onTap: () {
        setState(() {
          _status = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
            size: 22.0,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainPage()),
            );
          },
        ),
      ),
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      body: Container(
        color: themeProvider.isDarkMode ? Colors.black : Colors.white,
        child: ListView(
          children: <Widget>[
            Column(
              children: <Widget>[
                Container(
                  height: 250.0,
                  color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                  child: Column(
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: Stack(
                          fit: StackFit.loose,
                          children: <Widget>[
                            Center(
                              child: _profileImageUrl == null
                                  ? Container(
                                      width: 140.0,
                                      height: 140.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[300],
                                      ),
                                      child: Icon(
                                        Icons.person,
                                        size: 60.0,
                                        color: Colors.grey,
                                      ),
                                    )
                                  : Container(
                                      width: 140.0,
                                      height: 140.0,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        image: DecorationImage(
                                          image:
                                              NetworkImage(_profileImageUrl!),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                            ),
                            Positioned(
                              top: 90.0,
                              right: 100.0,
                              child: CircleAvatar(
                                backgroundColor: Colors.blue,
                                radius: 25.0,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding:
                            EdgeInsets.only(left: 25.0, right: 25.0, top: 25.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                    color: themeProvider.isDarkMode
                                        ? Colors.white
                                        : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 5.0),
                                Container(
                                  color: Colors.red,
                                  height: 1.0,
                                  width: 100.0,
                                ),
                              ],
                            ),
                            if (_status) _getEditIcon(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 25.0, vertical: 15.0),
                        child: TextField(
                          controller: _fullNameController,
                          decoration: InputDecoration(
                            labelText: 'Full Name',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_status,
                        ),
                      ),
                      SizedBox(height: 15.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            errorText: _emailError,
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_status,
                        ),
                      ),
                      SizedBox(height: 15.0),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 25.0),
                        child: TextField(
                          controller: _mobileNumberController,
                          decoration: InputDecoration(
                            labelText: 'Mobile Number',
                            border: OutlineInputBorder(),
                          ),
                          enabled: !_status,
                          inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly, // Only allow digits
        LengthLimitingTextInputFormatter(10), // Limit to 10 digits
      ],
                        ),
                      ),
                      SizedBox(height: 30.0),
                      if (!_status) _getActionButtons(),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

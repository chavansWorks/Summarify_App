import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:summarify/Pages/BottomNav.dart';
import 'package:summarify/Pages/SignIn.dart';
import 'package:summarify/Pages/HomeScreen.dart';
import 'package:summarify/Utilities/constant.dart';

class PhoneNumberScreen extends StatefulWidget {
  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _phoneController = TextEditingController();
  String completePhoneNumber = '';

  Widget _buildOTPBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => {_verifyPhoneNumber(context)},
        style: ElevatedButton.styleFrom(
          elevation: 5.0,
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          'Get OTP',
          style: TextStyle(
            color: Color(0xFF527DAA),
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Text("Sign in with mobile number",
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              )),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 22.0,
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => SignInScreen()),
            );
          },
        ),
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 120),
                  Icon(Icons.phone_android, size: 100, color: Colors.white),
                  SizedBox(height: 24.0),
                  Text(
                    'Enter your phone number',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'We will send an SMS with a verification code to this number.',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.0),
                  Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Transparent background
                      border: Border.all(
                          color: Colors.white, width: 1.5), // White outline
                      borderRadius:
                          BorderRadius.circular(10.0), // Rounded corners
                    ),
                    height: 60.0, // Match the height of your TextField
                    child: IntlPhoneField(
                      initialCountryCode:
                          'IN', // Set default country code to +91
                      decoration: InputDecoration(
                        border: InputBorder.none, // Remove default border
                        contentPadding: EdgeInsets.only(top: 14.0),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Colors.white,
                        ),
                        hintText: 'Enter your Mobile Number',
                        hintStyle:
                            kHintTextStyle, // Use your custom hint text style
                      ),
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                      onChanged: (phone) {
                        setState(() {
                          completePhoneNumber = phone
                              .completeNumber; // Store the complete phone number
                        });
                      },
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  _buildOTPBtn(),
                  SizedBox(
                    height: 160,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPhoneNumber(BuildContext context) async {
    if (completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid phone number'),
          behavior: SnackBarBehavior
              .floating, // Makes the snackbar float above the bottom
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjust margin as needed
        ),
      );
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber:
            completePhoneNumber, // Use the formatted number with country code
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Verification failed. Please check your information and try again.'),
              behavior: SnackBarBehavior
                  .floating, // Makes the snackbar float above the bottom
              margin: EdgeInsets.only(
                  bottom: 40.0,
                  left: 20.0,
                  right: 20.0), // Adjust margin as needed
            ),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Verification failed: ${e.message}')),
          );
        },
        codeSent: (String verificationId, int? resendToken) async {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (context) => SmsCodeScreen(
                      verificationId: verificationId,
                    )), // Replace with your home screen
          ); // Navigate to the SMS code entry screen
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
        timeout: Duration(seconds: 60),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Failed to verify your phone number. Please try again.'),
          behavior: SnackBarBehavior.floating, // Makes the snackbar float
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjusts position
        ),
      );
    }
  }
}

class SmsCodeScreen extends StatefulWidget {
  final String verificationId;

  SmsCodeScreen({required this.verificationId});

  @override
  _SmsCodeScreenState createState() => _SmsCodeScreenState();
}

class _SmsCodeScreenState extends State<SmsCodeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _smsController = TextEditingController();

  Widget _buildVerifyBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => {_signInWithSmsCode()},
        style: ElevatedButton.styleFrom(
          elevation: 5.0,
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          'Verify',
          style: TextStyle(
            color: Color(0xFF527DAA),
            letterSpacing: 1.5,
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            fontFamily: 'OpenSans',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.sms, size: 100, color: Colors.white),
                  SizedBox(height: 24.0),
                  Text(
                    'Enter the verification code',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    'We have sent an SMS with a code to your phone.',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24.0),
                  Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Colors.transparent, // Transparent background
                      border: Border.all(
                          color: Colors.white, width: 1.5), // White outline
                      borderRadius: BorderRadius.circular(
                          10.0), // Optional: rounded corners
                    ),
                    height: 60.0,
                    child: TextField(
                      controller: _smsController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                      ),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(top: 14.0),
                        prefixIcon: Icon(
                          Icons.lock,
                          color: Colors.white,
                        ),
                        hintStyle: kHintTextStyle,
                      ),
                    ),
                  ),
                  SizedBox(height: 24.0),
                  _buildVerifyBtn(),
                  SizedBox(
                    height: 25,
                  ),
                  TextButton(
                      onPressed: () => {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      PhoneNumberScreen()), // Replace with your home screen
                            )
                          },
                      child: Text(
                        "Change Mobile number",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ))
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithSmsCode() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _smsController.text.trim(),
      );
      await _auth.signInWithCredential(credential);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (context) => MainPage()), // Replace with your home screen
      );
    } catch (e) {
      print('Error signing in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid code or error signing in.'),
          behavior: SnackBarBehavior
              .floating, // Makes the snackbar float above the bottom
          margin: EdgeInsets.only(
              bottom: 40.0, left: 20.0, right: 20.0), // Adjust margin as needed
        ),
      );
    }
  }
}

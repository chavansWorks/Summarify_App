import 'package:summarify/Utilities/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:summarify/Utilities/theme_provider.dart'; // Import ThemeProvider
import 'package:provider/provider.dart';
import 'package:summarify/Pages/SignIn.dart';

class SignupScreen extends StatefulWidget {
  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _agreeToTerms = false;
  bool _showPassword = false;
  bool _CshowPassword = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _fullNameController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  Future<void> signUp() async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: _emailTextController.text,
        password: _passwordTextController.text,
      );
      print("Signed up: ${userCredential.user?.email}");

      // Save user information to Firestore
      await _firestore.collection('users').doc(userCredential.user?.uid).set({
        'fullName': _fullNameController.text,
        'email': _emailTextController.text,
      });

      // Optionally update the user's profile with the full name
      await userCredential.user
          ?.updateProfile(displayName: _fullNameController.text);

      // Log sign-up activity
      await logUserActivity('Signed up');
    } on FirebaseAuthException catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Something went wrong please try again!')),
      );
    }
  }

  Future<void> logUserActivity(String activity) async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('user_activities').add({
        'user_id': user?.uid ?? 'guest', // Use 'guest' if no user is signed in
        'activity': activity,
        'timestamp': FieldValue.serverTimestamp(),
      });
      print("User activity logged: $activity");
    } catch (e) {
      print("Error logging user activity: $e");
    }
  }

  Widget _buildNameTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Name',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background
            border:
                Border.all(color: Colors.white, width: 1.5), // White outline
            borderRadius:
                BorderRadius.circular(10.0), // Optional: rounded corners
          ),
          height: 60.0,
          child: TextField(
            controller: _fullNameController,
            keyboardType: TextInputType.name,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.person,
                color: Colors.white,
              ),
              hintText: 'Enter your Name',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Email',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background
            border:
                Border.all(color: Colors.white, width: 1.5), // White outline
            borderRadius:
                BorderRadius.circular(10.0), // Optional: rounded corners
          ),
          height: 60.0,
          child: TextField(
            controller: _emailTextController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              color: Colors.white,
              fontFamily: 'OpenSans',
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.only(top: 14.0),
              prefixIcon: Icon(
                Icons.email,
                color: Colors.white,
              ),
              hintText: 'Enter your Email',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Password',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background
            border:
                Border.all(color: Colors.white, width: 1.5), // White outline
            borderRadius:
                BorderRadius.circular(10.0), // Optional: rounded corners
          ),
          height: 60.0,
          child: TextField(
            controller: _passwordTextController,
            obscureText: !_showPassword,
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
              suffixIcon: IconButton(
                icon: Icon(
                  _showPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _showPassword = !_showPassword;
                  });
                },
              ),
              hintText: 'Enter your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordTF() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Confirm Password',
          style: kLabelStyle,
        ),
        SizedBox(height: 10.0),
        Container(
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: Colors.transparent, // Transparent background
            border:
                Border.all(color: Colors.white, width: 1.5), // White outline
            borderRadius:
                BorderRadius.circular(10.0), // Optional: rounded corners
          ),
          height: 60.0,
          child: TextField(
            controller: _confirmPasswordController,
            obscureText: !_CshowPassword,
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
              suffixIcon: IconButton(
                icon: Icon(
                  _CshowPassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    _CshowPassword = !_CshowPassword;
                  });
                },
              ),
              hintText: 'Confirm your Password',
              hintStyle: kHintTextStyle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreeToTermsCheckbox() {
    return Row(
      children: <Widget>[
        Theme(
          data: ThemeData(unselectedWidgetColor: Colors.white),
          child: Checkbox(
            value: _agreeToTerms,
            checkColor: Colors.green,
            activeColor: Colors.white,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value!;
              });
            },
          ),
        ),
        Expanded(
          child: Text(
            'I agree to the Terms and Conditions',
            style: kLabelStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupBtn() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 25.0),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => {
          if (_fullNameController.text == '')
            {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please enter your name')),
              )
            }
          else
            {
              if (_emailTextController.text == '')
                {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide your email')),
                  )
                }
              else
                {
                  if (_passwordTextController.text == '')
                    {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Please provide password')),
                      )
                    }
                  else
                    {
                      if (_confirmPasswordController.text == '')
                        {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text('Please confirm the password')),
                          )
                        }
                      else
                        {
                          if (_passwordTextController.text !=
                              _confirmPasswordController.text)
                            {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Passwords do not match')),
                              )
                            }
                          else
                            {
                              if (_agreeToTerms == true)
                                {
                                  signUp(),
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                        builder: (context) => SignInScreen()),
                                  )
                                }
                              else
                                {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Please Accept the Terms and Cnditions')),
                                  )
                                }
                            }
                        }
                    }
                }
            }
        },
        style: ElevatedButton.styleFrom(
          elevation: 5.0,
          backgroundColor: Colors.white,
          padding: EdgeInsets.all(15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
        ),
        child: Text(
          'SIGN UP',
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

  Widget _buildLoginBtn() {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SignInScreen(),
        ),
      ),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: 'Already have an Account? ',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.w400,
              ),
            ),
            TextSpan(
              text: 'Sign in',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: <Widget>[
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
              SingleChildScrollView(
                padding:
                    EdgeInsets.symmetric(horizontal: 40.0, vertical: 120.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Sign up',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily:
                            'DancingScript', // Use the Dancing Script font
                        fontSize: 35.0,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30.0),
                    _buildNameTF(),
                    SizedBox(height: 10.0),
                    _buildEmailTF(),
                    SizedBox(height: 10.0),
                    _buildPasswordTF(),
                    SizedBox(height: 10.0),
                    _buildConfirmPasswordTF(),
                    SizedBox(height: 20.0),
                    _buildAgreeToTermsCheckbox(),
                    _buildSignupBtn(),
                    Center(child: _buildLoginBtn()),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

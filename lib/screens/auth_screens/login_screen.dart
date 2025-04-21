import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/auth_screens/forgot_pass_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'registration_screen.dart';
import '../payment_details_screen.dart'; // Import the PaymentPage
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if email is verified
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await _auth.signOut();
        Fluttertoast.showToast(
            msg: "Please verify your email before logging in.",
            toastLength: Toast.LENGTH_LONG);
        setState(() {
          _isLoading = false;
        });
        return;
      }

      Fluttertoast.showToast(msg: 'Login Successful!');

      // Navigate to PaymentScreen after successful login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PaymentDetailsScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(
          msg: 'Error: ${e.toString().split(']').last.trim()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();

      // Force the account picker by signing out first
      await googleSignIn.signOut(); // 👈 This is key

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        Fluttertoast.showToast(msg: 'Google Sign-In Successful!');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PaymentDetailsScreen()),
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Google Sign-In Error: ${e.toString().split(']').last.trim()}',
        toastLength: Toast.LENGTH_LONG,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0CA8E1),
      body: SafeArea(
        child: Stack(
          children: [
            // Sign-in label in top right
            Positioned(
              top: 20,
              right: 30,
              child: Text(
                'Sign-in',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),

            // Main content
            Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo
                      Image.asset(
                        'assets/logo-light.png',
                        height: 150,
                      ),
                      SizedBox(height: 40),

                      // Email field
                      _buildInputField('E-mail', _emailController),
                      SizedBox(height: 15),

                      // Password field
                      _buildInputField('Password', _passwordController,
                          isPassword: true),

                      // Forgot password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => ForgotPasswordScreen()),
                            );
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 20),

                      // Login button
                      _buildButton(
                        text: 'Login',
                        onPressed: _isLoading ? null : _login,
                        isLoading: _isLoading,
                      ),

                      SizedBox(height: 15),

                      // Google login button
                      _buildGoogleButton(),
                      SizedBox(height: 40), // optional space

                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => RegisterScreen()),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(
                          height:
                              20), 
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(String label, TextEditingController controller,
      {bool isPassword = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 5),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(50),
          ),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              hintText: isPassword ? 'password' : 'example@gmail.com',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildButton(
      {required String text,
      required VoidCallback? onPressed,
      bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF0CA8E1),
                ),
              )
            : Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0CA8E1),
                ),
              ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      child: ElevatedButton(
        onPressed: _signInWithGoogle,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Google logo
            Image.asset(
              'assets/google-logo.png',
              height: 24,
              width: 24,
            ),
            SizedBox(width: 10),
            Text(
              'Sign in with Google',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import '../../services/user_service.dart';
import '../../services/user_sync_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool loading = false;
  bool otpSent = false;

  // Send OTP to the user's email
  Future<void> _sendOTP() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final name = _nameController.text.trim();

    // Basic validation
    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(msg: "Please fill all fields");
      return;
    }

    if (password != confirmPassword) {
      Fluttertoast.showToast(msg: "Passwords do not match.");
      return;
    }

    setState(() => loading = true);

    try {
      // Check if email already exists
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        Fluttertoast.showToast(
            msg: "Email already in use. Please login instead.");
        setState(() => loading = false);
        return;
      }

      // Create user with email and password but don't sign in yet
      final userCredential = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);

      // Update user profile with name
      await userCredential.user!.updateDisplayName(name);

      // Send email verification
      await userCredential.user!.sendEmailVerification();

      // Save user data to UserService
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        final userModel = UserModel.fromFirebaseUser(userCredential.user!);
        await userService.setCurrentUser(userModel);
      } catch (e) {
        print('Error saving user data: $e');
      }

      // Try to create user in PostgreSQL database
      try {
        await UserSyncService().syncUserWithDatabase();
      } catch (e) {
        print('Error syncing user with database: $e');
        // Continue anyway, we'll try again on login
      }

      // Sign out immediately - user will need to verify email before logging in
      await _auth.signOut();

      setState(() {
        otpSent = true;
        loading = false;
      });

      Fluttertoast.showToast(
          msg:
              "Verification email sent! Please check your inbox and verify your email.",
          toastLength: Toast.LENGTH_LONG);
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
          msg: e.message ?? "Failed to send verification email");
      setState(() => loading = false);
    }
  }

  // Verify OTP and complete registration
  Future<void> _verifyEmailAndRegister() async {
    setState(() => loading = true);

    try {
      // Sign in with email and password
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Try to sign in
      final userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // Check if email is verified
      await userCredential.user!.reload();
      final user = _auth.currentUser;

      if (user != null && user.emailVerified) {
        // Email is verified, update user profile with name
        await user.updateDisplayName(_nameController.text.trim());

        // Save user data to UserService
        try {
          final userService = Provider.of<UserService>(context, listen: false);
          final userModel = UserModel.fromFirebaseUser(user);
          await userService.setCurrentUser(userModel);
        } catch (e) {
          print('Error saving user data: $e');
        }

        // Try to create user in PostgreSQL database
        try {
          await UserSyncService().syncUserWithDatabase();
        } catch (e) {
          print('Error syncing user with database: $e');
          // Continue anyway, we'll try again on login
        }

        Fluttertoast.showToast(msg: "Registration Successful!");

        // Navigate to login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        // Email not verified yet
        await _auth.signOut();
        Fluttertoast.showToast(
            msg: "Please verify your email before logging in.",
            toastLength: Toast.LENGTH_LONG);
      }
    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(msg: e.message ?? "Verification failed");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0CA8E1),
      body: SafeArea(
        child: Stack(
          children: [
            // Sign-up label in top right
            Positioned(
              top: 20,
              right: 30,
              child: Text(
                'Sign-up',
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

                      if (!otpSent) ...[
                        // Name field
                        _buildInputField('Name', _nameController),
                        SizedBox(height: 15),

                        // Email field
                        _buildInputField('E-mail', _emailController),
                        SizedBox(height: 15),

                        // Password field
                        _buildInputField('Password', _passwordController,
                            isPassword: true),
                        SizedBox(height: 15),

                        // Confirm Password field
                        _buildInputField(
                            'Confirm Password', _confirmPasswordController,
                            isPassword: true),

                        SizedBox(height: 30),

                        // Register button
                        _buildButton(
                          text: 'Register',
                          onPressed: loading ? null : _sendOTP,
                          isLoading: loading,
                        ),
                      ] else ...[
                        // Email verification UI
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 50, color: Colors.white),
                              SizedBox(height: 15),
                              Text(
                                'Verify Your Email',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'We\'ve sent a verification link to your email. Please check your inbox and click the link to verify your account.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 20),

                              // Verify button
                              _buildButton(
                                text: 'I\'ve Verified My Email',
                                onPressed:
                                    loading ? null : _verifyEmailAndRegister,
                                isLoading: loading,
                              ),

                              SizedBox(height: 15),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    otpSent = false;
                                  });
                                },
                                child: Text(
                                  'Go Back',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Added extra space at the bottom to ensure content doesn't overlap with the bottom text
                      SizedBox(height: 80),
                      // Already have an account - placed inline like other elements
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already have an account?",
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
                                    builder: (context) => LoginPage()),
                              );
                            },
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
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
              hintText: isPassword
                  ? 'password'
                  : label == 'Name'
                      ? 'your name'
                      : 'example@gmail.com',
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
}

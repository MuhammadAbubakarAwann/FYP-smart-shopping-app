// At the top of the file, ensure Provider is properly imported
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/auth_screens/forgot_pass_screen.dart';
import 'package:flutter_application_1/screens/shopping_list_welcome_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart'; // Make sure this import is present
import '../../services/user_service.dart';
import '../../services/user_sync_service.dart';
import '../../services/payment_service.dart';
import 'registration_screen.dart';
import '../payment_details_screen.dart';
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

// Inside the _navigateAfterLogin method in LoginPage class
Future<void> _navigateAfterLogin(User user) async {
  try {
    // First, synchronize the Firebase user with PostgreSQL database
    final syncResult = await UserSyncService().syncUserWithDatabase();
    print('Sync result: $syncResult'); // Debug log to see what's coming back

    if (syncResult['success']) {
      // Make sure we're getting the userId as an integer
      int? userId;
      if (syncResult['userId'] != null) {
        // Convert to int if it's not already
        userId = syncResult['userId'] is int 
            ? syncResult['userId'] 
            : int.tryParse(syncResult['userId'].toString());
            
        print('Extracted userId from sync: $userId'); // Debug log
      }
      
      if (userId == null) {
        print('Warning: userId is null from sync result'); // Debug log
        Fluttertoast.showToast(
          msg: "Could not retrieve user ID from server. Please try again.",
          toastLength: Toast.LENGTH_SHORT,
        );
        return;
      }

      // Create new UserModel that includes backend userId in additionalData
      final currentFirebaseUser = FirebaseAuth.instance.currentUser!;
      final enrichedUser =
          UserModel.fromFirebaseUser(currentFirebaseUser).copyWith(
        additionalData: {
          'userId': userId, // Make sure this is an integer
          'isAdmin': syncResult['isAdmin'] ?? false,
        },
      );

      // Get the UserService from Provider
      final userService = Provider.of<UserService>(context, listen: false);
      await userService.setCurrentUser(enrichedUser);
      
      // Verify the userId was properly stored
      print('Stored userId in UserService: ${userService.currentUser?.additionalData['userId']}');
      
      // Check if payment methods exist for this user
      try {
        print('Checking payment methods for userId: $userId');
        List<PaymentMethod> paymentMethods =
            await PaymentService.getPaymentMethods(userId);

        print('Payment methods found: ${paymentMethods.length} for userId: $userId'); // Debug log

        if (paymentMethods.isNotEmpty) {
          print('Navigating to ShoppingListWelcomeScreen'); 
           Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const ShoppingListWelcomeScreen(),
            ),
          );
        } else {
          // If no payment methods, go to payment details screen with the userId
          print('Navigating to PaymentDetailsScreen with userId: $userId'); // Debug log
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => PaymentDetailsScreen(userId: userId),
            ),
          );
        }
      } catch (e) {
        print('Error checking payment methods: $e');
        // Default to payment details screen if there's an error
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentDetailsScreen(userId: userId),
          ),
        );
      }
    } else {
      print('User sync failed: ${syncResult['error'] ?? 'Unknown error'}');
      Fluttertoast.showToast(
        msg: "Failed to sync user data. Please try again.",
        toastLength: Toast.LENGTH_SHORT,
      );
    }
  } catch (e) {
    print('Error navigating after login: $e');
    Fluttertoast.showToast(
      msg: "Error during login process. Please try again.",
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}


  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Check if email is verified
      User? user = userCredential.user;
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

      // Save user data to UserService if available
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        await userService.setCurrentUser(UserModel.fromFirebaseUser(user!));
      } catch (e) {
        print('Error saving user data: $e');
        // Continue even if UserService is not available
      }

      Fluttertoast.showToast(msg: 'Login Successful!');

      // Navigate based on payment details
      await _navigateAfterLogin(user!);
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
      await googleSignIn.signOut();

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
        // Save user data to UserService if available
        try {
          final userService = Provider.of<UserService>(context, listen: false);
          await userService.setCurrentUser(UserModel.fromFirebaseUser(user));
        } catch (e) {
          print('Error saving user data: $e');
          // Continue even if UserService is not available
        }

        Fluttertoast.showToast(msg: 'Google Sign-In Successful!');

        // Navigate based on payment details
        await _navigateAfterLogin(user);
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

                      SizedBox(height: 20),
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

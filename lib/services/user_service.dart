import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// User model to store user information
class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final Map<String, dynamic> additionalData;
  final bool isEmailVerified;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    this.additionalData = const {},
    this.isEmailVerified = false,
  });

  // Convert UserModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'additionalData': additionalData,
      'isEmailVerified': isEmailVerified,
    };
  }

  // Create UserModel from JSON
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'],
      email: json['email'],
      displayName: json['displayName'],
      photoURL: json['photoURL'],
      additionalData: json['additionalData'] ?? {},
      isEmailVerified: json['isEmailVerified'] ?? false,
    );
  }

  // Create UserModel from Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
      isEmailVerified: user.emailVerified,
    );
  }

  // Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
    bool? isEmailVerified,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      additionalData: additionalData ?? this.additionalData,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

// UserService to manage user state throughout the app
class UserService extends ChangeNotifier {
  // Singleton pattern
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  // Current user data
  UserModel? _currentUser;
  bool _isLoading = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;

  // Initialize the service
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load user from shared preferences
      await _loadUserFromPrefs();

      // Check if Firebase has a current user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        // Update with latest Firebase user data
        await setCurrentUser(UserModel.fromFirebaseUser(firebaseUser));
      }
    } catch (e) {
      print('Error initializing UserService: $e');
      await clearCurrentUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

// Update the setCurrentUser method
  Future<void> setCurrentUser(UserModel user) async {
    _currentUser = user;

    // Debug log to verify the user data
    print('Setting current user: ${user.uid}');
    print('User additionalData: ${user.additionalData}');

    await _saveUserToPrefs(user);
    notifyListeners();
  }

  Future<void> updateUserData(Map<String, dynamic> data) async {
    if (_currentUser == null) return;

    // Debug log to see what data is being updated
    print('Updating user data: $data');
    print('Current additionalData: ${_currentUser!.additionalData}');

    final updatedUser = _currentUser!.copyWith(
      additionalData: {..._currentUser!.additionalData, ...data},
    );

    // Debug log to see the updated data
    print('Updated additionalData: ${updatedUser.additionalData}');

    await setCurrentUser(updatedUser);
  }

  // Clear current user (logout)
  Future<void> clearCurrentUser() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    notifyListeners();
  }

  // Save user to shared preferences
  Future<void> _saveUserToPrefs(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode(user.toJson());
    await prefs.setString('user_data', userData);
  }

  // Load user from shared preferences
  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('user_data');

    if (userData != null) {
      try {
        final userMap = jsonDecode(userData) as Map<String, dynamic>;
        _currentUser = UserModel.fromJson(userMap);
      } catch (e) {
        print('Error parsing user data: $e');
        await prefs.remove('user_data');
      }
    }
  }

  // Check if user is admin
  bool isUserAdmin() {
    if (_currentUser == null) return false;
    return _currentUser!.additionalData['isAdmin'] == true;
  }

  // Check if user has verified email
  bool isEmailVerified() {
    if (_currentUser == null) return false;
    return _currentUser!.isEmailVerified;
  }

  // Refresh user data from Firebase
  Future<void> refreshUserData() async {
    if (_currentUser == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Reload Firebase user
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser != null) {
        await firebaseUser.reload();

        // Update current user with fresh data
        final refreshedUser = UserModel.fromFirebaseUser(firebaseUser);

        // Preserve additional data
        final updatedUser = refreshedUser.copyWith(
          additionalData: _currentUser!.additionalData,
        );

        await setCurrentUser(updatedUser);
      }
    } catch (e) {
      print('Error refreshing user data: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

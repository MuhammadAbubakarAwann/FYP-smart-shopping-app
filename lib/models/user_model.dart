import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final Map<String, dynamic> additionalData;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    Map<String, dynamic>? additionalData,
  }) : additionalData = additionalData ?? {};

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoURL: user.photoURL,
    );
  }

  // Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoURL,
    Map<String, dynamic>? additionalData,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      additionalData: additionalData ?? Map.from(this.additionalData),
    );
  }

  // Convert to JSON string
  String toJson() {
    return jsonEncode({
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'additionalData': additionalData,
    });
  }

  // Create from JSON string
  factory UserModel.fromJson(String jsonString) {
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return UserModel(
      uid: data['uid'],
      email: data['email'],
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      additionalData: data['additionalData'] ?? {},
    );
  }
}

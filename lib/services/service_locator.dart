import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'user_service.dart';

/// A helper class to access services throughout the app
class ServiceLocator {
  /// Get the UserService instance
  static UserService getUserService(BuildContext context) {
    try {
      return Provider.of<UserService>(context, listen: false);
    } catch (e) {
      print('Error accessing UserService: $e');
      // Return a default instance as fallback
      return UserService();
    }
  }
  
  /// Get the current user ID safely
  static int? getUserId(BuildContext context) {
    try {
      final userService = getUserService(context);
      return userService.currentUser?.additionalData['userId'];
    } catch (e) {
      print('Error getting userId: $e');
      return null;
    }
  }
}

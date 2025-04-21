import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/user_service.dart';

class UserSyncService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String apiBaseUrl = 'http://192.168.100.5:5000'; // Use your actual API URL
  final UserService _userService = UserService(); // Use the singleton directly

  // Sync Firebase user with backend database
  Future<Map<String, dynamic>> syncUserWithDatabase() async {
    try {
      // Get current Firebase user
      final firebaseUser = _auth.currentUser;
      if (firebaseUser == null) {
        throw Exception('No authenticated user found');
      }

      // Check if we already have a userId in UserService
      final currentUser = _userService.currentUser;
      if (currentUser?.additionalData['userId'] != null) {
        // User is already synchronized
        final userId = currentUser!.additionalData['userId'];
        print('User already synchronized with userId: $userId');
        return {
          'success': true,
          'userId': userId,
          'message': 'User already synchronized'
        };
      }

      // Make API call to backend to find or create user
      print('Making API call to sync user: ${firebaseUser.uid}, ${firebaseUser.email}');
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/users/sync'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUid': firebaseUser.uid,
          'email': firebaseUser.email,
          'name': firebaseUser.displayName ?? 'User',
          'photoURL': firebaseUser.photoURL,
        }),
      );

      print('API response status: ${response.statusCode}');
      print('API response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          // Make sure we're getting an integer userId
          final userId = data['user']['id'] is int 
              ? data['user']['id'] 
              : int.tryParse(data['user']['id'].toString());
              
          if (userId == null) {
            throw Exception('Invalid userId returned from server');
          }
          
          // Store PostgreSQL userId in UserService
          await _userService.updateUserData({
            'userId': userId,
            'databaseSynced': true,
          });
          
          print('Successfully synced user with userId: $userId');
          
          return {
            'success': true,
            'userId': userId,
            'message': data['message']
          };
        } else {
          throw Exception(data['error'] ?? 'Failed to sync user');
        }
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error syncing user: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }
}

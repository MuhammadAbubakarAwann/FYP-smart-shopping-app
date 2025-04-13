import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentMethod {
  final int id;
  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;
  final bool isDefault;
  
  PaymentMethod({
    required this.id,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.isDefault,
  });
  
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'],
      last4: json['last4'],
      brand: json['brand'],
      expiryMonth: json['expiryMonth'],
      expiryYear: json['expiryYear'],
      isDefault: json['isDefault'] ?? false,
    );
  }
}

class PaymentService {
  static const String apiBaseUrl = 'http://192.168.100.4:5000';
  static String? get stripePublishableKey => dotenv.env['STRIPE_PUBLISHABLE_KEY'];

  // Validate card details
  static bool validateCardNumber(String cardNumber) {
    // Remove any spaces or dashes
    cardNumber = cardNumber.replaceAll(RegExp(r'\s+|-'), '');

    // Check if the card number is numeric and has a valid length (13-19 digits)
    if (!RegExp(r'^[0-9]{13,19}$').hasMatch(cardNumber)) {
      return false;
    }

    // Luhn algorithm for card number validation
    int sum = 0;
    bool alternate = false;
    for (int i = cardNumber.length - 1; i >= 0; i--) {
      int digit = int.parse(cardNumber[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }

  static bool validateExpiryDate(String expiryDate) {
    // Check format MM/YY
    if (!RegExp(r'^(0[1-9]|1[0-2])\s?\/\s?([0-9]{2})$').hasMatch(expiryDate)) {
      return false;
    }

    // Extract month and year
    List<String> parts = expiryDate.split('/');
    int month = int.parse(parts[0].trim());
    int year = int.parse(parts[1].trim()) + 2000; // Convert to 4-digit year

    // Get current date
    DateTime now = DateTime.now();
    int currentYear = now.year;
    int currentMonth = now.month;

    // Check if the card is expired
    if (year < currentYear || (year == currentYear && month < currentMonth)) {
      return false;
    }

    return true;
  }

  static bool validateCVV(String cvv) {
    // CVV should be 3 or 4 digits
    return RegExp(r'^[0-9]{3,4}$').hasMatch(cvv);
  }

  // Save payment method to database
  static Future<Map<String, dynamic>> savePaymentMethod({
    required int userId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String country,
  }) async {
    try {
      // Extract month and year from expiry date
      List<String> parts = expiryDate.split('/');
      int expiryMonth = int.parse(parts[0].trim());
      int expiryYear = int.parse(parts[1].trim()) + 2000;

      // Get last 4 digits of card
      String last4 = cardNumber.substring(cardNumber.length - 4);

      // Determine card brand (simplified)
      String brand = 'unknown';
      if (cardNumber.startsWith('4')) {
        brand = 'visa';
      } else if (cardNumber.startsWith('5')) {
        brand = 'mastercard';
      } else if (cardNumber.startsWith('3')) {
        brand = 'amex';
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/payment/save-card'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'last4': last4,
          'brand': brand,
          'expiryMonth': expiryMonth,
          'expiryYear': expiryYear,
          'country': country,
          'isDefault': true,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to save payment method: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error saving payment method: $e');
    }
  }
  
  // Get saved payment methods for a user
  static Future<List<PaymentMethod>> getPaymentMethods(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl/api/payment/$userId/payment-methods'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['paymentMethods'] != null) {
          final List<dynamic> methods = data['paymentMethods'];
          return methods.map((method) => PaymentMethod.fromJson(method)).toList();
        }
      }
      
      // If no payment methods found or error occurred
      return [];
    } catch (e) {
      print('Error fetching payment methods: $e');
      return [];
    }
  }
  
  // Process a payment with Stripe
  static Future<Map<String, dynamic>> processPayment({
    required int userId,
    required double amount,
    int? paymentMethodId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/payment/$userId/process-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'paymentMethodId': paymentMethodId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false, 
          'error': errorData['error'] ?? 'Payment processing failed',
          'details': errorData['details'],
          'code': errorData['code']
        };
      }
    } catch (e) {
      print('Error processing payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

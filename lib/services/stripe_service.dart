import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static String apiBaseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000/api';
  
  // Initialize Stripe
  static Future<void> initialize() async {
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';
    await Stripe.instance.applySettings();
  }
  
  // Create a setup intent for saving a card
  static Future<Map<String, dynamic>> createSetupIntent(int userId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/payment/create-setup-intent'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create setup intent: ${response.body}');
    }
  }
  
  // Save a payment method
  static Future<Map<String, dynamic>> savePaymentMethod(int userId, String paymentMethodId) async {
    final response = await http.post(
      Uri.parse('$apiBaseUrl/payment/save-payment-method'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': userId,
        'paymentMethodId': paymentMethodId,
      }),
    );
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to save payment method: ${response.body}');
    }
  }
  
  // Get saved payment methods
  static Future<List<dynamic>> getPaymentMethods(int userId) async {
    final response = await http.get(
      Uri.parse('$apiBaseUrl/payment/$userId/payment-methods'),
      headers: {'Content-Type': 'application/json'},
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['paymentMethods'] ?? [];
    } else {
      throw Exception('Failed to get payment methods: ${response.body}');
    }
  }
  
  // Add a new card
  static Future<Map<String, dynamic>> addNewCard(int userId, BuildContext context) async {
    try {
      // 1. Create a setup intent
      final setupIntentData = await createSetupIntent(userId);
      final clientSecret = setupIntentData['clientSecret'];
      
      // 2. Collect card details
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      
      // 3. Confirm the setup intent
      await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,  // Corrected parameter name
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );
      
      // 4. Save the payment method to your backend
      return await savePaymentMethod(userId, paymentMethod.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
      rethrow;
    }
  }
}
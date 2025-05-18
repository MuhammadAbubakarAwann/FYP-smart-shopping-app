import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class StripeService {
  static String get apiBaseUrl =>
      dotenv.env['API_URL'] ?? 'http://192.168.100.6:5000';
  static String get publishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

  // Create a SetupIntent on the server
  static Future<Map<String, dynamic>> createSetupIntent(int userId) async {
    try {
      debugPrint('Creating setup intent for user $userId');

      // For testing, return a mock response if the API URL is not set
      if (apiBaseUrl.isEmpty) {
        debugPrint('API URL is empty, returning mock response');
        return {
          'success': true,
          'clientSecret': 'seti_mock_secret_for_testing',
          'customerId': 'cus_mock_customer_id',
        };
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/payment/create-setup-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
        }),
      );

      debugPrint('Setup intent response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Setup intent created successfully');
        return data;
      } else {
        debugPrint('Failed to create setup intent: ${response.body}');
        throw Exception('Failed to create setup intent: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error creating setup intent: $e');
      throw Exception('Error creating setup intent: $e');
    }
  }

  // Confirm the SetupIntent with the card details
  static Future<String> confirmSetupIntent(String clientSecret) async {
    try {
      debugPrint(
          'Confirming setup intent with client secret: ${clientSecret.substring(0, 10)}...');

      // For testing, return a mock payment method ID if the client secret is a mock
      if (clientSecret == 'seti_mock_secret_for_testing') {
        debugPrint(
            'Using mock client secret, returning mock payment method ID');
        return 'pm_mock_payment_method_id';
      }

      // Confirm the setup intent with the card
      final result = await Stripe.instance.confirmSetupIntent(
        paymentIntentClientSecret: clientSecret,
        params: const PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(),
        ),
      );

      debugPrint('Setup intent confirmation result status: ${result.status}');

      // Return the payment method ID from the setup intent
      if (result.status == 'succeeded') {
        final paymentMethodId = result.paymentMethodId;
        debugPrint('Payment method ID: ${paymentMethodId.substring(0, 5)}...');
        return paymentMethodId;
      } else {
        debugPrint(
            'Setup intent confirmation failed with status: ${result.status}');
        throw Exception(
            'Setup intent confirmation failed with status: ${result.status}');
      }
    } catch (e) {
      debugPrint('Error confirming setup intent: $e');
      throw Exception('Error confirming setup intent: $e');
    }
  }

  // Save the payment method to the backend
  static Future<Map<String, dynamic>> savePaymentMethod({
    required int userId,
    required String paymentMethodId,
    required CardFieldInputDetails? cardDetails,
  }) async {
    try {
      debugPrint('Saving payment method for user $userId');

      // Validate inputs
      if (cardDetails == null) {
        debugPrint('Card details are null');
        throw Exception('Card details cannot be null');
      }

      // For testing, return a mock response if the API URL is not set
      if (apiBaseUrl.isEmpty) {
        debugPrint('API URL is empty, returning mock response');
        return {
          'success': true,
          'paymentMethod': {
            'id': 1,
            'userId': userId,
            'stripePaymentMethodId': paymentMethodId,
            'last4': cardDetails.last4 ?? '4242',
            'brand': cardDetails.brand ?? 'visa',
          },
        };
      }

      // Send to backend
      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/payment/save-payment-method'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'stripePaymentMethodId': paymentMethodId,
          'last4': cardDetails.last4 ?? '****',
          'brand': cardDetails.brand ?? 'unknown',
          'expiryMonth': cardDetails.expiryMonth ?? 12,
          'expiryYear': cardDetails.expiryYear ?? 2030,
          'country': 'US',
          'isDefault': true,
        }),
      );

      debugPrint('Save payment method response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Payment method saved successfully');
        return data;
      } else {
        debugPrint('Failed to save payment method: ${response.body}');
        throw Exception('Failed to save payment method: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error saving payment method: $e');
      throw Exception('Error saving payment method: $e');
    }
  }

  // Process a payment with a saved payment method
  static Future<Map<String, dynamic>> processPayment({
    required int userId,
    required double amount,
    int? paymentMethodId,
  }) async {
    try {
      debugPrint('Processing payment for user $userId, amount: $amount');

      // For testing, return a mock response if the API URL is not set
      if (apiBaseUrl.isEmpty) {
        debugPrint('API URL is empty, returning mock response');
        return {
          'success': true,
          'transactionId': 'txn_mock_transaction_id',
          'amount': amount,
          'paymentMethod': {
            'id': paymentMethodId ?? 1,
            'last4': '4242',
            'brand': 'visa',
          },
        };
      }

      final response = await http.post(
        Uri.parse('$apiBaseUrl/api/payment/$userId/process-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amount,
          'paymentMethodId': paymentMethodId,
        }),
      );

      debugPrint('Process payment response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Payment processed successfully');
        return data;
      } else {
        debugPrint('Failed to process payment: ${response.body}');
        return {
          'success': false,
          'error': 'Payment processing failed: ${response.body}'
        };
      }
    } catch (e) {
      debugPrint('Error processing payment: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}

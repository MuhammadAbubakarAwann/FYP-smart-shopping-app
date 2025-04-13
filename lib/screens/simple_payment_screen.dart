import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/payment_service.dart';
import 'items_selector_screen.dart';

class SimplePaymentScreen extends StatefulWidget {
  final int userId;

  const SimplePaymentScreen({
    Key? key,
    this.userId = 1, // Default user ID for testing
  }) : super(key: key);

  @override
  _SimplePaymentScreenState createState() => _SimplePaymentScreenState();
}

class _SimplePaymentScreenState extends State<SimplePaymentScreen> {
  bool _isLoading = false;
  String _selectedCountry = 'Pakistan';
  CardFieldInputDetails? _cardFieldInputDetails;

  @override
  void initState() {
    super.initState();
    print('Stripe publishable key: ${Stripe.publishableKey}');
  }

  void _navigateToItemsSelector() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ItemsSelectorScreen()),
    );
  }

  Future<void> _saveCard() async {
    if (_cardFieldInputDetails == null || !_cardFieldInputDetails!.complete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete card details')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create payment method using Stripe
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
                // Add optional billing details here if needed
                ),
          ),
        ),
      );
      // Save payment method to backend
      await PaymentService.savePaymentMethodWithId(
        userId: widget.userId,
        stripePaymentMethodId: paymentMethod.id,
        country: _selectedCountry,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment details saved successfully')),
      );

      // Navigate to items selector screen
      _navigateToItemsSelector();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
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
      appBar: AppBar(
        title: const Text('Add Payment Method'),
        actions: [
          TextButton(
            onPressed: _navigateToItemsSelector,
            child: const Text('Skip', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter Card Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Card details form - USING SIMPLER CARDFIELD
            Container(
              height: 50, // Explicit height
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: CardField(
                onCardChanged: (details) {
                  setState(() {
                    _cardFieldInputDetails = details;
                  });
                },
              ),
            ),

            const SizedBox(height: 20),

            // Country dropdown
            const Text(
              'Country',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountry,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                        value: 'Pakistan', child: Text('Pakistan')),
                    DropdownMenuItem(value: 'USA', child: Text('USA')),
                    DropdownMenuItem(value: 'UK', child: Text('UK')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCountry = value;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveCard,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Card Details'),
              ),
            ),

            // Debug info
            const SizedBox(height: 30),
            const Text(
              'If card fields are not visible:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Stripe key: ${Stripe.publishableKey.substring(0, 10)}...'),
            const SizedBox(height: 8),
            const Text(
                '1. Make sure flutter_stripe is in dependencies, not dev_dependencies'),
            const SizedBox(height: 4),
            const Text('2. Run flutter clean && flutter pub get'),
            const SizedBox(height: 4),
            const Text('3. Restart the app completely'),
          ],
        ),
      ),
    );
  }
}

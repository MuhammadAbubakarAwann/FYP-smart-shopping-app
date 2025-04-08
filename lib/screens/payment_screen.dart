import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/items_selector_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  String _selectedPaymentMethod = 'paypal';
  String _selectedCountry = 'Pakistan';

  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Payment– Details',
          style: TextStyle(
            fontSize: 18,
            color: Colors.lightBlue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Credit or Debit Card Option
            _buildPaymentOption(
              value: 'card',
              icon: Icons.credit_card,
              label: 'Credit or debit card',
              content: _buildCardForm(),
            ),

            const SizedBox(height: 10),

            // PayPal Option
            _buildPaymentOption(
              value: 'paypal',
              iconAsset: 'assets/paypal.png',
              label: 'PayPal',
              content: _buildCountryDropdown(),
            ),

            const Spacer(),

            // Proceed Button
            Center(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                height: 38,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ItemsSelectorScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    IconData? icon,
    String? iconAsset,
    required String label,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.lightBlue, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          RadioListTile<String>(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: value,
            groupValue: _selectedPaymentMethod,
            onChanged: (val) {
              setState(() {
                _selectedPaymentMethod = val!;
              });
            },
            title: Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 18)
                else if (iconAsset != null)
                  Image.asset(iconAsset, height: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          if (_selectedPaymentMethod == value)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _buildTextField(_cardNumberController, 'Card Number'),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildTextField(_expiryDateController, 'Expiry Date'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildTextField(_cvvController, 'CVV'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Dropdown Row
        Row(
          children: [
            const Text("Country: ", style: TextStyle(fontSize: 13)),
            const SizedBox(width: 10),
            SizedBox(
              width: 180, // 👈 limit width of dropdown inside card option
              child: _buildCountryDropdown(),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      isDense: true,
      icon: const Icon(Icons.arrow_drop_down, size: 18),
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 13),
      items: const [
        DropdownMenuItem(value: 'Pakistan', child: Text('Pakistan', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'USA', child: Text('USA', style: TextStyle(fontSize: 13))),
        DropdownMenuItem(value: 'UK', child: Text('UK', style: TextStyle(fontSize: 13))),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCountry = value!;
        });
      },
    );
  }
}

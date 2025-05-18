import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/payment_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import 'shopping_list_welcome_screen.dart';

class PaymentDetailsScreen extends StatefulWidget {
  const PaymentDetailsScreen({
    Key? key,
    this.userId,
  }) : super(key: key);

  final int? userId;

  @override
  _PaymentDetailsScreenState createState() => _PaymentDetailsScreenState();
}

class _PaymentDetailsScreenState extends State<PaymentDetailsScreen> {
  String _selectedPaymentMethod = 'card'; // Default to card selected
  String _selectedCountry = 'Pakistan';
  bool _isLoading = false;
  bool _isCardValid = false;
  bool _isExpiryValid = false;
  bool _isCvvValid = false;
  int? _userId;

  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Add listeners to validate input as user types
    _cardNumberController.addListener(_validateCard);
    _expiryDateController.addListener(_validateExpiry);
    _cvvController.addListener(_validateCvv);

    // Get userId in initState to avoid context issues
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserId();
    });
  }

  // Update the _initializeUserId method
  Future<void> _initializeUserId() async {
    // First check if userId was passed directly
    if (widget.userId != null) {
      setState(() {
        _userId = widget.userId;
      });
      print('Using provided userId: $_userId');
      return;
    }

    // Try to get from UserService using Provider
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final userId = userService.currentUser?.additionalData['userId'];
      
      // Ensure userId is an integer
      int? parsedUserId;
      if (userId != null) {
        parsedUserId = userId is int ? userId : int.tryParse(userId.toString());
      }
      
      setState(() {
        _userId = parsedUserId;
      });
      
      print('Retrieved userId from UserService: $_userId (original value: $userId)');
      
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in again.')),
        );
      }
    } catch (e) {
      print('Error getting userId from UserService: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _validateCard() {
    setState(() {
      _isCardValid =
          PaymentService.validateCardNumber(_cardNumberController.text);
    });
  }

  void _validateExpiry() {
    setState(() {
      _isExpiryValid =
          PaymentService.validateExpiryDate(_expiryDateController.text);
    });
  }

  void _validateCvv() {
    setState(() {
      _isCvvValid = PaymentService.validateCVV(_cvvController.text);
    });
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  // Navigate to items selector screen
  void _navigateToItemsSelector() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const ShoppingListWelcomeScreen(),
      ),
    );
  }

  // Update the _processPayment method
  Future<void> _processPayment() async {
    // Validate all fields first
    if (_selectedPaymentMethod == 'card' &&
        (!_isCardValid || !_isExpiryValid || !_isCvvValid)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid card details')),
      );
      return;
    }

    // Check if userId is available
    if (_userId == null) {
      // Try one more time to get the userId using Provider
      try {
        final userService = Provider.of<UserService>(context, listen: false);
        final userId = userService.currentUser?.additionalData['userId'];
        
        // Ensure userId is an integer
        int? parsedUserId;
        if (userId != null) {
          parsedUserId = userId is int ? userId : int.tryParse(userId.toString());
          
          if (parsedUserId != null) {
            setState(() {
              _userId = parsedUserId;
            });
            print('Retrieved userId at payment time: $_userId');
          }
        }
      } catch (e) {
        print('Error getting userId at payment time: $e');
      }
      
      // If still null, show error
      if (_userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User ID not found. Please log in again.')),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      if (_selectedPaymentMethod == 'card') {
        print('Processing payment for userId: $_userId'); // Debug log

        // Save card details to database
        final response = await PaymentService.savePaymentMethod(
          userId: _userId!,
          cardNumber: _cardNumberController.text,
          expiryDate: _expiryDateController.text,
          cvv: _cvvController.text,
          country: _selectedCountry,
        );

        print('Payment method save response: $response'); // Debug log

        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment details saved successfully')),
          );

          // Navigate to items selector screen
          _navigateToItemsSelector();
        } else {
          throw Exception(
              response['error'] ?? 'Failed to save payment details');
        }
      } else {
        // For other payment methods, just navigate to items selector
        _navigateToItemsSelector();
      }
    } catch (e) {
      print('Error in _processPayment: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Rest of your code remains the same...
  // (I'm not including the rest of the UI code to keep this response focused on the fix)
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 22,
            color: Color(0xFF8BE0FF),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _navigateToItemsSelector, // Skip button now navigates to items selector
            child: const Text(
              'Skip',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payment method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Credit or Debit Card Option
            _buildPaymentOption(
              value: 'card',
              icon: Icons.credit_card,
              label: 'Credit or debit card',
            ),

            const SizedBox(height: 16),

            // Easy Paisa Option (replacing PayPal)
            _buildPaymentOption(
              value: 'easypaisa',
              iconAsset: 'assets/easypaisa.png', // You'll need this asset
              label: '',
              iconFallback: Icons.account_balance_wallet,
              iconColor: Colors.green,
            ),

            const Spacer(),

            // Proceed Button - Updated to process payment
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0CA8E1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Proceed",
                        style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
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
    IconData? iconFallback,
    Color iconColor = const Color(0xFF0CA8E1),
  }) {
    bool isSelected = _selectedPaymentMethod == value;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0CA8E1), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Payment method header with radio button
          RadioListTile<String>(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
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
                  Icon(icon, size: 24, color: iconColor)
                else if (iconAsset != null)
                  Image.asset(
                    iconAsset,
                    height: 24,
                    errorBuilder: (context, error, stackTrace) => Icon(
                        iconFallback ?? Icons.payment,
                        size: 24,
                        color: iconColor),
                  )
                else if (iconFallback != null)
                  Icon(iconFallback, size: 24, color: iconColor),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            activeColor: const Color(0xFF0CA8E1),
          ),

          // Expanded content for selected payment method
          if (isSelected && value == 'card')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _buildCardForm(),
            ),
        ],
      ),
    );
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Card number field
        const Text(
          'Card number',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _buildCardNumberField(),
        const SizedBox(height: 16),

        // Expiry date and CVV row
        Row(
          children: [
            // Expiry date field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expiry date',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildExpiryDateField(),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Security code field
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Security code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSecurityCodeField(),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Country dropdown
        _buildCountryDropdown(),
      ],
    );
  }

  Widget _buildCardNumberField() {
    return TextField(
      controller: _cardNumberController,
      decoration: InputDecoration(
        hintText: 'Card number',
        prefixIcon: const Icon(Icons.credit_card, color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isCardValid || _cardNumberController.text.isEmpty
                  ? Colors.grey
                  : Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isCardValid || _cardNumberController.text.isEmpty
                  ? const Color(0xFF0CA8E1)
                  : Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        errorText: _cardNumberController.text.isNotEmpty && !_isCardValid
            ? 'Invalid card number'
            : null,
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(16),
        _CardNumberFormatter(),
      ],
    );
  }

  Widget _buildExpiryDateField() {
    return TextField(
      controller: _expiryDateController,
      decoration: InputDecoration(
        hintText: 'MM / YY',
        prefixIcon:
            const Icon(Icons.calendar_today, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isExpiryValid || _expiryDateController.text.isEmpty
                  ? Colors.grey
                  : Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isExpiryValid || _expiryDateController.text.isEmpty
                  ? const Color(0xFF0CA8E1)
                  : Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        errorText: _expiryDateController.text.isNotEmpty && !_isExpiryValid
            ? 'Invalid expiry date'
            : null,
      ),
      keyboardType: TextInputType.datetime,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
        _ExpiryDateFormatter(),
      ],
    );
  }

  Widget _buildSecurityCodeField() {
    return TextField(
      controller: _cvvController,
      decoration: InputDecoration(
        hintText: 'CVC',
        prefixIcon: const Icon(Icons.security, color: Colors.grey, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isCvvValid || _cvvController.text.isEmpty
                  ? Colors.grey
                  : Colors.red),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
              color: _isCvvValid || _cvvController.text.isEmpty
                  ? const Color(0xFF0CA8E1)
                  : Colors.red),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        errorText: _cvvController.text.isNotEmpty && !_isCvvValid
            ? 'Invalid CVV'
            : null,
      ),
      keyboardType: TextInputType.number,
      obscureText: true,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
    );
  }

  Widget _buildCountryDropdown() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCountry,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          items: const [
            DropdownMenuItem(value: 'Pakistan', child: Text('Pakistan')),
            DropdownMenuItem(value: 'USA', child: Text('USA')),
            DropdownMenuItem(value: 'UK', child: Text('UK')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedCountry = value!;
            });
          },
        ),
      ),
    );
  }
}

// Card number formatter to add spaces after every 4 digits
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Add a space after every 4 digits
    StringBuffer buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) {
        buffer.write(' ');
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

// Expiry date formatter to add a slash after 2 digits
class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all non-digits
    String text = newValue.text.replaceAll(RegExp(r'\D'), '');

    // Add a slash after 2 digits
    if (text.length >= 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

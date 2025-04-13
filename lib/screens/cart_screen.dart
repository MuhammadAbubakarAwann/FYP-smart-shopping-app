import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/payment_service.dart';

// Reuse the Product model from qr_code_scanner.dart
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String qrCode;
  final String status;
  int quantity;
  
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.qrCode,
    required this.status,
    this.quantity = 1,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      category: json['category'] ?? '',
      price: json['price'] != null 
          ? double.tryParse(json['price'].toString()) ?? 0.0 
          : 0.0,
      qrCode: json['qr_code'] ?? '',
      status: json['status'] ?? 'IN_STORE',
      quantity: json['quantity'] ?? 1,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'qr_code': qrCode,
      'status': status,
      'quantity': quantity,
    };
  }
}

class CartScreen extends StatefulWidget {
  final int userId;
  
  const CartScreen({
    Key? key, 
    this.userId = 1, // Default user ID for testing
  }) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Product> cartItems = [];
  bool isLoading = true;
  String? errorMessage;
  bool isProcessingPayment = false;
  List<PaymentMethod> paymentMethods = [];
  PaymentMethod? selectedPaymentMethod;
  
  @override
  void initState() {
    super.initState();
    _loadCartItems();
    _loadPaymentMethods();
  }
  
  Future<void> _loadPaymentMethods() async {
    try {
      final methods = await PaymentService.getPaymentMethods(widget.userId);
      setState(() {
        paymentMethods = methods;
        if (methods.isNotEmpty) {
          // Find default payment method or use the first one
          selectedPaymentMethod = methods.firstWhere(
            (method) => method.isDefault, 
            orElse: () => methods.first
          );
        }
      });
    } catch (e) {
      print('Error loading payment methods: $e');
    }
  }
  
  Future<void> _loadCartItems() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    
    try {
      // First try to load from local storage (for offline access)
      await _loadCartFromLocalStorage();
      
      // Then try to fetch from server (for up-to-date data)
      await _fetchCartFromServer();
    } catch (e) {
      print('Error loading cart: $e');
      setState(() {
        errorMessage = 'Failed to load cart items. Please try again.';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }
  
  Future<void> _loadCartFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString('cart_items');
      
      if (cartData != null) {
        final List<dynamic> decodedData = json.decode(cartData);
        setState(() {
          cartItems = decodedData.map((item) => Product.fromJson(item)).toList();
        });
        print('Loaded ${cartItems.length} items from local storage');
      }
    } catch (e) {
      print('Error loading from local storage: $e');
      // Don't set error message here, as we'll try server next
    }
  }
  
  Future<void> _fetchCartFromServer() async {
    try {
      final apiUrl = PaymentService.apiBaseUrl;
      final response = await http.get(
        Uri.parse('$apiUrl/api/cart/${widget.userId}'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['items'] != null) {
          final List<dynamic> items = data['items'];
          final List<Product> serverItems = [];
          
          for (var item in items) {
            final product = item['product'];
            if (product != null) {
              serverItems.add(Product.fromJson({
                ...product,
                'quantity': item['quantity'] ?? 1,
              }));
            }
          }
          
          setState(() {
            cartItems = serverItems;
          });
          
          // Save to local storage for offline access
          _saveCartToLocalStorage();
          
          print('Loaded ${cartItems.length} items from server');
        }
      } else {
        print('Server error: ${response.statusCode}');
        // Only set error if we don't have local data
        if (cartItems.isEmpty) {
          setState(() {
            errorMessage = 'Failed to fetch cart from server. Status: ${response.statusCode}';
          });
        }
      }
    } catch (e) {
      print('Error fetching from server: $e');
      // Only set error if we don't have local data
      if (cartItems.isEmpty) {
        setState(() {
          errorMessage = 'Network error. Using offline data.';
        });
      }
    }
  }
  
  Future<void> _saveCartToLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode(cartItems.map((item) => item.toJson()).toList());
      await prefs.setString('cart_items', cartData);
      print('Saved cart to local storage');
    } catch (e) {
      print('Error saving to local storage: $e');
    }
  }
  
  Future<void> _updateQuantity(Product product, int newQuantity) async {
    if (newQuantity < 1) return;
    
    setState(() {
      product.quantity = newQuantity;
    });
    
    try {
      final apiUrl = PaymentService.apiBaseUrl;
      final response = await http.put(
        Uri.parse('$apiUrl/api/cart/${widget.userId}/item/${product.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'quantity': newQuantity,
        }),
      );
      
      if (response.statusCode == 200) {
        print('Updated quantity on server');
        // Update local storage
        _saveCartToLocalStorage();
      } else {
        print('Failed to update quantity on server: ${response.statusCode}');
        // Show a snackbar but don't revert the UI change
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update quantity on server. Will retry later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Changes saved locally.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  Future<void> _removeItem(Product product) async {
    setState(() {
      cartItems.removeWhere((item) => item.id == product.id);
    });
    
    // Update local storage immediately
    _saveCartToLocalStorage();
    
    try {
      final apiUrl = PaymentService.apiBaseUrl;
      final response = await http.delete(
        Uri.parse('$apiUrl/api/cart/${widget.userId}/item/${product.id}'),
      );
      
      if (response.statusCode == 200) {
        print('Removed item from server');
      } else {
        print('Failed to remove item from server: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to remove item on server. Will retry later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Changes saved locally.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  // Show payment method selection dialog
  Future<PaymentMethod?> _showPaymentMethodDialog() async {
    if (paymentMethods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No payment methods available. Using default payment.'),
          backgroundColor: Colors.orange,
        ),
      );
      return null;
    }
    
    return await showDialog<PaymentMethod>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Select Payment Method',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ...paymentMethods.map((method) {
                  return ListTile(
                    leading: Icon(_getCardIcon(method.brand)),
                    title: Text('${method.brand.toUpperCase()} •••• ${method.last4}'),
                    subtitle: Text('Expires ${method.expiryMonth}/${method.expiryYear % 100}'),
                    trailing: method.isDefault ? const Icon(Icons.check_circle, color: Colors.green) : null,
                    onTap: () {
                      Navigator.of(context).pop(method);
                    },
                  );
                }).toList(),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  IconData _getCardIcon(String brand) {
    switch (brand.toLowerCase()) {
      case 'visa':
        return Icons.credit_card;
      case 'mastercard':
        return Icons.credit_card;
      case 'amex':
        return Icons.credit_card;
      default:
        return Icons.credit_card;
    }
  }
  
  // Show payment confirmation dialog
  Future<bool> _showPaymentConfirmationDialog() async {
    return await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(false),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'You want to Pay Now?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (selectedPaymentMethod != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(_getCardIcon(selectedPaymentMethod!.brand)),
                        const SizedBox(width: 10),
                        Text(
                          '${selectedPaymentMethod!.brand.toUpperCase()} •••• ${selectedPaymentMethod!.last4}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  'Total: \$${_calculateTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0CA8E1),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[200],
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0CA8E1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                      ),
                      child: const Text('Pay Now'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Show payment success dialog
  Future<void> _showPaymentSuccessDialog(String transactionId) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Transaction ID:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  transactionId,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0CA8E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: const Text('Done'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Show payment error dialog
  Future<void> _showPaymentErrorDialog(String errorMessage) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Failed',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red[800],
                    size: 40,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  errorMessage,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0CA8E1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                  ),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  // Process payment and checkout
  Future<void> _processPayment() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Let user select payment method if they have multiple
    if (paymentMethods.length > 1) {
      final selectedMethod = await _showPaymentMethodDialog();
      if (selectedMethod != null) {
        setState(() {
          selectedPaymentMethod = selectedMethod;
        });
      }
    }
    
    // Show confirmation dialog
    final bool confirmed = await _showPaymentConfirmationDialog();
    if (!confirmed) return;
    
    setState(() {
      isProcessingPayment = true;
    });
    
    try {
      // Calculate total amount
      final double totalAmount = _calculateTotal;
      
      // Process the checkout on the server
      final apiUrl = PaymentService.apiBaseUrl;
      final response = await http.post(
        Uri.parse('$apiUrl/api/shopping-list/${widget.userId}/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'paymentMethodId': selectedPaymentMethod?.id,
        }),
      );
      
      setState(() {
        isProcessingPayment = false;
      });
      
      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200 && responseData['success'] != false) {
        // Show success dialog
        await _showPaymentSuccessDialog(responseData['transactionId'] ?? 'Unknown');
        
        // Clear local cart
        setState(() {
          cartItems = [];
        });
        
        // Clear local storage
        _saveCartToLocalStorage();
      } else {
        // Show error dialog
        await _showPaymentErrorDialog(
          responseData['error'] ?? 'Payment failed. Please try again.'
        );
      }
    } catch (e) {
      print('Error during payment: $e');
      setState(() {
        isProcessingPayment = false;
      });
      
      await _showPaymentErrorDialog('Network error. Please check your connection and try again.');
    }
  }
  
  double get _calculateTotal {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  // Get icon widget based on item name
  Widget _getItemIcon(String itemName) {
    // Map of item names to colors
    final Map<String, Color> itemColors = {
      "Milk": Colors.blue[100]!,
      "Semi skimmed Milk": Colors.blue[100]!,
      "Meat": Colors.red[100]!,
      "Chicken": Colors.yellow[100]!,
      "Eggs": Colors.orange[100]!,
      "Cheese": Colors.yellow[100]!,
      "Apple": Colors.red[100]!,
      "Bread": Colors.brown[100]!,
      "Salad": Colors.green[100]!,
      "Sugar": Colors.grey[100]!,
    };

    // Get color for this item, or use a default
    final Color backgroundColor = itemColors[itemName] ?? const Color(0xFFE1F7FF);

    // Map of item names to icons
    final Map<String, IconData> itemIcons = {
      "Milk": Icons.water_drop,
      "Semi skimmed Milk": Icons.water_drop,
      "Meat": Icons.restaurant_menu,
      "Chicken": Icons.egg,
      "Eggs": Icons.egg_alt,
      "Cheese": Icons.cake,
      "Apple": Icons.apple,
      "Bread": Icons.bakery_dining,
      "Salad": Icons.eco,
      "Sugar": Icons.grain,
    };

    // Get icon for this item, or use a default
    final IconData icon = itemIcons[itemName] ?? Icons.shopping_basket;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: const Color(0xFF0CA8E1),
        size: 30,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              // Header with title and refresh button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 3,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                       
                        Text(
                          'Shopping Cart',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF8BE0FF),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.refresh,
                        color: Color(0xFF0CA8E1),
                      ),
                      onPressed: _loadCartItems,
                      tooltip: 'Refresh Cart',
                    ),
                  ],
                ),
              ),
              
              // Main content
              Expanded(
                child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF0CA8E1),
                      ),
                    )
                  : errorMessage != null && cartItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 70,
                              color: Color(0xFF8BE0FF),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadCartItems,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0CA8E1),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Try Again'),
                            ),
                          ],
                        ),
                      )
                    : cartItems.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE1F7FF),
                                  borderRadius: BorderRadius.circular(60),
                                ),
                                child: const Icon(
                                  Icons.shopping_cart_outlined,
                                  size: 70,
                                  color: Color(0xFF0CA8E1),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                'Your cart is empty',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0CA8E1),
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'Scan products to add them to your cart',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 32),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Start Shopping'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF0CA8E1),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            // Cart items count
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    '${cartItems.length} ${cartItems.length == 1 ? 'item' : 'items'} in cart',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Cart items list
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                itemCount: cartItems.length,
                                itemBuilder: (context, index) {
                                  final item = cartItems[index];
                                  final itemTotalPrice = item.price * item.quantity;
                                  
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE1F7FF),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          // Item icon
                                          _getItemIcon(item.name),
                                          const SizedBox(width: 16),
                                          
                                          // Item details
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  item.category,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                
                                                // Price information
                                                Row(
                                                  children: [
                                                    // Unit price
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Unit Price',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        Text(
                                                          '\$${item.price.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: Color(0xFF0CA8E1),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    
                                                    const SizedBox(width: 24),
                                                    
                                                    // Total price
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                          'Total',
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            color: Colors.grey,
                                                          ),
                                                        ),
                                                        Text(
                                                          '\$${itemTotalPrice.toStringAsFixed(2)}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 14,
                                                            color: Color(0xFF0CA8E1),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          
                                          // Quantity controls
                                          Column(
                                            children: [
                                              // Remove button
                                              IconButton(
                                                icon: const Icon(Icons.delete_outline, color: Color.fromARGB(255, 234, 85, 85)),
                                                onPressed: () => _removeItem(item),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                              ),
                                              const SizedBox(height: 12),
                                              
                                              // Quantity controls
                                              Row(
                                                children: [
                                                  // Decrease quantity
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: Colors.red[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.remove, size: 16),
                                                      padding: EdgeInsets.zero,
                                                      color: Colors.red,
                                                      onPressed: () => _updateQuantity(item, item.quantity - 1),
                                                    ),
                                                  ),
                                                  
                                                  // Quantity display
                                                  Container(
                                                    width: 30,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '${item.quantity}',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  
                                                  // Increase quantity
                                                  Container(
                                                    width: 28,
                                                    height: 28,
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: IconButton(
                                                      icon: const Icon(Icons.add, size: 16),
                                                      padding: EdgeInsets.zero,
                                                      color: Colors.green,
                                                      onPressed: () => _updateQuantity(item, item.quantity + 1),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              ),
              
              // Cart summary and checkout
              if (cartItems.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Payment method display
                        if (selectedPaymentMethod != null)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_getCardIcon(selectedPaymentMethod!.brand)),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${selectedPaymentMethod!.brand.toUpperCase()} •••• ${selectedPaymentMethod!.last4}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                TextButton(
                                  onPressed: () async {
                                    final method = await _showPaymentMethodDialog();
                                    if (method != null) {
                                      setState(() {
                                        selectedPaymentMethod = method;
                                      });
                                    }
                                  },
                                  child: const Text('Change'),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        
                        // Order summary
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F7FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '\$${_calculateTotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0CA8E1),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Checkout button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: isProcessingPayment ? null : _processPayment,
                            icon: isProcessingPayment 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.shopping_cart_checkout),
                            label: Text(
                              isProcessingPayment ? 'Processing...' : 'Checkout',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CA8E1),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Continue shopping button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8BE0FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(
                                    Icons.arrow_back,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Continue Shopping',
                                  style: TextStyle(
                                    color: Color(0xFF8BE0FF),
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

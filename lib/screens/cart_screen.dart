import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Product> cartItems = [];
  bool isLoading = true;
  String? errorMessage;
  final int userId = 1; // Replace with actual user ID from authentication
  
  @override
  void initState() {
    super.initState();
    _loadCartItems();
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
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.0.126:5000';
      final response = await http.get(
        Uri.parse('$apiUrl/api/cart/$userId'),
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
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.0.126:5000';
      final response = await http.put(
        Uri.parse('$apiUrl/api/cart/$userId/item/${product.id}'),
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
          SnackBar(
            content: Text('Failed to update quantity on server. Will retry later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
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
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.0.126:5000';
      final response = await http.delete(
        Uri.parse('$apiUrl/api/cart/$userId/item/${product.id}'),
      );
      
      if (response.statusCode == 200) {
        print('Removed item from server');
      } else {
        print('Failed to remove item from server: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove item on server. Will retry later.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('Error removing item: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error. Changes saved locally.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
  
  Future<void> _checkout() async {
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      isLoading = true;
    });
    
    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.0.126:5000';
      final response = await http.post(
        Uri.parse('$apiUrl/api/cart/$userId/checkout'),
      );
      
      if (response.statusCode == 200) {
        // Clear local cart
        setState(() {
          cartItems = [];
          isLoading = false;
        });
        
        // Clear local storage
        _saveCartToLocalStorage();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Checkout successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Checkout failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error during checkout: $e');
      setState(() {
        isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error during checkout. Please try again when online.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  double get _calculateTotal {
    return cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        backgroundColor: const Color(0xFF0CA8E1),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCartItems,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null && cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 60,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadCartItems,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0CA8E1),
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
                          Image.asset(
                            'assets/images/empty_cart.png',
                            height: 120,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.shopping_cart_outlined,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Your cart is empty',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Scan products to add them to your cart',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0CA8E1),
                            ),
                            child: const Text('Start Shopping'),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // Cart items list
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Product image placeholder
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(
                                            Icons.shopping_bag_outlined,
                                            size: 40,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      
                                      // Product details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
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
                                            Text(
                                              '\$${item.price.toStringAsFixed(2)}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: Theme.of(context).primaryColor,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            
                                            // Quantity controls
                                            Row(
                                              children: [
                                                Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.all(color: Colors.grey[300]!),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      // Decrease quantity
                                                      InkWell(
                                                        onTap: () => _updateQuantity(item, item.quantity - 1),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          child: const Icon(Icons.remove, size: 16),
                                                        ),
                                                      ),
                                                      
                                                      // Quantity display
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 12),
                                                        child: Text(
                                                          '${item.quantity}',
                                                          style: const TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      
                                                      // Increase quantity
                                                      InkWell(
                                                        onTap: () => _updateQuantity(item, item.quantity + 1),
                                                        child: Container(
                                                          padding: const EdgeInsets.all(4),
                                                          child: const Icon(Icons.add, size: 16),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                
                                                const Spacer(),
                                                
                                                // Remove item button
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                  onPressed: () => _removeItem(item),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Order summary
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '\$${_calculateTotal.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0CA8E1),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  // Checkout button
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _checkout,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF0CA8E1),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Checkout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
    );
  }
}
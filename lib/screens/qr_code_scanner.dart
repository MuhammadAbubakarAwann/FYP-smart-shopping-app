import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Define a Product model to match your backend structure
class Product {
  final int id;
  final String name;
  final String category;
  final double price;
  final String qrCode;
  final String status;
  
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.qrCode,
    required this.status,
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
    };
  }
}

class QRScannerPopup extends StatefulWidget {
  final Function(Product) onProductScanned;
  
  const QRScannerPopup({
    Key? key, 
    required this.onProductScanned,
  }) : super(key: key);

  @override
  State<QRScannerPopup> createState() => _QRScannerPopupState();
}

class _QRScannerPopupState extends State<QRScannerPopup> with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  String? errorMessage;
  bool showSuccess = false;
  bool isErrorCooldown = false;
  DateTime? lastErrorTime;
  bool isProcessing = false;
  final int userId = 1; // Replace with actual user ID from authentication
  
  // Animation controller for scanner animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ),
    );
    
    _animationController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    controller.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDetection(BarcodeCapture capture) async {
    if (!isScanning || isErrorCooldown || isProcessing) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty || barcodes[0].rawValue == null) return;
    
    final String scannedData = barcodes[0].rawValue!;
    print("QR Code detected: $scannedData");
    
    setState(() {
      isProcessing = true;
    });
    
    try {
      // First, try to parse the scanned data as JSON
      // This handles the case where the QR code contains the full product data
      Product? product;
      String qrCodeIdentifier = scannedData;
      
      try {
        final Map<String, dynamic> jsonData = json.decode(scannedData);
        
        // Check if this looks like a product object
        if (jsonData.containsKey('id') && jsonData.containsKey('name') && jsonData.containsKey('qr_code')) {
          product = Product.fromJson(jsonData);
          qrCodeIdentifier = product.qrCode;
          print("Parsed product from QR JSON: ${product.name}");
        }
      } catch (e) {
        // Not JSON, treat as plain QR code identifier
        print("QR code is not JSON, using as identifier: $qrCodeIdentifier");
      }
      
      // If we couldn't parse a product from the QR code, fetch it from the backend
      if (product == null) {
        product = await _fetchProductByQRCode(qrCodeIdentifier);
        
        if (product == null) {
          _showError("Product not found");
          return;
        }
      }
      
      // Check if product is already in someone's cart
      if (product.status == "CARTED") {
        _showError("This product is already in someone's cart");
        return;
      }
      
      if (product.status == "SOLD") {
        _showError("This product has already been sold");
        return;
      }
      
      // Add product to cart and update status
      final success = await _addToCart(product);
      
      if (success) {
        setState(() {
          isScanning = false;
          showSuccess = true;
          errorMessage = null;
        });
        
        // Log the product details
        print('Product added to cart: ${product.toJson()}');
        
        // Show success message and close after delay
        Future.delayed(const Duration(seconds: 1), () {
          widget.onProductScanned(product!);
          Navigator.of(context).pop();
        });
      } else {
        _showError("Failed to add product to cart");
      }
    } catch (e) {
      print("Error processing QR code: $e");
      _showError("Error: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }
  
  Future<Product?> _fetchProductByQRCode(String qrCode) async {
    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.7.57:5000';
      print("Fetching product from: $apiUrl/api/items/qr/$qrCode");
      
      final response = await http.get(
        Uri.parse('$apiUrl/api/items/qr/$qrCode'),
      );

      print("Responseeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee status: ${response.statusCode}");
      print("Responseeeeeeeeeeeeeeeeeeeeeeee body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      throw e;
    }
  }

  Future<bool> _addToCart(Product product) async {
    try {
      final apiUrl = dotenv.env['API_URL'] ?? 'http://192.168.7.57:5000';
      print("product id:::::::::::::::: ${product.id}");
     
      final response = await http.post(
        Uri.parse('$apiUrl/api/shopping-list/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'productId': product.id,
          'quantity': 1,
        }),
      );
      
      print("Add to cart response: ${response.statusCode}");
      print("Response body: ${response.body}");
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding to cart: $e');
      return false;
    }
  }
  
  void _showError(String message) {
    // Check if we're in cooldown period (3 seconds between errors)
    final now = DateTime.now();
    if (lastErrorTime != null) {
      final difference = now.difference(lastErrorTime!);
      if (difference.inSeconds < 3) {
        return; // Skip showing error during cooldown
      }
    }
    
    setState(() {
      errorMessage = message;
      isErrorCooldown = true;
      lastErrorTime = now;
    });
    
    // Clear error message after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          errorMessage = null;
          // Add a small additional cooldown after error disappears
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) {
              setState(() {
                isErrorCooldown = false;
              });
            }
          });
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.width * 0.95,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with title and close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Scan Product QR Code",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  iconSize: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Scanner area
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Scanner
                    MobileScanner(
                      controller: controller,
                      onDetect: _handleDetection,
                    ),
                    
                    // Animated scan line
                    AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Positioned(
                          top: 20 + (_animation.value * (MediaQuery.of(context).size.width * 0.6)),
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 2,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.primary.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    
                    // Instruction text
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Position QR code in center",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    
                    // Processing overlay
                    if (isProcessing && !showSuccess && errorMessage == null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Processing...",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Error message overlay
                    if (errorMessage != null)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 80,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                errorMessage!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Success overlay
                    if (showSuccess)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 80,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "Added to Cart!",
                                style: TextStyle(
                                  color: Colors.white,
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
    );
  }
}
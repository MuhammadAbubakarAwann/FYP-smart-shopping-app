import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Define a Product model to match your backend structure
class Product {
  final int id;
  final String name;
  final double price;
  
  Product({
    required this.id,
    required this.name,
    required this.price,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'] != null ? json['price'].toDouble() : 0.0,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
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

  void _handleDetection(BarcodeCapture capture) {
    if (!isScanning || isErrorCooldown) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes[0].rawValue != null) {
      final String code = barcodes[0].rawValue!;
      
      try {
        // Try to parse the QR code as JSON
        final Map<String, dynamic> productData = jsonDecode(code);
        
        // Validate that this is a product QR code
        if (productData.containsKey('id') && productData.containsKey('name')) {
          final Product product = Product.fromJson(productData);
          
          setState(() {
            isScanning = false;
            showSuccess = true;
            errorMessage = null;
          });
          
          // Log the product details
          print('Product scanned: ${product.toJson()}');
          
          // Show success message and close after delay
          Future.delayed(const Duration(seconds: 1), () {
            widget.onProductScanned(product);
            Navigator.of(context).pop();
          });
        } else {
          _showError("Invalid product QR code");
        }
      } catch (e) {
        _showError("Invalid QR code format");
      }
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
                    
                    // Error message overlay - now matching success style
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
                                "Product Found!",
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


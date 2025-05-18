import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/cart_screen.dart';
import '../services/shopping_list_service.dart';
import '../components/items_overlay.dart';
import 'qr_code_scanner.dart';

class ARNavigationScreen extends StatefulWidget {
  const ARNavigationScreen({Key? key}) : super(key: key);

  @override
  _ARNavigationScreenState createState() => _ARNavigationScreenState();
}

class _ARNavigationScreenState extends State<ARNavigationScreen> {
  List<Map<String, dynamic>> shoppingList = [];
  bool showMap = false;
  bool isLoading = true;
  bool isBlueBackground = true;

  @override
  void initState() {
    super.initState();
    fetchShoppingList();
  }

  Future<void> fetchShoppingList() async {
    setState(() {
      isLoading = true;
    });

    final list = await ShoppingListService.getShoppingList();

    if (mounted) {
      setState(() {
        shoppingList = list;
        isLoading = false;
      });
    }
  }

  void toggleBackground() {
    setState(() {
      isBlueBackground = !isBlueBackground;
    });
  }

  // Method to open QR scanner popup
  void _openQRScanner() {
    showDialog(
      context: context,
      builder: (context) => QRScannerPopup(
        onProductScanned: (product) {
          // Create the item data
          final newItem = {
            "id": product.id.toString(),
            "name": product.name,
            "quantity": 1,
            "inCart": true // Set to true by default when scanned
          };

          // First update the UI immediately
          setState(() {
            // Check if item already exists in the list
            final existingIndex =
                shoppingList.indexWhere((item) => item['id'] == newItem['id']);
            if (existingIndex >= 0) {
              // Update existing item
              shoppingList[existingIndex]['quantity'] =
                  (shoppingList[existingIndex]['quantity'] as int) +
                      (newItem['quantity'] as int);
              shoppingList[existingIndex]['inCart'] = newItem['inCart'];
            } else {
              // Add new item
              shoppingList.add(newItem);
            }
          });

          // Then update storage
          ShoppingListService.updateStatus(newItem);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product scanned: ${product.name}'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
  }

  // Show items overlay
  void _showItemsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsOverlay(
        onItemAdded: (Map<String, dynamic> newItem) {
          // Immediately update the UI with the new item
          setState(() {
            // Check if item already exists in the list
            final existingIndex =
                shoppingList.indexWhere((item) => item['id'] == newItem['id']);
            if (existingIndex >= 0) {
              // Update existing item
              shoppingList[existingIndex]['quantity'] =
                  (shoppingList[existingIndex]['quantity'] as int) +
                      (newItem['quantity'] as int);
              shoppingList[existingIndex]['inCart'] = newItem['inCart'];
            } else {
              // Add new item
              shoppingList.add(newItem);
            }
          });
        },
      ),
      isScrollControlled: true,
    );

    // Refresh the list after overlay is closed to ensure everything is in sync
    fetchShoppingList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: isBlueBackground ? const Color(0xFF8BE0FF) : Colors.white,
        child: SafeArea(
          child: Stack(
            children: [
              // Top navigation bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      // User profile icon
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.grey),
                      ),
                      const SizedBox(width: 10),

                      // Navigation button with arrow
                      Expanded(
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0CA8E1),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 4),
                                child: Container(
                                  width: 43,
                                  height: 43,
                                  decoration: const BoxDecoration(
                                    color: Color.fromARGB(255, 8, 120, 163),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_upward,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              // End of Aisle text
                              const Text(
                                'End of Aisle 4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: GestureDetector(
                                  onTap: toggleBackground,
                                  child: Container(
                                    width: 43,
                                    height: 43,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isBlueBackground
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      color: const Color(0xFF0CA8E1),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Cart button
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => CartScreen()),
                          ).then((_) {
                            // This runs when you pop back from CartScreen
                            fetchShoppingList();
                          });
                        },
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Center(
                            child: Text(
                              'cart',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Main content area
              Positioned.fill(
                top: 70,
                child: Center(
                  child: isBlueBackground
                      ? Image.asset(
                          'assets/store_map.png',
                          fit: BoxFit.contain,
                        )
                      : const Center(
                          child: Text(
                            'AR Navigation Will Go here',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),

              // Light blue section behind the item card
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 120, // Adjust height as needed
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F7FF),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Small visible part of the map
                      SizedBox(
                        height: 40,
                        child: Center(
                          child: Image.asset(
                            'assets/images/store_map.png',
                            height: 40,
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                      ),

                      // Blue dot indicator
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0CA8E1),
                          shape: BoxShape.circle,
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),

              // Bottom card for item
              Positioned(
                bottom: 70,
                left: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 20.0),
                    child: Row(
                      children: [
                        // Item icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.shopping_basket,
                            color: Color(0xFF0CA8E1),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Item details
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              'Milk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF0CA8E1),
                              ),
                            ),
                            Text(
                              'End of Aisle 4',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Question mark
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: const Center(
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Got it button - Now opens QR scanner
                        GestureDetector(
                          onTap: _openQRScanner,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: const Color(0xFF0CA8E1)),
                            ),
                            child: const Text(
                              'Got it',
                              style: TextStyle(
                                color: Color(0xFF0CA8E1),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Bottom navigation
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Row(
                  children: [
                    // Item count
                    Row(
                      children: [
                        const Icon(Icons.list, color: Colors.grey, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${shoppingList.length} ${shoppingList.length == 1 ? 'item' : 'items'} in list',
                          style: const TextStyle(
                              color: Color.fromRGBO(158, 158, 158, 1)),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Add More button (using the provided styling)
                    TextButton(
                      onPressed: () => _showItemsOverlay(context),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        padding: EdgeInsets.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF8BE0FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 18,
                              weight: 900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add More',
                            style: TextStyle(
                              color: Color(0xFF8BE0FF),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

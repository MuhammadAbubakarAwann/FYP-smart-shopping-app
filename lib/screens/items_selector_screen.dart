import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/items_overlay.dart';
import 'qr_code_scanner.dart';
import 'qr_generator.dart';
import 'ar_navigation_screen.dart';

class ItemsSelectorScreen extends StatefulWidget {
  const ItemsSelectorScreen({super.key});

  @override
  _ItemsSelectorScreenState createState() => _ItemsSelectorScreenState();
}

class _ItemsSelectorScreenState extends State<ItemsSelectorScreen> {
  List<Map<String, dynamic>> shoppingList = [];
  bool showMap = false;

  @override
  void initState() {
    super.initState();
    fetchShoppingList();
  }

  Future<void> fetchShoppingList() async {
    try {
      final response = await http.get(
        Uri.parse('http://172.20.65.214:5000/api/shopping-list/1'),
      );

      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);
        setState(() {
          shoppingList = decodedJson
              .expand((list) => list["items"])
              .map((item) => {
                    "id": item["id"].toString(),
                    "name": item["product"]["name"].toString(),
                    "quantity": item["quantity"] ?? 1,
                  })
              .toList();
        });
      }
    } catch (e) {
      // If API fails, use sample data for UI demonstration
      setState(() {
        shoppingList = [
          {"id": "1", "name": "Semi skimmed Milk", "quantity": 1},
          {"id": "2", "name": "Meat", "quantity": 1},
          {"id": "3", "name": "Chicken", "quantity": 1},
          {"id": "4", "name": "Eggs", "quantity": 1},
          {"id": "5", "name": "Cheese", "quantity": 1},
          {"id": "6", "name": "Apple", "quantity": 1},
          {"id": "7", "name": "Bread", "quantity": 1},
          {"id": "8", "name": "Salad", "quantity": 1},
          {"id": "9", "name": "Sugar", "quantity": 1},
        ];
      });
    }
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return; // Prevent negative quantity

    try {
      final response = await http.put(
        Uri.parse('http://172.20.65.214:5000/api/shopping-list/$itemId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"quantity": newQuantity}),
      );

      if (response.statusCode == 200) {
        setState(() {
          shoppingList = shoppingList.map((item) {
            if (item["id"] == itemId) {
              return {
                "id": item["id"],
                "name": item["name"],
                "quantity": newQuantity
              };
            }
            return item;
          }).toList();
        });
      }
    } catch (e) {
      // Handle locally if API fails
      setState(() {
        shoppingList = shoppingList.map((item) {
          if (item["id"] == itemId) {
            return {
              "id": item["id"],
              "name": item["name"],
              "quantity": newQuantity
            };
          }
          return item;
        }).toList();
      });
    }
  }

  Future<void> removeItemFromShoppingList(String itemId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://172.20.65.214:5000/api/shopping-list/$itemId'),
      );

      if (response.statusCode == 200) {
        setState(() {
          shoppingList.removeWhere((item) => item["id"] == itemId);
        });
      }
    } catch (e) {
      // Handle locally if API fails
      setState(() {
        shoppingList.removeWhere((item) => item["id"] == itemId);
      });
    }
  }

  void _showItemsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ItemsOverlay(),
      isScrollControlled: true,
    );
    fetchShoppingList();
  }

  // Method to open QR scanner popup
  void _openQRScanner() {
    showDialog(
      context: context,
      builder: (context) => QRScannerPopup(
        onProductScanned: (product) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product scanned: ${product.name}'),
              backgroundColor: Colors.green,
            ),
          );

          print('Product details:');
          print('ID: ${product.id}');
          print('Name: ${product.name}');
          print('Price: \$${product.price.toStringAsFixed(2)}');
        },
      ),
    );
  }

  // Get icon widget based on item name
  Widget _getItemIcon(String itemName) {
    // Map of item names to colors
    final Map<String, Color> itemColors = {
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
    final Color backgroundColor = itemColors[itemName] ?? Colors.blue[100]!;

    // Map of item names to icons
    final Map<String, IconData> itemIcons = {
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        color: Color(0xFF0CA8E1),
        size: 24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Header
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
              child: SafeArea(
                bottom: false,
                child: Text(
                  'Shopping List',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8BE0FF),
                  ),
                ),
              ),
            ),

            // Shopping list
            Expanded(
              child: shoppingList.isEmpty
                  ? Center(
                      child: Text(
                        'No items in your shopping list.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: shoppingList.length,
                      itemBuilder: (context, index) {
                        final item = shoppingList[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE1F7FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Item icon and name
                              Expanded(
                                child: ListTile(
                                  leading: _getItemIcon(item['name']),
                                  title: Text(
                                    item['name'],
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                ),
                              ),

                              // Quantity controls
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Decrease quantity button
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
                                      onPressed: () {
                                        int newQuantity = item['quantity'] - 1;
                                        if (newQuantity > 0) {
                                          updateQuantity(
                                              item['id'], newQuantity);
                                        } else {
                                          removeItemFromShoppingList(
                                              item['id']);
                                        }
                                      },
                                    ),
                                  ),

                                  // Quantity display
                                  Container(
                                    width: 30,
                                    alignment: Alignment.center,
                                    child: Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  // Increase quantity button
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
                                      onPressed: () {
                                        updateQuantity(
                                            item['id'], item['quantity'] + 1);
                                      },
                                    ),
                                  ),
                                ],
                              ),

                              // Remove button
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  removeItemFromShoppingList(item['id']);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Bottom buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Start Navigating button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ARNavigationScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Start Navigating'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0CA8E1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Show Map and Add Item buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Show Map button with the specified design
                      TextButton(
                        onPressed: () {
                          setState(() {
                            showMap = !showMap;
                          });
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          padding: EdgeInsets.zero,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Show Map',
                              style: TextStyle(
                                color: Color(0xFF8BE0FF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF8BE0FF),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(6),
                              child: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Add Item button with the specified design
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
                              'Add item',
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

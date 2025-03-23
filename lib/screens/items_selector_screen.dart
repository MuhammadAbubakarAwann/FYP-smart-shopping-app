import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../components/items_overlay.dart';
import 'qr_code_scanner.dart';
import 'qr_generator.dart';

class ItemsSelectorScreen extends StatefulWidget {
  const ItemsSelectorScreen({super.key});

  @override
  _ItemsSelectorScreenState createState() => _ItemsSelectorScreenState();
}

class _ItemsSelectorScreenState extends State<ItemsSelectorScreen> {
  List<Map<String, dynamic>> shoppingList = [];

  @override
  void initState() {
    super.initState();
    fetchShoppingList();
  }

  Future<void> fetchShoppingList() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.5:5000/api/shopping-list/1'),
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
  }

  Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) return; // Prevent negative quantity

    final response = await http.put(
      Uri.parse('http://192.168.100.5:5000/api/shopping-list/$itemId'),
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
  }

  Future<void> removeItemFromShoppingList(String itemId) async {
    final response = await http.delete(
      Uri.parse('http://192.168.100.5:5000/api/shopping-list/$itemId'),
    );

    if (response.statusCode == 200) {
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
          // Handle the scanned product
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Product scanned: ${product.name}'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Log the product details
          print('Product details:');
          print('ID: ${product.id}');
          print('Name: ${product.name}');
          print('Price: \$${product.price.toStringAsFixed(2)}');
          
          // Here you would add the product to the cart
          // For now, we're just logging the details
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Selector'),
        actions: [
          // Add QR Scanner button in the app bar
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _openQRScanner,
            tooltip: 'Scan Product QR Code',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemsOverlay(context),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Add a prominent QR scanner button at the top
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ElevatedButton.icon(
                  onPressed: _openQRScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Scan Product QR Code'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const QRCodeGenerator()),
                    );
                  },
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Create Test QR Codes'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: shoppingList.isEmpty
                ? const Center(child: Text('No items in your shopping list.'))
                : ListView.builder(
                    itemCount: shoppingList.length,
                    itemBuilder: (context, index) {
                      final item = shoppingList[index];
                      return ListTile(
                        title: Text(item['name']),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Decrease quantity button
                            IconButton(
                              icon:
                                  const Icon(Icons.remove_circle, color: Colors.red),
                              onPressed: () {
                                int newQuantity = item['quantity'] - 1;
                                if (newQuantity > 0) {
                                  updateQuantity(item['id'], newQuantity);
                                } else {
                                  removeItemFromShoppingList(item['id']);
                                }
                              },
                            ),
                            // Quantity Display
                            Text('${item['quantity']}',
                                style: const TextStyle(fontSize: 18)),
                            // Increase quantity button
                            IconButton(
                              icon: const Icon(Icons.add_circle, color: Colors.green),
                              onPressed: () {
                                updateQuantity(item['id'], item['quantity'] + 1);
                              },
                            ),
                            // Cross button to delete item
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
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
        ],
      ),
    );
  }
}


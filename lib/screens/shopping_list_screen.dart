import 'package:flutter/material.dart';
import '../services/shopping_list_service.dart';
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
  bool isLoading = true;

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

  // Fixed to update UI immediately
  Future<void> updateQuantity(String itemId, int newQuantity) async {
    // First update local state for immediate UI feedback
    setState(() {
      final itemIndex = shoppingList.indexWhere((item) => item['id'] == itemId);
      if (itemIndex >= 0) {
        if (newQuantity > 0) {
          shoppingList[itemIndex]['quantity'] = newQuantity;
        } else {
          shoppingList.removeAt(itemIndex);
        }
      }
    });
    
    // Then update storage
    if (newQuantity > 0) {
      await ShoppingListService.updateQuantity(itemId, newQuantity);
    } else {
      await ShoppingListService.removeItem(itemId);
    }
  }

  // Fixed to update UI immediately
  Future<void> toggleItemInCart(String itemId) async {
    // First update local state for immediate UI feedback
    setState(() {
      final itemIndex = shoppingList.indexWhere((item) => item['id'] == itemId);
      if (itemIndex >= 0) {
        shoppingList[itemIndex]['inCart'] = !(shoppingList[itemIndex]['inCart'] ?? false);
      }
    });
    
    // Then update storage
    await ShoppingListService.toggleItemInCart(itemId);
  }

  // Fixed to update UI immediately
  Future<void> removeItemFromShoppingList(String itemId) async {
    // First update local state for immediate UI feedback
    setState(() {
      shoppingList.removeWhere((item) => item['id'] == itemId);
    });
    
    // Then update storage
    await ShoppingListService.removeItem(itemId);
  }

  Future<void> clearShoppingList() async {
    // Show confirmation dialog
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Shopping List'),
        content: const Text('Are you sure you want to clear your entire shopping list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;
    
    if (confirm) {
      // First update local state for immediate UI feedback
      setState(() {
        shoppingList = [];
      });
      
      // Then update storage
      await ShoppingListService.clearShoppingList();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shopping list cleared'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // Replace the _showItemsOverlay method with this updated version
  void _showItemsOverlay(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ItemsOverlay(
        onItemAdded: (Map<String, dynamic> newItem) {
          // Immediately update the UI with the new item
          setState(() {
            // Check if item already exists in the list
            final existingIndex = shoppingList.indexWhere((item) => item['id'] == newItem['id']);
            if (existingIndex >= 0) {
              // Update existing item
              shoppingList[existingIndex]['quantity'] = 
                  (shoppingList[existingIndex]['quantity'] as int) + (newItem['quantity'] as int);
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

  // Replace the _openQRScanner method with this updated version
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
            "inCart": true  // Set to true by default when scanned
          };
          
          // First update the UI immediately
          setState(() {
            // Check if item already exists in the list
            final existingIndex = shoppingList.indexWhere((item) => item['id'] == newItem['id']);
            if (existingIndex >= 0) {
              // Update existing item
              shoppingList[existingIndex]['quantity'] = 
                  (shoppingList[existingIndex]['quantity'] as int) + (newItem['quantity'] as int);
              shoppingList[existingIndex]['inCart'] = newItem['inCart'];
            } else {
              // Add new item
              shoppingList.add(newItem);
            }
          });
          
          // Then update storage
          ShoppingListService.addItem(newItem);
          
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

  // Method to open QR generator
  void _openQRGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRCodeGenerator()),
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
        color: const Color(0xFF0CA8E1),
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
            // Header with QR code icons
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Shopping List',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF8BE0FF),
                      ),
                    ),
                    // Add QR code icons and clear button
                    Row(
                      children: [
                        // Clear All button
                        TextButton.icon(
                          onPressed: shoppingList.isEmpty ? null : clearShoppingList,
                          icon: const Icon(
                            Icons.delete_sweep,
                            color: Color(0xFF0CA8E1),
                            size: 20,
                          ),
                          label: const Text(
                            'Clear All',
                            style: TextStyle(
                              color: Color(0xFF0CA8E1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            foregroundColor: shoppingList.isEmpty 
                                ? Colors.grey 
                                : const Color(0xFF0CA8E1),
                          ),
                        ),
                        // QR Scanner icon
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code_scanner,
                            color: Color(0xFF0CA8E1),
                          ),
                          onPressed: _openQRScanner,
                          tooltip: 'Scan Product QR Code',
                        ),
                        // QR Generator icon
                        IconButton(
                          icon: const Icon(
                            Icons.qr_code,
                            color: Color(0xFF0CA8E1),
                          ),
                          onPressed: _openQRGenerator,
                          tooltip: 'Create QR Codes',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Shopping list
            Expanded(
              child: isLoading 
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0CA8E1)))
                : shoppingList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_basket_outlined,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No items in your shopping list.',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => _showItemsOverlay(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Items'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF0CA8E1),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: shoppingList.length,
                      itemBuilder: (context, index) {
                        final item = shoppingList[index];
                        final bool inCart = item['inCart'] ?? false;
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: inCart 
                              ? const Color(0xFFE1FFE8) // Light green for items in cart
                              : const Color(0xFFE1F7FF), // Original color for items not in cart
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              // Checkbox to mark item as in cart
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: InkWell(
                                  onTap: () => toggleItemInCart(item['id']),
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: inCart ? const Color(0xFF0CA8E1) : Colors.white,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: const Color(0xFF0CA8E1),
                                        width: 2,
                                      ),
                                    ),
                                    child: inCart
                                        ? const Icon(
                                            Icons.check,
                                            size: 18,
                                            color: Colors.white,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              
                              // Item icon and name
                              Expanded(
                                child: ListTile(
                                  leading: _getItemIcon(item['name']),
                                  title: Text(
                                    item['name'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.black87,
                                      decoration: inCart ? TextDecoration.lineThrough : null,
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
                                        updateQuantity(item['id'], newQuantity);
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
                                        updateQuantity(item['id'], item['quantity'] + 1);
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
                      onPressed: shoppingList.isEmpty 
                        ? null 
                        : () {
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
                        disabledBackgroundColor: Colors.grey[300],
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

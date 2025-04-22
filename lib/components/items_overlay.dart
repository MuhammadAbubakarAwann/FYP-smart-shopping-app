import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/config_service.dart';
import '../services/shopping_list_service.dart';
import '../services/user_service.dart';

// Update the ItemsOverlay class to include a callback for when an item is added
class ItemsOverlay extends StatefulWidget {
  final Function(Map<String, dynamic>)? onItemAdded;
  
  const ItemsOverlay({
    super.key,
    this.onItemAdded,
  });

  @override
  _ItemsOverlayState createState() => _ItemsOverlayState();
}

class _ItemsOverlayState extends State<ItemsOverlay> {
  List<Map<String, String>> recentItems = []; // Recent items list
  List<Map<String, String>> searchResults = []; // Search results list
  bool showRecentItemsOverlay = false;
  TextEditingController searchController = TextEditingController();
  bool isLoading = true;
  late int userId; // Will be set from UserService

  @override
  void initState() {
    super.initState();
    
    // Get the user ID from UserService
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userService = Provider.of<UserService>(context, listen: false);
      if (userService.currentUser != null && 
          userService.currentUser!.additionalData.containsKey('userId')) {
        userId = userService.currentUser!.additionalData['userId'];
        print('Using user ID: $userId from UserService in ItemsOverlay');
      } else {
        // Fallback to default if not available
        userId = 1;
        print('UserService user ID not found in ItemsOverlay, using default: $userId');
      }
      
      // Now that we have the userId, fetch recent items
      fetchRecentItems();
    });
  }

  Future<void> fetchRecentItems() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      final response = await http.get(Uri.parse('${configService.apiBaseUrl}/api/items'));

      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);
        setState(() {
          recentItems = decodedJson.map((item) {
            return {
              "id": item["id"].toString(),
              "name": item["name"].toString(),
            };
          }).toList();
          searchResults = recentItems;
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching recent items: $e");
      // Fallback to sample data if API fails
      setState(() {
        recentItems = [
          {"id": "1", "name": "Semi skimmed Milk"},
          {"id": "2", "name": "Meat"},
          {"id": "3", "name": "Chicken"},
          {"id": "4", "name": "Eggs"},
          {"id": "5", "name": "Cheese"},
          {"id": "6", "name": "Apple"},
          {"id": "7", "name": "Bread"},
          {"id": "8", "name": "Salad"},
          {"id": "9", "name": "Sugar"},
        ];
        searchResults = recentItems;
        isLoading = false;
      });
    }
  }

  Future<void> searchItems(String query) async {
    setState(() {
      isLoading = true;
    });
    
    if (query.isEmpty) {
      setState(() {
        searchResults = recentItems;
        isLoading = false;
      });
      return;
    }

    try {
      // Search from API
      final response = await http.get(Uri.parse('${configService.apiBaseUrl}/api/items?q=$query'));
      
      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);
        setState(() {
          searchResults = decodedJson.map((item) {
            return {
              "id": item["id"].toString(),
              "name": item["name"].toString(),
            };
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error searching items: $e");
      // Fallback to local filtering if API fails
      setState(() {
        searchResults = recentItems.where((item) {
          return item["name"]!.toLowerCase().contains(query.toLowerCase());
        }).toList();
        isLoading = false;
      });
    }
  }

  void showRecentItems() {
    setState(() {
      showRecentItemsOverlay = true;
      searchResults = recentItems;
    });
  }

  void hideRecentItems() {
    setState(() {
      showRecentItemsOverlay = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                offset: Offset(0, -1),
                blurRadius: 4,
              ),
            ],
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: const Icon(Icons.search,
                          color: Colors.grey, size: 32),
                    ),
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: searchItems,
                        onTap: showRecentItems,
                        decoration: InputDecoration(
                          hintText: 'Search',
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFF8BE0FF), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                                color: Color(0xFF8BE0FF), width: 2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(top: 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F9F9),
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(30)),
                  ),
                  child: Stack(
                    children: [
                      isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Color(0xFF0CA8E1)))
                        : ListView(
                          children: [
                            _buildCategorySection('Top up', [
                              _ItemCard(
                                icon: '🍎', 
                                label: 'Fruits',
                                onTap: () => _addItemToShoppingList("6", "Apple", true),
                              ),
                              _ItemCard(
                                icon: '🏠', 
                                label: 'Sugar',
                                onTap: () => _addItemToShoppingList("9", "Sugar", true),
                              ),
                              _ItemCard(
                                icon: '🥗', 
                                label: 'Salad',
                                onTap: () => _addItemToShoppingList("8", "Salad", true),
                              ),
                            ]),
                            const SizedBox(height: 20),
                            _buildCategorySection('Bread and dairy', [
                              _ItemCard(
                                icon: '🥛', 
                                label: 'Milk',
                                onTap: () => _addItemToShoppingList("1", "Semi skimmed Milk", true),
                              ),
                              _ItemCard(
                                icon: '🍞', 
                                label: 'Bread',
                                onTap: () => _addItemToShoppingList("7", "Bread", true),
                              ),
                              _ItemCard(
                                icon: '🧀', 
                                label: 'Cheese',
                                onTap: () => _addItemToShoppingList("5", "Cheese", true),
                              ),
                            ]),
                            const SizedBox(height: 45),
                          ],
                        ),
                      
                      // Cancel button properly positioned at the bottom right
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
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
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                  weight: 900,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF8BE0FF),
                                  fontSize: 20,
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
        if (showRecentItemsOverlay)
          Positioned(
            top: 100,
            left: 16,
            right: 16,
            child: _RecentItemsOverlay(
              items: searchResults,
              onClose: hideRecentItems,
              onItemAdded: () {
                // Refresh the parent screen when an item is added
                Navigator.pop(context);
              },
              onItemAddedWithData: widget.onItemAdded,
              userId: userId, // Pass the user ID to the overlay
              isLoading: isLoading,
            ),
          ),
      ],
    );
  }

  // Update the _addItemToShoppingList method in _ItemsOverlayState
  Future<void> _addItemToShoppingList(String itemId, String itemName, bool inCart) async {
    // Create the item data
    final newItem = {
      "id": itemId,
      "name": itemName,
      "quantity": 1,
      "inCart": inCart
    };
    
    // Add to local storage shopping list
    await ShoppingListService.addItem(newItem);
    
    // Notify parent component about the new item
    if (widget.onItemAdded != null) {
      widget.onItemAdded!(newItem);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $itemName to shopping list'),
        backgroundColor: Colors.green,
      ),
    );
    
    // Close the overlay
    Navigator.pop(context);
  }

  Widget _buildCategorySection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Sarala',
              fontSize: 22,
              color: Color(0xFF616161),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: items,
            ),
          ),
        ],
      ),
    );
  }
}

// Update the _RecentItemsOverlay class to include a callback for when an item is added
class _RecentItemsOverlay extends StatelessWidget {
  final List<Map<String, String>> items;
  final VoidCallback onClose;
  final VoidCallback onItemAdded;
  final Function(Map<String, dynamic>)? onItemAddedWithData;
  final int userId; // Add user ID parameter
  final bool isLoading;

  const _RecentItemsOverlay({
    required this.items, 
    required this.onClose,
    required this.onItemAdded,
    required this.userId, // Require user ID
    this.onItemAddedWithData,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 5,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        height: 250,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Recent Items",
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: onClose),
              ],
            ),
            Expanded(
              child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0CA8E1)))
                : items.isEmpty
                  ? const Center(
                      child: Text("No items found"),
                    )
                  : ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          leading: const Icon(Icons.shopping_cart),
                          title: Text(items[index]['name'] ?? 'Unknown Item'),
                          trailing: IconButton(
                            icon: const Icon(Icons.add_circle, color: Color(0xFF0CA8E1)),
                            onPressed: () {
                              addItemToShoppingList(
                                items[index]['id']!,
                                items[index]['name']!,
                                false, // Set inCart to true by default
                              );
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the addItemToShoppingList method in _RecentItemsOverlay
  Future<void> addItemToShoppingList(String itemId, String itemName, bool inCart) async {
    // Create the item data
    final newItem = {
      "id": itemId,
      "name": itemName,
      "quantity": 1,
      "inCart": inCart
    };
    
    // Add to local storage shopping list
    await ShoppingListService.addItem(newItem);
    
    // Notify parent component about the new item
    if (onItemAddedWithData != null) {
      onItemAddedWithData!(newItem);
    }
    
    print("Item added locally for user $userId: $itemName");
    onItemAdded();
  }
}

class _ItemCard extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;
  
  const _ItemCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 101,
        height: 136,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Color.fromARGB(159, 139, 224, 255),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 71,
              height: 71,
              decoration: const BoxDecoration(
                color: Color.fromARGB(189, 255, 255, 255),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Sarala',
                fontSize: 20,
                color: Color(0xFF0CA8E1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

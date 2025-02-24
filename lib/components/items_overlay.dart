import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ItemsOverlay extends StatefulWidget {
  const ItemsOverlay({super.key});

  @override
  _ItemsOverlayState createState() => _ItemsOverlayState();
}

class _ItemsOverlayState extends State<ItemsOverlay> {
  List<Map<String, String>> recentItems = []; // Recent items list
  List<Map<String, String>> searchResults = []; // Search results list
  bool showRecentItemsOverlay = false;
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchRecentItems();
  }

  Future<void> fetchRecentItems() async {
    final response =
        await http.get(Uri.parse('http://172.20.40.137:5000/api/items'));
    print("Response Status: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode == 200) {
      List<dynamic> decodedJson = jsonDecode(response.body);
      setState(() {
        recentItems = decodedJson.map((item) {
          return {
            "id": item["id"].toString(),
            "name": item["name"].toString(),
          };
        }).toList();
      });
    }
  }

  Future<void> searchItems(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = recentItems;
      });
      return;
    }

    // Filter items locally based on the search query
    setState(() {
      searchResults = recentItems.where((item) {
        return item["name"]!.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });

    // If no items match locally, try fetching from the server
    if (searchResults.isEmpty) {
      final response = await http
          .get(Uri.parse('http://172.20.40.137:5000/api/items?q=$query'));
      if (response.statusCode == 200) {
        List<dynamic> decodedJson = jsonDecode(response.body);
        setState(() {
          searchResults = decodedJson.map((item) {
            return {
              "id": item["id"].toString(),
              "name": item["name"].toString(),
            };
          }).toList();
        });
      }
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
                  child: ListView(
                    children: [
                      _buildCategorySection('Top up', [
                        _ItemCard(icon: '🍎', label: 'Fruits'),
                        _ItemCard(icon: '🏠', label: 'Sugar'),
                        _ItemCard(icon: '🥗', label: 'Fruits'),
                      ]),
                      const SizedBox(height: 20),
                      _buildCategorySection('Bread and dairy', [
                        _ItemCard(icon: '🥛', label: 'Milk'),
                        _ItemCard(icon: '🍞', label: 'Bakery'),
                        _ItemCard(icon: '🧀', label: 'Cheese'),
                      ]),
                      const SizedBox(height: 45),
                      Padding(
                        padding: const EdgeInsets.only(right: 16, bottom: 16),
                        child: Align(
                          alignment: Alignment.bottomRight,
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
            ),
          ),
      ],
    );
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

class _RecentItemsOverlay extends StatelessWidget {
  final List<Map<String, String>> items;
  final VoidCallback onClose;

  const _RecentItemsOverlay({required this.items, required this.onClose});

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
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading:
                        const Icon(Icons.shopping_cart), // Placeholder icon
                    title: Text(items[index]['name'] ?? 'Unknown Item'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_circle, color: Color(0xFF0CA8E1)),
                      onPressed: () {
                        print("Item added: ${items[index]['name']}");
                        // Call function to add item to the shopping list
                        addItemToShoppingList(items[index]['name']!);
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

  void addItemToShoppingList(String itemName) {
    print("Adding $itemName to shopping list...");
    // Implement shopping list addition logic here (e.g., updating state or API call)
  }
}

class _ItemCard extends StatelessWidget {
  final String icon;
  final String label;
  const _ItemCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}

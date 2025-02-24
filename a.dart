
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ItemsOverlay extends StatefulWidget {
  const ItemsOverlay({super.key});

  @override
  _ItemsOverlayState createState() => _ItemsOverlayState();
}

class _ItemsOverlayState extends State<ItemsOverlay> {
  List<dynamic> _items = []; // Holds search results
  List<dynamic> _recentItems = []; // Holds top 5 recent items
  bool _showRecentItems = false; // Controls recent items visibility
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRecentItems();
  }

  // Fetch top 5 recently added items
  Future<void> _fetchRecentItems() async {
    final response = await http.get(Uri.parse('http://172.20.40.137:5000/api/items'));

    if (response.statusCode == 200) {
      setState(() {
        _recentItems = jsonDecode(response.body);
      });
    }
  }

  // Fetch matching items as the user types
  Future<void> _searchItems(String query) async {
    if (query.isEmpty) {
      setState(() {
        _items.clear();
      });
      return;
    }

    final response = await http.get(Uri.parse('http://172.20.40.137:5000/api/items?query=$query'));

    if (response.statusCode == 200) {
      setState(() {
        _items = jsonDecode(response.body);
      });
    }
  }

  // Add item to shopping list
  void _addItemToShoppingList(dynamic item) {
    print("Added to shopping list: ${item['name']}");
    // You can implement actual shopping list logic here
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
                const Icon(Icons.search, color: Colors.grey, size: 32),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF8BE0FF), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF8BE0FF), width: 2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (query) => _searchItems(query),
                    onTap: () {
                      setState(() {
                        _showRecentItems = true;
                      });
                    },
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

          // Recent Items (Dropdown)
          if (_showRecentItems && _recentItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _recentItems.map((item) {
                  return ListTile(
                    title: Text(item['name']),
                    trailing: IconButton(
                      icon: const Icon(Icons.add, color: Colors.blue),
                      onPressed: () => _addItemToShoppingList(item),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Search Results
          Expanded(
            child: Container(
              padding: const EdgeInsets.only(top: 18),
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: _items.isNotEmpty
                  ? ListView.builder(
                      itemCount: _items.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_items[index]['name']),
                          trailing: IconButton(
                            icon: const Icon(Icons.add, color: Colors.blue),
                            onPressed: () => _addItemToShoppingList(_items[index]),
                          ),
                        );
                      },
                    )
                  : const Center(
                      child: Text(
                        "No item match",
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

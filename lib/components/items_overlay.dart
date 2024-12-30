import 'package:flutter/material.dart';

class ItemsOverlay extends StatelessWidget {
  const ItemsOverlay({super.key});

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
                // Search icon outside the search bar
                Container(
                  margin: const EdgeInsets.only(
                      right: 8), // Add spacing between icon and search bar
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search, color: Colors.grey, size: 32),
                ),
                // Search bar
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search',
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color.fromARGB(159, 139, 224, 255),
                            width: 2), // Colored border when not focused
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                            color: Color(0xFF8BE0FF),
                            width: 2), // Colored border when focused
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                // Done button
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                  const SizedBox(height: 20),
                  // Centered and enlarged text below the cards
                  const Center(
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 20, horizontal: 56),
                      child: Text(
                        "Search and Add Items to List",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Sarala',
                          fontSize: 28, // Increased font size
                          color: Color(0xFF616161),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
                          backgroundColor:
                              Colors.transparent,
                          padding: EdgeInsets.zero, 
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(
                                    0xFF8BE0FF), 
                                shape: BoxShape
                                    .rectangle, 
                                borderRadius: BorderRadius.circular(
                                    6), 
                              ),
                              padding: const EdgeInsets.all(
                                  6), 
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 18, 
                                weight: 900, 
                              ),
                            ),
                            const SizedBox(
                                width: 8), 
                           
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

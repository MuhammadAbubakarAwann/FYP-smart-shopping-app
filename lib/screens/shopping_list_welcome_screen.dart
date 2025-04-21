import 'package:flutter/material.dart';
import 'items_selector_screen.dart';
import 'ar_navigation_screen.dart';

class ShoppingListWelcomeScreen extends StatelessWidget {
  const ShoppingListWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 10, top: 41, bottom: 12),
            color: Colors.white,
            alignment: Alignment.centerLeft,
            child: const Text(
              'Shopping List',
              style: TextStyle(
                fontFamily: 'Sarala',
                fontWeight: FontWeight.w700,
                fontSize: 24,
                color: Color(0xFF8BE0FF),
              ),
            ),
          ),
          
          // Main blue container with content
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF0CA8E1),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Center add button
                  Positioned(
                    top: 129, // Adjusted from design to look better
                    child: GestureDetector(
                      onTap: () => _navigateToItemsSelector(context),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 30,
                              color: Color(0xFF8BE0FF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add or search for an item',
                            style: TextStyle(
                              fontFamily: 'Sarala',
                              fontSize: 16,
                              color: Color(0xFF8BE0FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Shopping basket image and items
                  Positioned(
                    top: 336,
                    child: SizedBox(
                      width: 200,
                      height: 230,
                      child: Stack(
                        children: [
                          // Shopping basket
                          Positioned(
                            left: 25,
                            top: 80,
                            child: Opacity(
                              opacity: 0.8,
                              child: Image.asset(
                                'assets/images/shopping-basket.png',
                                width: 148,
                                height: 148,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 148,
                                  height: 148,
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.shopping_basket,
                                    size: 80,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Milk bottle
                          Positioned(
                            right: 10,
                            top: 75,
                            child: Transform.rotate(
                              angle: 2.65, // ~152 degrees
                              child: Opacity(
                                opacity: 0.7,
                                child: Container(
                                  width: 57,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.water_drop,
                                    color: Colors.blue,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Meat
                          Positioned(
                            right: 20,
                            top: 70,
                            child: Transform.rotate(
                              angle: -0.88, // ~-50 degrees
                              child: Opacity(
                                opacity: 0.7,
                                child: Container(
                                  width: 71,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.red[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.restaurant_menu,
                                    color: Colors.redAccent,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Egg
                          Positioned(
                            right: 25,
                            top: 95,
                            child: Opacity(
                              opacity: 0.6,
                              child: Container(
                                width: 25,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.egg,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                          
                          // Broccoli/Vegetable
                          Positioned(
                            left: 34,
                            top: 169,
                            child: Transform.rotate(
                              angle: -1.71, // ~-98 degrees
                              child: Opacity(
                                opacity: 0.7,
                                child: Container(
                                  width: 70,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.eco,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Meat/Steak
                          Positioned(
                            right: 20,
                            top: 163,
                            child: Transform.rotate(
                              angle: -2.33, // ~-133 degrees
                              child: Opacity(
                                opacity: 0.7,
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: Colors.red[200],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lunch_dining,
                                    color: Colors.redAccent,
                                    size: 30,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Fruit
                          Positioned(
                            right: 30,
                            top: 44,
                            child: Transform.rotate(
                              angle: -3.03, // ~-173 degrees
                              child: Opacity(
                                opacity: 0.7,
                                child: Container(
                                  width: 37,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.yellow[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.apple,
                                    color: Colors.orange,
                                    size: 25,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          
                          // Another food item
                          Positioned(
                            left: 72,
                            top: 67,
                            child: Opacity(
                              opacity: 0.7,
                              child: Container(
                                width: 37,
                                height: 37,
                                decoration: BoxDecoration(
                                  color: Colors.brown[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.bakery_dining,
                                  color: Colors.brown,
                                  size: 25,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // "Let's build your basket" text
                  const Positioned(
                    bottom: 111,
                    child: Text(
                      "Let's build your basket",
                      style: TextStyle(
                        fontFamily: 'Sarala',
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        color: Color(0xFF8BE0FF),
                      ),
                    ),
                  ),
                  
                  // Bottom buttons
                  Positioned(
                    bottom: 16,
                    left: 6,
                    right: 6,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Show Map button
                        GestureDetector(
                          onTap: () => _navigateToARNavigation(context),
                          child: Row(
                            children: [
                              const Text(
                                'Show Map',
                                style: TextStyle(
                                  fontFamily: 'Sarala',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF8BE0FF),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8BE0FF),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        // Add item button
                        GestureDetector(
                          onTap: () => _navigateToItemsSelector(context),
                          child: Row(
                            children: [
                              Container(
                                width: 29,
                                height: 29,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8BE0FF),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 15,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Add item',
                                style: TextStyle(
                                  fontFamily: 'Sarala',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF8BE0FF),
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
        ],
      ),
    );
  }

  // Navigate to ItemsSelectorScreen
  void _navigateToItemsSelector(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ItemsSelectorScreen()),
    );
  }

  // Navigate to ARNavigationScreen
  void _navigateToARNavigation(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ARNavigationScreen()),
    );
  }
}

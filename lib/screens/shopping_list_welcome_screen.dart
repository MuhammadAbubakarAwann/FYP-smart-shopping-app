import 'package:flutter/material.dart';
import 'shopping_list_screen.dart';
import 'ar_navigation_screen.dart';

class ShoppingListWelcomeScreen extends StatelessWidget {
  const ShoppingListWelcomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header - matching the ItemsSelectorScreen style
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
                  const Text(
                    'Shopping List',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF8BE0FF),
                    ),
                  ),
                  // You can add QR code icons here if needed, like in ItemsSelectorScreen
                ],
              ),
            ),
          ),
          
          // Main blue container with content - expanded to fill the screen
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFF0CA8E1),
              child: Stack(
                fit: StackFit.expand, // Make sure the stack fills the container
                children: [
                  // Center add button
                  Positioned(
                    top: 129,
                    left: 0,
                    right: 0,
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
                              size: 50,
                              color: Color(0xFF8BE0FF),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Add or search for an item',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF8BE0FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Shopping basket image - using a single image for all items
                  Positioned(
                    top: 336,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Image.asset(
                        'assets/basket.png',
                        width: 220,
                        height: 220,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 200,
                          height: 200,
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
                  
                  // "Let's build your basket" text
                  const Positioned(
                    bottom: 111,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        "Let's build your basket",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 25,
                          color: Color(0xFF8BE0FF),
                        ),
                      ),
                    ),
                  ),
                  
                  // Bottom buttons - matching ItemsSelectorScreen style and position
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Show Map button
                        TextButton(
                          onPressed: () => _navigateToARNavigation(context),
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
                        
                        // Add Item button
                        TextButton(
                          onPressed: () => _navigateToItemsSelector(context),
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

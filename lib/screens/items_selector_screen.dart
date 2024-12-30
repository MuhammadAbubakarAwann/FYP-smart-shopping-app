// lib/screens/items_selector_screen.dart
import 'package:flutter/material.dart';
import '../components/items_overlay.dart';

class ItemsSelectorScreen extends StatelessWidget {
  const ItemsSelectorScreen({super.key});

  void _showItemsOverlay(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const ItemsOverlay(),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Selector'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showItemsOverlay(context),
        child: const Icon(Icons.add),
      ),
      body: const Center(
        child: Text('Your main content goes here'),
      ),
    );
  }
}

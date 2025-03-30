import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ShoppingListService {
  static const String _storageKey = 'shopping_list';
  static const String _recentItemsKey = 'recent_items';
  static const String _itemsKey = 'all_items';
  
  // Get shopping list from local storage
  static Future<List<Map<String, dynamic>>> getShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final String? shoppingListJson = prefs.getString(_storageKey);
    
    if (shoppingListJson == null) {
      return [];
    }
    
    List<dynamic> decodedList = jsonDecode(shoppingListJson);
    return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  // Save shopping list to local storage
  static Future<void> saveShoppingList(List<Map<String, dynamic>> shoppingList) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(shoppingList);
    await prefs.setString(_storageKey, encodedList);
  }
  
  // Add item to shopping list
  static Future<void> addItem(Map<String, dynamic> item) async {
    final List<Map<String, dynamic>> currentList = await getShoppingList();
    
    // Check if item already exists
    final existingItemIndex = currentList.indexWhere((i) => i['id'] == item['id']);
    
    if (existingItemIndex >= 0) {
      // Update quantity if item exists
      currentList[existingItemIndex]['quantity'] = 
          (currentList[existingItemIndex]['quantity'] as int) + (item['quantity'] as int);
    } else {
      // Add new item
      currentList.add(item);
    }
    
    await saveShoppingList(currentList);
  }
  
  // Remove item from shopping list
  static Future<void> removeItem(String itemId) async {
    final List<Map<String, dynamic>> currentList = await getShoppingList();
    currentList.removeWhere((item) => item['id'] == itemId);
    await saveShoppingList(currentList);
  }
  
  // Update item quantity
  static Future<void> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity < 1) {
      await removeItem(itemId);
      return;
    }
    
    final List<Map<String, dynamic>> currentList = await getShoppingList();
    final itemIndex = currentList.indexWhere((item) => item['id'] == itemId);
    
    if (itemIndex >= 0) {
      currentList[itemIndex]['quantity'] = newQuantity;
      await saveShoppingList(currentList);
    }
  }
  
  // Clear shopping list
  static Future<void> clearShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}


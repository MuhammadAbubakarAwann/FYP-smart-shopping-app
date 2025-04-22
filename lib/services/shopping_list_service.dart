import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/user_service.dart';

class ShoppingListService {
  static const String _baseStorageKey = 'shopping_list';
  static const String _recentItemsKey = 'recent_items';
  static const String _itemsKey = 'all_items';
  
  // Get user-specific storage key
  static Future<String> _getUserStorageKey() async {
    // Get current user ID from UserService
    final userService = UserService();
    final userId = userService.currentUser?.additionalData['userId'];
    
    // If user is logged in, use user-specific key
    if (userId != null) {
      return '${_baseStorageKey}_$userId';
    }
    
    // Otherwise use default key
    return _baseStorageKey;
  }
  
  // Get shopping list from local storage
  static Future<List<Map<String, dynamic>>> getShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getUserStorageKey();
    final String? shoppingListJson = prefs.getString(storageKey);
    
    if (shoppingListJson == null) {
      return [];
    }
    
    List<dynamic> decodedList = jsonDecode(shoppingListJson);
    return decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  // Save shopping list to local storage
  static Future<void> saveShoppingList(List<Map<String, dynamic>> shoppingList) async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getUserStorageKey();
    final String encodedList = jsonEncode(shoppingList);
    await prefs.setString(storageKey, encodedList);
  }
  
  // Add item to shopping list
  static Future<List<Map<String, dynamic>>> addItem(Map<String, dynamic> item) async {
    final List<Map<String, dynamic>> currentList = await getShoppingList();
    
    // Check if item already exists
    final existingItemIndex = currentList.indexWhere((i) => i['id'] == item['id']);
    
    if (existingItemIndex >= 0) {
      // Update quantity if item exists
      currentList[existingItemIndex]['quantity'] = 
          (currentList[existingItemIndex]['quantity'] as int) + (item['quantity'] as int);
      
      // Update inCart status if provided
      if (item.containsKey('inCart')) {
        currentList[existingItemIndex]['inCart'] = item['inCart'];
      }
    } else {
      // Add new item with inCart flag
      if (!item.containsKey('inCart')) {
        item['inCart'] = false;
      }
      currentList.add(item);
    }
    
    // Save the updated list
    await saveShoppingList(currentList);
    
    // Return the updated list so the UI can be updated immediately
    return currentList;
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
  
  // Toggle item's inCart status
  static Future<void> toggleItemInCart(String itemId) async {
    final List<Map<String, dynamic>> currentList = await getShoppingList();
    final itemIndex = currentList.indexWhere((item) => item['id'] == itemId);
    
    if (itemIndex >= 0) {
      // Toggle the inCart status
      currentList[itemIndex]['inCart'] = !(currentList[itemIndex]['inCart'] ?? false);
      await saveShoppingList(currentList);
    }
  }
  
  // Clear shopping list
  static Future<void> clearShoppingList() async {
    final prefs = await SharedPreferences.getInstance();
    final storageKey = await _getUserStorageKey();
    await prefs.remove(storageKey);
  }
}

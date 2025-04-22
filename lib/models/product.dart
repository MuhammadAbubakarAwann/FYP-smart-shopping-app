class Product {
  final int id;
  final String name;
  final double price;
  final String? description;
  final String? imageUrl;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.description,
    this.imageUrl,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      price: json['price'] is String 
          ? double.tryParse(json['price']) ?? 0.0 
          : (json['price'] ?? 0.0).toDouble(),
      description: json['description'],
      imageUrl: json['imageUrl'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
    };
  }
}

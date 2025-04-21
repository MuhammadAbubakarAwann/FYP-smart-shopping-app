// Model class for payment methods
class PaymentMethod {
  final int id;
  final int userId;
  final String last4;
  final String brand;
  final int expiryMonth;
  final int expiryYear;
  final String country;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentMethod({
    required this.id,
    required this.userId,
    required this.last4,
    required this.brand,
    required this.expiryMonth,
    required this.expiryYear,
    required this.country,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a PaymentMethod from a JSON map
  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      userId: json['userId'] is int ? json['userId'] : int.parse(json['userId'].toString()),
      last4: json['last4'] ?? '',
      brand: json['brand'] ?? '',
      expiryMonth: json['expiryMonth'] is int ? json['expiryMonth'] : int.parse(json['expiryMonth'].toString()),
      expiryYear: json['expiryYear'] is int ? json['expiryYear'] : int.parse(json['expiryYear'].toString()),
      country: json['country'] ?? '',
      isDefault: json['isDefault'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  // Convert PaymentMethod to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'last4': last4,
      'brand': brand,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'country': country,
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create a copy of this PaymentMethod with modified fields
  PaymentMethod copyWith({
    int? id,
    int? userId,
    String? last4,
    String? brand,
    int? expiryMonth,
    int? expiryYear,
    String? country,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      last4: last4 ?? this.last4,
      brand: brand ?? this.brand,
      expiryMonth: expiryMonth ?? this.expiryMonth,
      expiryYear: expiryYear ?? this.expiryYear,
      country: country ?? this.country,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

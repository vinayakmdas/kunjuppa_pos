class Product {
  final String id;
  final String name;
  final String sku;
  final String? barcode;
  final String category;
  final double sellingPrice;
  final double? costPrice;
  final int stockQuantity;
  final String unit; // 'piece' | 'kg' | 'litre' | 'packet' | 'box' | 'meter' | 'dozen'
  final String? description;
  final String createdAt;
  final String updatedAt;
  final bool isDeleted;
  final String? deletedAt;

  Product({
    required this.id,
    required this.name,
    required this.sku,
    this.barcode,
    required this.category,
    required this.sellingPrice,
    this.costPrice,
    required this.stockQuantity,
    required this.unit,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.deletedAt,
  });

  Product copyWith({
    String? id,
    String? name,
    String? sku,
    String? barcode,
    String? category,
    double? sellingPrice,
    double? costPrice,
    int? stockQuantity,
    String? unit,
    String? description,
    String? createdAt,
    String? updatedAt,
    bool? isDeleted,
    String? deletedAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      costPrice: costPrice ?? this.costPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'category': category,
        'sellingPrice': sellingPrice,
        'costPrice': costPrice,
        'stockQuantity': stockQuantity,
        'unit': unit,
        'description': description,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String?,
        category: json['category'] as String,
        sellingPrice: (json['sellingPrice'] as num).toDouble(),
        costPrice: json['costPrice'] != null ? (json['costPrice'] as num).toDouble() : null,
        stockQuantity: json['stockQuantity'] as int,
        unit: json['unit'] as String,
        description: json['description'] as String?,
        createdAt: json['createdAt'] as String,
        updatedAt: json['updatedAt'] as String,
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] as String?,
      );
}

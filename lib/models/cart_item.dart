class CartItem {
  final String productId;
  final String name;
  final String sku;
  final String? barcode;
  final double originalPrice;
  final double unitPrice;
  final bool isCustomPrice;
  final int quantity;
  final int maxStock;
  final String unit;
  final double lineTotal;

  CartItem({
    required this.productId,
    required this.name,
    required this.sku,
    this.barcode,
    required this.originalPrice,
    required this.unitPrice,
    this.isCustomPrice = false,
    required this.quantity,
    required this.maxStock,
    required this.unit,
    required this.lineTotal,
  });

  CartItem copyWith({
    String? productId,
    String? name,
    String? sku,
    String? barcode,
    double? originalPrice,
    double? unitPrice,
    bool? isCustomPrice,
    int? quantity,
    int? maxStock,
    String? unit,
    double? lineTotal,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      originalPrice: originalPrice ?? this.originalPrice,
      unitPrice: unitPrice ?? this.unitPrice,
      isCustomPrice: isCustomPrice ?? this.isCustomPrice,
      quantity: quantity ?? this.quantity,
      maxStock: maxStock ?? this.maxStock,
      unit: unit ?? this.unit,
      lineTotal: lineTotal ?? this.lineTotal,
    );
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'sku': sku,
        'barcode': barcode,
        'originalPrice': originalPrice,
        'unitPrice': unitPrice,
        'isCustomPrice': isCustomPrice,
        'quantity': quantity,
        'maxStock': maxStock,
        'unit': unit,
        'lineTotal': lineTotal,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        productId: json['productId'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String,
        barcode: json['barcode'] as String?,
        originalPrice: (json['originalPrice'] as num).toDouble(),
        unitPrice: (json['unitPrice'] as num).toDouble(),
        isCustomPrice: json['isCustomPrice'] as bool? ?? false,
        quantity: json['quantity'] as int,
        maxStock: json['maxStock'] as int,
        unit: json['unit'] as String,
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

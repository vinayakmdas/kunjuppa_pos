import 'customer.dart';

class OrderItem {
  final String productId;
  final String productName;
  final String sku;
  final double unitPrice;
  final double? originalPrice;
  final bool isCustomPrice;
  final int quantity;
  final String unit;
  final double lineTotal;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.unitPrice,
    this.originalPrice,
    this.isCustomPrice = false,
    required this.quantity,
    required this.unit,
    required this.lineTotal,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'sku': sku,
        'unitPrice': unitPrice,
        'originalPrice': originalPrice,
        'isCustomPrice': isCustomPrice,
        'quantity': quantity,
        'unit': unit,
        'lineTotal': lineTotal,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        sku: json['sku'] as String,
        unitPrice: (json['unitPrice'] as num).toDouble(),
        originalPrice: json['originalPrice'] != null ? (json['originalPrice'] as num).toDouble() : null,
        isCustomPrice: json['isCustomPrice'] as bool? ?? false,
        quantity: json['quantity'] as int,
        unit: json['unit'] as String,
        lineTotal: (json['lineTotal'] as num).toDouble(),
      );
}

class Order {
  final String id;
  final String orderNumber; // e.g. ORD-2026-0001
  final String createdAt;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final Customer? customerSnapshot;
  final List<OrderItem> items;
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod; // 'cash' | 'upi' | 'card'
  final String paymentStatus; // 'paid' | 'pending'
  final String orderStatus; // 'completed' | 'cancelled'
  final bool isDeleted;
  final String? deletedAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.createdAt,
    this.customerId,
    required this.customerName,
    this.customerPhone,
    this.customerSnapshot,
    required this.items,
    required this.itemCount,
    required this.totalQuantity,
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.grandTotal,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.isDeleted,
    this.deletedAt,
  });

  Order copyWith({
    String? id,
    String? orderNumber,
    String? createdAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    Customer? customerSnapshot,
    List<OrderItem>? items,
    int? itemCount,
    int? totalQuantity,
    double? subtotal,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? grandTotal,
    String? paymentMethod,
    String? paymentStatus,
    String? orderStatus,
    bool? isDeleted,
    String? deletedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      createdAt: createdAt ?? this.createdAt,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerSnapshot: customerSnapshot ?? this.customerSnapshot,
      items: items ?? this.items,
      itemCount: itemCount ?? this.itemCount,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      subtotal: subtotal ?? this.subtotal,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      discountAmount: discountAmount ?? this.discountAmount,
      grandTotal: grandTotal ?? this.grandTotal,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      orderStatus: orderStatus ?? this.orderStatus,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'orderNumber': orderNumber,
        'createdAt': createdAt,
        'customerId': customerId,
        'customerName': customerName,
        'customerPhone': customerPhone,
        'customerSnapshot': customerSnapshot?.toJson(),
        'items': items.map((i) => i.toJson()).toList(),
        'itemCount': itemCount,
        'totalQuantity': totalQuantity,
        'subtotal': subtotal,
        'discountType': discountType,
        'discountValue': discountValue,
        'discountAmount': discountAmount,
        'grandTotal': grandTotal,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'orderStatus': orderStatus,
        'isDeleted': isDeleted,
        'deletedAt': deletedAt,
      };

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        id: json['id'] as String,
        orderNumber: json['orderNumber'] as String,
        createdAt: json['createdAt'] as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        customerSnapshot: json['customerSnapshot'] != null
            ? Customer.fromJson(json['customerSnapshot'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List).map((i) => OrderItem.fromJson(i as Map<String, dynamic>)).toList(),
        itemCount: json['itemCount'] as int,
        totalQuantity: json['totalQuantity'] as int,
        subtotal: (json['subtotal'] as num).toDouble(),
        discountType: json['discountType'] as String,
        discountValue: (json['discountValue'] as num).toDouble(),
        discountAmount: (json['discountAmount'] as num).toDouble(),
        grandTotal: (json['grandTotal'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        paymentStatus: json['paymentStatus'] as String,
        orderStatus: json['orderStatus'] as String,
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] as String?,
      );
}

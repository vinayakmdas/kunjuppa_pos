import 'cart_item.dart';
import 'customer.dart';

class PendingOrder {
  final String id;
  final int queueNumber;
  final String label; // e.g. "Bill #1"
  final String createdAt;
  final String? customerId;
  final String customerName;
  final String? customerPhone;
  final Customer? customerSnapshot;
  final List<CartItem> items;
  final int itemCount;
  final int totalQuantity;
  final double subtotal;
  final String discountType; // 'percentage' | 'fixed'
  final double discountValue;
  final double discountAmount;
  final double grandTotal;
  final String paymentMethod; // 'cash' | 'upi' | 'card'
  final bool isPrinted;
  final String? printedAt;

  PendingOrder({
    required this.id,
    required this.queueNumber,
    required this.label,
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
    required this.isPrinted,
    this.printedAt,
  });

  PendingOrder copyWith({
    String? id,
    int? queueNumber,
    String? label,
    String? createdAt,
    String? customerId,
    String? customerName,
    String? customerPhone,
    Customer? customerSnapshot,
    List<CartItem>? items,
    int? itemCount,
    int? totalQuantity,
    double? subtotal,
    String? discountType,
    double? discountValue,
    double? discountAmount,
    double? grandTotal,
    String? paymentMethod,
    bool? isPrinted,
    String? printedAt,
  }) {
    return PendingOrder(
      id: id ?? this.id,
      queueNumber: queueNumber ?? this.queueNumber,
      label: label ?? this.label,
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
      isPrinted: isPrinted ?? this.isPrinted,
      printedAt: printedAt ?? this.printedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'queueNumber': queueNumber,
        'label': label,
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
        'isPrinted': isPrinted,
        'printedAt': printedAt,
      };

  factory PendingOrder.fromJson(Map<String, dynamic> json) => PendingOrder(
        id: json['id'] as String,
        queueNumber: json['queueNumber'] as int,
        label: json['label'] as String,
        createdAt: json['createdAt'] as String,
        customerId: json['customerId'] as String?,
        customerName: json['customerName'] as String,
        customerPhone: json['customerPhone'] as String?,
        customerSnapshot: json['customerSnapshot'] != null
            ? Customer.fromJson(json['customerSnapshot'] as Map<String, dynamic>)
            : null,
        items: (json['items'] as List).map((i) => CartItem.fromJson(i as Map<String, dynamic>)).toList(),
        itemCount: json['itemCount'] as int,
        totalQuantity: json['totalQuantity'] as int,
        subtotal: (json['subtotal'] as num).toDouble(),
        discountType: json['discountType'] as String,
        discountValue: (json['discountValue'] as num).toDouble(),
        discountAmount: (json['discountAmount'] as num).toDouble(),
        grandTotal: (json['grandTotal'] as num).toDouble(),
        paymentMethod: json['paymentMethod'] as String,
        isPrinted: json['isPrinted'] as bool? ?? false,
        printedAt: json['printedAt'] as String?,
      );
}

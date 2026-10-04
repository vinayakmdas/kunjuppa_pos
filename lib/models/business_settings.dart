class BusinessSettings {
  final String businessName;
  final String phone;
  final String address;
  final String email;
  final String? gstin;
  final String currencySymbol;
  final String currencyCode;
  final String receiptWidth; // '58mm' | '80mm'
  final String receiptFooter;
  final int lowStockThreshold;
  final String defaultPaymentMethod; // 'cash' | 'upi' | 'card'

  BusinessSettings({
    required this.businessName,
    required this.phone,
    required this.address,
    required this.email,
    this.gstin,
    required this.currencySymbol,
    required this.currencyCode,
    required this.receiptWidth,
    required this.receiptFooter,
    required this.lowStockThreshold,
    required this.defaultPaymentMethod,
  });

  BusinessSettings copyWith({
    String? businessName,
    String? phone,
    String? address,
    String? email,
    String? gstin,
    String? currencySymbol,
    String? currencyCode,
    String? receiptWidth,
    String? receiptFooter,
    int? lowStockThreshold,
    String? defaultPaymentMethod,
  }) {
    return BusinessSettings(
      businessName: businessName ?? this.businessName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      email: email ?? this.email,
      gstin: gstin ?? this.gstin,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      receiptWidth: receiptWidth ?? this.receiptWidth,
      receiptFooter: receiptFooter ?? this.receiptFooter,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
    );
  }

  Map<String, dynamic> toJson() => {
        'businessName': businessName,
        'phone': phone,
        'address': address,
        'email': email,
        'gstin': gstin,
        'currencySymbol': currencySymbol,
        'currencyCode': currencyCode,
        'receiptWidth': receiptWidth,
        'receiptFooter': receiptFooter,
        'lowStockThreshold': lowStockThreshold,
        'defaultPaymentMethod': defaultPaymentMethod,
      };

  factory BusinessSettings.fromJson(Map<String, dynamic> json) => BusinessSettings(
        businessName: json['businessName'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        email: json['email'] as String,
        gstin: json['gstin'] as String?,
        currencySymbol: json['currencySymbol'] as String,
        currencyCode: json['currencyCode'] as String,
        receiptWidth: json['receiptWidth'] as String? ?? '80mm',
        receiptFooter: json['receiptFooter'] as String,
        lowStockThreshold: json['lowStockThreshold'] as int? ?? 15,
        defaultPaymentMethod: json['defaultPaymentMethod'] as String? ?? 'cash',
      );
}

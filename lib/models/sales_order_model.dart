// file: lib/models/sales_order_model.dart

class SalesOrder {
  final String id;
  final int salesmanId;
  final String dealerId;
  final DateTime estimatedDelivery;
  // Add other fields like items, totalAmount etc. as needed

  SalesOrder({
    required this.id,
    required this.salesmanId,
    required this.dealerId,
    required this.estimatedDelivery,
  });

  factory SalesOrder.fromJson(Map<String, dynamic> json) {
    return SalesOrder(
      id: json['id'],
      salesmanId: json['salesmanId'],
      dealerId: json['dealerId'],
      estimatedDelivery: DateTime.parse(json['estimatedDelivery']),
    );
  }

  Map<String, dynamic> toJson() => {
      'salesmanId': salesmanId,
      'dealerId': dealerId,
      'estimatedDelivery': estimatedDelivery.toIso8601String(),
  };
}
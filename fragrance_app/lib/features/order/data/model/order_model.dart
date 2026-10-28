/// One order the customer placed, as the API sends it.
final class OrderModel {
  final String id;
  final String status;
  final String paymentMethod;
  final double totalAmount;
  final DateTime createdAt;
  final List<OrderItemModel> items;

  /// Where to deliver (receiver, phone and address), if given.
  final String? deliveryDetail;

  const OrderModel({
    required this.id,
    required this.status,
    required this.paymentMethod,
    required this.totalAmount,
    required this.createdAt,
    required this.items,
    this.deliveryDetail,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
    id: json['id'] as String,
    status: json['status'] as String? ?? 'pending',
    paymentMethod: json['paymentMethod'] as String? ?? '',
    totalAmount: (json['totalAmount'] as num? ?? 0).toDouble(),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
        DateTime.now(),
    items: [
      for (final item in (json['items'] as List<dynamic>? ?? []))
        OrderItemModel.fromJson(item as Map<String, dynamic>),
    ],
    deliveryDetail: json['deliveryDetail'] as String?,
  );

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  /// The customer can confirm delivery once it is on its way.
  bool get canConfirmReceived => status == 'shipping' || status == 'delivered';

  String get statusLabel => switch (status) {
    'pending' => 'Waiting for payment',
    'paid' => 'Paid',
    'processing' => 'Preparing',
    'shipping' => 'On the way',
    'delivered' => 'Delivered',
    'received' => 'Received',
    'cancelled' => 'Cancelled',
    'failed' => 'Failed',
    _ => status,
  };

  String get paymentLabel => switch (paymentMethod) {
    'aba_payway' => 'ABA PayWay',
    'wallet' => 'Wallet',
    _ => paymentMethod,
  };
}

final class OrderItemModel {
  final String? productId;
  final String name;
  final double price;
  final int quantity;

  const OrderItemModel({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) => OrderItemModel(
    productId: json['productId'] as String?,
    name: json['name'] as String? ?? '',
    price: (json['price'] as num? ?? 0).toDouble(),
    quantity: (json['quantity'] as num? ?? 1).toInt(),
  );
}

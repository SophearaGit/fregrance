/// An ABA PayWay payment that was started: open [checkoutUrl] in a web view.
final class PaywayCheckout {
  final String orderId;
  final String tranId;
  final double amount;
  final String checkoutUrl;

  /// PayWay sends the customer here at the end; seeing it means "close the page".
  final String returnUrl;

  const PaywayCheckout({
    required this.orderId,
    required this.tranId,
    required this.amount,
    required this.checkoutUrl,
    required this.returnUrl,
  });

  factory PaywayCheckout.fromJson(Map<String, dynamic> json) => PaywayCheckout(
    orderId: json['orderId'] as String,
    tranId: json['tranId'] as String,
    amount: (json['amount'] as num).toDouble(),
    checkoutUrl: json['checkoutUrl'] as String,
    returnUrl: json['returnUrl'] as String,
  );
}

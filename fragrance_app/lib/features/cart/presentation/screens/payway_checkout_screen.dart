import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../domain/entities/payway_checkout.dart';

/// Shows ABA PayWay's payment page inside the app.
/// Closes itself (returning true) when PayWay sends the customer back.
class PaywayCheckoutScreen extends StatefulWidget {
  const PaywayCheckoutScreen({
    super.key,
    required this.checkout,
    required this.isPaid,
  });

  final PaywayCheckout checkout;

  /// Asks the backend whether the payment arrived. Checked every few seconds,
  /// so the page closes by itself once the customer has paid.
  final Future<bool> Function() isPaid;

  @override
  State<PaywayCheckoutScreen> createState() => _PaywayCheckoutScreenState();
}

class _PaywayCheckoutScreenState extends State<PaywayCheckoutScreen> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _closed = false;
  Timer? _poll;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (value) {
            if (mounted) setState(() => _progress = value);
          },
          onNavigationRequest: (request) {
            // PayWay finished (paid or cancelled): back to the cart.
            if (request.url.startsWith(widget.checkout.returnUrl)) {
              _close(true);
              return NavigationDecision.prevent;
            }
            // Links such as abamobilebank:// need the ABA app; stay here.
            final scheme = Uri.tryParse(request.url)?.scheme ?? '';
            if (scheme != 'http' && scheme != 'https') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'That option needs the ABA Mobile app. '
                    'Try paying by card instead.',
                  ),
                ),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkout.checkoutUrl));

    _poll = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_checking || _closed) return;
      _checking = true;
      final paid = await widget.isPaid();
      _checking = false;
      if (paid) _close(true);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _close(bool finished) {
    if (_closed || !mounted) return;
    _closed = true;
    _poll?.cancel();
    Navigator.of(context).pop(finished);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ABA PayWay'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () => _close(false),
        ),
        bottom: _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(
                  value: _progress / 100,
                  minHeight: 2,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

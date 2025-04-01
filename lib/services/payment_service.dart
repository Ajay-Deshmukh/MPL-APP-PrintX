import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:js' as js;
import 'dart:html' as html;

typedef PaymentCallback = void Function(String paymentId);
typedef PaymentErrorCallback = void Function(String error);

class PaymentService {
  final Razorpay? _razorpay;
  PaymentCallback? onPaymentSuccess;
  PaymentErrorCallback? onPaymentError;

  PaymentService() : _razorpay = kIsWeb ? null : Razorpay() {
    if (!kIsWeb) {
      _razorpay?.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay?.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
      _razorpay?.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    } else {
      _loadRazorpayScript();
    }
  }

  void _loadRazorpayScript() {
    print('Attempting to load Razorpay script...');
    if (html.document.getElementById('razorpay-checkout-js') != null) {
      print('Razorpay script already loaded');
      return;
    }
    
    final script = html.ScriptElement()
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..id = 'razorpay-checkout-js'
      ..type = 'text/javascript'
      ..async = true
      ..onLoad.listen((event) {
        print('Razorpay script loaded successfully');
      })
      ..onError.listen((event) {
        print('Error loading Razorpay script: $event');
      });
    
    html.document.head?.append(script);
  }

  void _handleWebPayment(Map<String, dynamic> options) {
    if (js.context['Razorpay'] == null) {
      print('Waiting for Razorpay to initialize...');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (js.context['Razorpay'] != null) {
          _initializePayment(options);
        } else {
          _handleWebPayment(options);
        }
      });
      return;
    }
    _initializePayment(options);
  }

  void _initializePayment(Map<String, dynamic> options) {
    try {
      print('Initializing payment...');
      js.context['handlePaymentSuccess'] = js.allowInterop((dynamic response) {
        print('Payment success response: ${js.context['JSON'].callMethod('stringify', [response])}');
        if (response != null) {
          onPaymentSuccess?.call(response['razorpay_payment_id']);
        }
      });

      js.context['handlePaymentError'] = js.allowInterop((dynamic error) {
        print('Payment error: ${js.context['JSON'].callMethod('stringify', [error])}');
        onPaymentError?.call("Payment failed: ${error?.toString() ?? 'Unknown error'}");
      });

      final jsOptions = js.JsObject.jsify({
        ...options,
        'handler': js.context['handlePaymentSuccess'],
        'modal': {
          'ondismiss': js.allowInterop(() {
            print('Payment modal dismissed by user');
            onPaymentError?.call("Payment cancelled by user");
          }),
          'escape': false,
          'animation': true
        }
      });

      final razorpay = js.JsObject(js.context['Razorpay'], [jsOptions]);
      razorpay.callMethod('open');
      print('Payment window opened');
    } catch (e, stackTrace) {
      print('Payment initialization error: $e');
      print('Stack trace: $stackTrace');
      onPaymentError?.call("Payment initialization failed: $e");
    }
  }

  void startPayment(double amount, String orderId, {
    PaymentCallback? onSuccess,
    PaymentErrorCallback? onError,
    String? customerName,
    String? customerEmail,
  }) {
    print('Starting payment process...');
    onPaymentSuccess = onSuccess;
    onPaymentError = onError;

    var options = {
      'key': 'rzp_test_dDRfvvt96dpvdw',
      'amount': (amount * 100).toInt(),
      'currency': 'INR',
      'name': 'PrintX',
      'description': 'Order #$orderId',
      'notes': {
        'order_id': orderId
      },
      'prefill': {
        'name': customerName ?? 'Customer',
        'email': customerEmail ?? 'customer@email.com'
      },
      'theme': {
        'color': '#3399cc'
      }
    };
    print('Payment options configured: $options');

    if (kIsWeb) {
      print('Using web payment implementation');
      _handleWebPayment(options);
    } else {
      print('Using mobile payment implementation');
      try {
        _razorpay?.open(options);
      } catch (e) {
        print('Payment initialization error: $e');
        onPaymentError?.call("Payment initialization failed: $e");
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('Mobile payment success: ${response.paymentId}');
    onPaymentSuccess?.call(response.paymentId ?? '');
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('Mobile payment error: ${response.message}, code: ${response.code}');
    onPaymentError?.call(response.message ?? "Payment failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print("External Wallet Selected: ${response.walletName}");
  }

  void dispose() {
    if (!kIsWeb) {
      _razorpay?.clear();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PaymentScreen({super.key, required this.amount, required this.orderId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  void startPayment() async {
    setState(() => _isProcessing = true);

    var options = {
      'key': 'rzp_test_dDRfvvt96dpvdw',
      'amount': (widget.amount * 100).toInt(), // Convert to paise
      'currency': 'INR',
      'name': 'PrintX Xerox Center',
      'description': 'Payment for Order #${widget.orderId}',
      'prefill': {
        'contact': '9876543210', // Fetch dynamically from user profile
        'email': 'user@example.com',
      },
      'theme': {'color': '#3399cc'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error opening payment gateway. Try again.")),
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'paymentStatus': 'Paid',
      'transactionId': response.paymentId, // Store transaction ID
    });

    Provider.of<OrderProvider>(context, listen: false).updatePaymentStatus(widget.orderId, "Paid");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Successful! Order Confirmed.")),
    );

    Navigator.pop(context, true); // Return success status
  }

  void _handlePaymentError(PaymentFailureResponse response) async {
    await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
      'paymentStatus': 'Failed',
    });

    setState(() => _isProcessing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Using External Wallet: ${response.walletName}")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Center(
        child: _isProcessing
            ? CircularProgressIndicator()
            : ElevatedButton(
                onPressed: startPayment,
                child: Text("Pay ₹${widget.amount.toStringAsFixed(2)}"),
              ),
      ),
    );
  }
}

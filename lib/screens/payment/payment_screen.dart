import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/order_provider.dart';
import '../../services/payment_service.dart';  // Add this import
import '../../services/order_service.dart';  // Add this import

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PaymentScreen({super.key, required this.amount, required this.orderId});

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final OrderService _orderService = OrderService();  // Add this
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _paymentService.dispose();
    super.dispose();
  }

  void startPayment() async {  // Make this async
    setState(() => _isProcessing = true);

    try {
      // Verify if order exists in Firestore
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();

      if (!orderDoc.exists) {
        throw Exception('Order not found in database');
      }

      _paymentService.startPayment(
        widget.amount,
        widget.orderId,
        onSuccess: _handlePaymentSuccess,
        onError: _handlePaymentError,
      );
    } catch (e) {
      print('Error starting payment: $e');
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error initializing payment. Please try again.")),
      );
    }
  }

  void _handlePaymentSuccess(String paymentId) async {
    try {
      await _orderService.updateOrderAfterPayment(widget.orderId, paymentId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Successful! Order Confirmed.")),
      );
      Navigator.pop(context, true);
    } catch (e) {
      print("Error updating order after payment: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment successful but order update failed. Please contact support.")),
      );
    }
  }

  void _handlePaymentError(String error) {
    setState(() => _isProcessing = false);
    
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: $error")),
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

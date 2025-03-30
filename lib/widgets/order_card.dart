import 'package:flutter/material.dart';
import '../models/order_model.dart';

class OrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const OrderCard({required this.order, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        title: Text("Order #${order.id}", style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Status: ${order.status}", style: TextStyle(color: Colors.blue)),
            Text("Amount: ₹${order.price}"),
            Text("Payment: ${order.paymentStatus}"),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: Colors.black54),
          onPressed: onTap,
        ),
      ),
    );
  }
}

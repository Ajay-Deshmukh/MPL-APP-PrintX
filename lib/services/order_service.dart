import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CollectionReference ordersCollection = FirebaseFirestore.instance.collection('orders');

  // Place New Order
  Future<void> placeOrder(OrderModel order) async {
    try {
      await _firestore.collection("orders").doc(order.id).set(order.toJson());
    } catch (e) {
      print("Order Error: $e");
    }
  }

  // Fetch User Orders
  Future<List<OrderModel>> fetchOrders(String userId) async {
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection("orders")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => OrderModel.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print("Fetch Orders Error: $e");
      return [];
    }
  }

  // Update Order Status
  Future<void> updateOrderStatus(String orderId, String status) async {
    try {
      await _firestore.collection("orders").doc(orderId).update({"status": status});
    } catch (e) {
      print("Update Order Error: $e");
    }
  }

  // Delete Order
  Future<void> deleteOrder(String orderId) async {
    try {
      await ordersCollection.doc(orderId).delete();
    } catch (e) {
      print("Delete Order Error: $e");
    }
  }

  // Update Payment Status
  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': paymentStatus,
      });
    } catch (e) {
      print("Update Payment Status Error: $e");
    }
  }
}

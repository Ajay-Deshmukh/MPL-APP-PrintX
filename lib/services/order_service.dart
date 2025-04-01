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
      throw e; // Propagate error for handling
    } 
  }

  // Update Order After Payment
  Future<void> updateOrderAfterPayment(String orderId, String paymentId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentStatus': 'Paid',
        'status': 'Confirmed',
        'transactionId': paymentId,
        'updatedAt': Timestamp.now(),
      });
      print('Order updated successfully after payment');
    } catch (e) {
      print("Update Order After Payment Error: $e");
      throw e;
    }
  }

  // Fetch User Orders
  Future<List<OrderModel>> fetchOrders(String userId) async {
    try {
      print('Fetching orders for userId: $userId'); // Debug print
      QuerySnapshot querySnapshot = await _firestore
          .collection("orders")
          .where("userId", isEqualTo: userId)
          .orderBy("createdAt", descending: true)
          .get();

      print('Found ${querySnapshot.docs.length} documents'); // Debug print

      final orders = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Ensure document ID is included
        print('Order data: $data'); // Debug print
        return OrderModel.fromJson(data);
      }).toList();

      print('Parsed ${orders.length} orders'); // Debug print
      return orders;
    } catch (e) {
      print("Fetch Orders Error: $e");
      rethrow; // Throw error for better error handling
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

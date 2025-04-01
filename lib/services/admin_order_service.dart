import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class AdminOrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all orders with pagination
  Future<List<OrderModel>> getAllOrders({
    String? status,
    String? searchOrderId,
    int limit = 10,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('orders')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      if (searchOrderId != null) {
        query = query.where('id', isEqualTo: searchOrderId);
      }

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => OrderModel.fromJson({
        ...doc.data() as Map<String, dynamic>,
        'id': doc.id,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  // Get order statistics
  Future<Map<String, int>> getOrderStatistics() async {
    try {
      final snapshot = await _firestore.collection('orders').get();
      int pending = 0;
      int processing = 0;
      int completed = 0;

      for (var doc in snapshot.docs) {
        String status = doc.data()['status'];
        switch (status) {
          case 'Pending':
            pending++;
            break;
          case 'Processing':
            processing++;
            break;
          case 'Completed':
            completed++;
            break;
        }
      }

      return {
        'pending': pending,
        'processing': processing,
        'completed': completed,
      };
    } catch (e) {
      throw Exception('Failed to fetch order statistics: $e');
    }
  }

  // Update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
    } catch (e) {
      throw Exception('Failed to update order status: $e');
    }
  }

  // Get orders by date range
  Future<List<OrderModel>> getOrdersByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore.collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      return snapshot.docs.map((doc) => OrderModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by date range: $e');
    }
  }
}
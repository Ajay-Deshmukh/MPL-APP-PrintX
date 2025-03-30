import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  List<OrderModel> _orders = [];
  bool _isLoading = false;

  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;

  Future<void> fetchOrders(String userId) async {
  if (_isLoading) return;
  
  _isLoading = true;
  Future.microtask(() => notifyListeners()); // ✅ Delays notifyListeners() to avoid conflict
  
  try {
    List<OrderModel> fetchedOrders = await _orderService.fetchOrders(userId);
    if (fetchedOrders.isNotEmpty && _orders != fetchedOrders) {
      _orders = fetchedOrders;
      Future.microtask(() => notifyListeners()); // ✅ Safe to update
    }
  } catch (e) {
    print("Error fetching orders: $e");
  }

  _isLoading = false;
  Future.microtask(() => notifyListeners()); // ✅ Delays notifyListeners() to avoid build issues
}


  Future<void> placeOrder(OrderModel order) async {
    await _orderService.placeOrder(order);
    _orders = [order, ..._orders]; // Ensures a new list is created
    notifyListeners();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orderService.updateOrderStatus(orderId, status);
    int index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1 && _orders[index].status != status) {
      _orders[index].status = status;
      _orders = List.from(_orders); // Force UI update
      notifyListeners();
    }
  }

  Future<void> deleteOrder(String orderId) async {
    await _orderService.deleteOrder(orderId);
    _orders = _orders.where((order) => order.id != orderId).toList();
    notifyListeners();
  }

  Future<void> updatePaymentStatus(String orderId, String paymentStatus) async {
    await _orderService.updatePaymentStatus(orderId, paymentStatus);
    int index = _orders.indexWhere((order) => order.id == orderId);
    if (index != -1 && _orders[index].paymentStatus != paymentStatus) {
      _orders[index].paymentStatus = paymentStatus;
      _orders = List.from(_orders);
      notifyListeners();
    }
  }
}

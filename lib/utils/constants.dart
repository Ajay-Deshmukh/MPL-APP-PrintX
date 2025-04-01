import 'package:flutter/material.dart';

class AppConstants {
  // 🔹 App Information
  static const String appName = "PrintX";

  // 🔹 Firebase Collections
  static const String usersCollection = "users";
  static const String ordersCollection = "orders";
  static const String paymentsCollection = "payments";

  // 🔹 Order Statuses
  static const String statusPending = "Pending";
  static const String statusCompleted = "Completed";
  static const String statusCancelled = "Cancelled";

  // 🔹 Colors
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.orange;

  // 🔹 API Keys
  static const String razorpayKey = 'rzp_test_51Jw5RwEwGJjPGK'; // Update with your key

  // 🔹 Default Messages
  static const String errorMessage = "Something went wrong. Please try again!";
}

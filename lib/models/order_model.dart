import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  String id;
  String userId;
  String fileUrl;
  int copies;
  bool isColor;
  String status; // Pending, Processing, Completed
  double price;
  Timestamp createdAt;
  List<Map<String, dynamic>> items;
  String paymentStatus; // New field: Pending, Paid, Failed

  OrderModel({
    required this.id,
    required this.userId,
    required this.fileUrl,
    required this.copies,
    required this.isColor,
    required this.status,
    required this.price,
    required this.createdAt,
    required this.items,
    required this.paymentStatus, // Include in constructor
  });

  // Convert OrderModel to JSON (for Firestore)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'fileUrl': fileUrl,
      'copies': copies,
      'isColor': isColor,
      'status': status,
      'price': price,
      'createdAt': createdAt,
      'items': items,
      'paymentStatus': paymentStatus, // Include in JSON
    };
  }

  // Create OrderModel from JSON (from Firestore)
  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'],
      fileUrl: json['fileUrl'],
      copies: json['copies'],
      isColor: json['isColor'],
      status: json['status'],
      price: (json['price'] as num).toDouble(),
      createdAt: json['createdAt'] ?? Timestamp.now(),
      items: List<Map<String, dynamic>>.from(json['items'] ?? []),
      paymentStatus: json['paymentStatus'] ?? "Pending", // Default to Pending
    );
  }
}

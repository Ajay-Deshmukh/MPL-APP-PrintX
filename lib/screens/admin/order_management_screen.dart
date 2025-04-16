import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? TextField(
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search by user email...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value),
            )
          : const Text('Order Management'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('paymentStatus', isEqualTo: 'Paid')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .handleError((error) {
              print('Firestore Error: $error');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Error loading orders. Please check your authentication.'),
                  duration: Duration(seconds: 3),
                ),
              );
              return Stream.empty();
            }),
        builder: (context, snapshot) {
          // Add error handling for auth errors
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      // Trigger a rebuild to retry
                      setState(() {});
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var orders = snapshot.data?.docs ?? [];

          // Filter orders if search query exists
          if (_searchQuery.isNotEmpty) {
            orders = orders.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final userEmail = data['userEmail'] ?? '';
              return userEmail.toLowerCase().contains(_searchQuery.toLowerCase());
            }).toList();
          }

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final order = OrderModel.fromJson(orderData);
              
              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(order.status),
                    child: Text('#${index + 1}'),
                  ),
                  title: Text('Order #${order.id.substring(0, 8)}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Status: ${order.status}'),
                      // Remove Payment status display
                      Text('Amount: ₹${order.price}'),
                      Text('Date: ${_formatDate(order.createdAt)}'),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          _buildDetailRow('User ID', order.userId),
                          _buildDetailRow('Copies', order.copies.toString()),
                          _buildDetailRow('Color Print', order.isColor ? 'Yes' : 'No'),
                          _buildDetailRow('Pages', order.items.first['pages'].toString()),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _updateOrderStatus(context, order.id),
                                icon: const Icon(Icons.update),
                                label: const Text('Update Status'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _launchURL(order.fileUrl),
                                icon: const Icon(Icons.remove_red_eye),
                                label: const Text('View File'),
                              ),
                              // Remove Payment status update button
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(Timestamp date) {
    final DateTime dateTime = date.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  void _updateOrderStatus(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Order Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('Pending'),
              onTap: () => _changeStatus(context, orderId, 'Pending'),
            ),
            ListTile(
              leading: const Icon(Icons.hourglass_empty),
              title: const Text('Processing'),
              onTap: () => _changeStatus(context, orderId, 'Processing'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Completed'),
              onTap: () => _changeStatus(context, orderId, 'Completed'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Cancelled'),
              onTap: () => _changeStatus(context, orderId, 'Cancelled'),
            ),
          ],
        ),
      ),
    );
  }

  void _updatePaymentStatus(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Payment Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.pending),
              title: const Text('Pending'),
              onTap: () => _changePaymentStatus(context, orderId, 'Pending'),
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Paid'),
              onTap: () => _changePaymentStatus(context, orderId, 'Paid'),
            ),
            ListTile(
              leading: const Icon(Icons.cancel),
              title: const Text('Failed'),
              onTap: () => _changePaymentStatus(context, orderId, 'Failed'),
            ),
          ],
        ),
      ),
    );
  }

  void _changeStatus(BuildContext context, String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'status': status});
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update order status')),
      );
    }
  }

  void _changePaymentStatus(BuildContext context, String orderId, String status) async {
    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({'paymentStatus': status});
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment status updated to $status')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update payment status')),
      );
    }
  }

  void _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open file')),
      );
    }
  }
}
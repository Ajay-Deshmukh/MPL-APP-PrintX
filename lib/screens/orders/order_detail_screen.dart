import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';  // Add this import
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';  // Add this import
import 'package:url_launcher/url_launcher.dart';  // Add this import at the top

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Order #${order.id.substring(0, 8)}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              context,
              'Order Status',
              [
                _buildInfoRow('Status', order.status),
                _buildInfoRow('Payment Status', order.paymentStatus),
                _buildInfoRow('Order ID', order.id),  // Replace transactionId with order.id
                _buildInfoRow('Date', _formatDate(order.createdAt)),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Document Details',
              [
                _buildInfoRow('Copies', order.copies.toString()),
                _buildInfoRow('Color Print', order.isColor ? 'Yes' : 'No'),
                _buildInfoRow('Pages', order.items.first['pages']),
              ],
            ),
            const SizedBox(height: 16),
            _buildSection(
              context,
              'Payment Details',
              [
                _buildInfoRow('Amount', '₹${order.price.toStringAsFixed(2)}'),
                _buildInfoRow('Reference ID', order.id),  // Use order.id instead of transactionId
              ],
            ),
            if (order.fileUrl != null) ...[
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Document Preview',
                [
                  ElevatedButton.icon(
                    onPressed: () => _launchURL(order.fileUrl!),
                    icon: const Icon(Icons.remove_red_eye),
                    label: const Text('View Document'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(Timestamp? date) {  // Change DateTime? to Timestamp?
    if (date == null) return 'N/A';
    final DateTime dateTime = date.toDate();
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
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
      print('Error launching URL: $e');
    }
  }
}

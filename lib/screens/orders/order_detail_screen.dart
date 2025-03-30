import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../theme/app_theme.dart';  // Add this import

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 32),
                    _buildInfoRow('Order ID', '#${order.id}'),
                    const SizedBox(height: 12),
                    _buildInfoRow('Status', order.status,
                      valueColor: _getStatusColor(order.status),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Total Amount', '₹${order.price}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Order Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: order.items.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final item = order.items[index];
                  return ListTile(
                    title: Text(
                      item['name'],
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text('Quantity: ${item['quantity']}'),
                    trailing: Text(
                      '₹${item['price']}',
                      style: TextStyle(  // Remove const
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: AppTheme.textColorSecondary),  // Remove const
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.textColorPrimary,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.textColorPrimary;  // Now AppTheme is accessible
    }
  }
}

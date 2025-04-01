import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Profile',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(user?.name ?? 'Admin'),
                    subtitle: Text(user?.email ?? ''),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('System Settings'),
                    onTap: () {
                      // Implement settings
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.security),
                    title: const Text('Change Password'),
                    onTap: () {
                      // Implement password change
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data?.docs ?? [];

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index].data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(user['name']?[0] ?? 'U'),
                ),
                title: Text(user['name'] ?? 'Unknown'),
                subtitle: Text(user['email'] ?? ''),
                trailing: PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('View Details'),
                      onTap: () => _viewUserDetails(context, user),
                    ),
                    PopupMenuItem(
                      child: Text(user['isBlocked'] ? 'Unblock User' : 'Block User'),
                      onTap: () => _toggleUserBlock(users[index].id, user['isBlocked'] ?? false),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _viewUserDetails(BuildContext context, Map<String, dynamic> user) {
    // Implement user details view
  }

  Future<void> _toggleUserBlock(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .update({'isBlocked': !currentStatus});
  }
}
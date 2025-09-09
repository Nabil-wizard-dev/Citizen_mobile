import 'package:flutter/material.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  final String ouvrierId;
  const NotificationsScreen({super.key, required this.ouvrierId});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    notifications = await NotificationService.getNotificationsByOuvrier(
      widget.ouvrierId,
    );
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF1E3A8A),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final notif = notifications[index];
                  return ListTile(
                    leading: Icon(
                      notif.lu
                          ? Icons.notifications_none
                          : Icons.notifications_active,
                      color: notif.lu ? Colors.grey : Colors.blue,
                    ),
                    title: Text(notif.message),
                    subtitle:
                        notif.lu ? const Text('Lue') : const Text('Non lue'),
                  );
                },
              ),
    );
  }
}

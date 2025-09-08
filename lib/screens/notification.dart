import 'package:flutter/material.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Liste exemple de notifications
    final List<NotificationItem> notifications = [
      NotificationItem(
        id: '1',
        title: 'Nouveau message',
        content: 'Marie vous a envoyé un message',
        time: '09:30',
        isRead: false,
        type: NotificationType.message,
      ),
      NotificationItem(
        id: '2',
        title: 'Rappel',
        content: 'Réunion à 14h00',
        time: 'Hier',
        isRead: true,
        type: NotificationType.reminder,
      ),
      NotificationItem(
        id: '3',
        title: 'Mise à jour disponible',
        content: 'Une nouvelle version de l\'application est disponible',
        time: '22 Mars',
        isRead: false,
        type: NotificationType.update,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],

      body: notifications.isEmpty
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Pas de notifications',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      )
          : ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationCard(notification: notification);
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final NotificationItem notification;

  const NotificationCard({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation vers la page correspondante
        navigateToNotificationDetails(context, notification);
      },
      onLongPress: () {
        // Afficher les actions sur appui long
        showNotificationActions(context, notification);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône de la notification
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getNotificationColor(notification.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getNotificationIcon(notification.type),
                  color: _getNotificationColor(notification.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Contenu de la notification
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        Text(
                          notification.time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Indicateur non lu
              if (!notification.isRead)
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(left: 8, top: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void navigateToNotificationDetails(BuildContext context, NotificationItem notification) {
    // Navigation vers l'écran correspondant
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationDetailPage(notification: notification),
      ),
    );
  }

  void showNotificationActions(BuildContext context, NotificationItem notification) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(!notification.isRead ? Icons.mark_email_read : Icons.mark_email_unread),
                title: Text(!notification.isRead ? 'Marquer comme lu' : 'Marquer comme non lu'),
                onTap: () {
                  Navigator.pop(context);
                  // Mettre à jour l'état de lecture
                },
              ),
              const ListTile(
                leading: Icon(Icons.delete),
                title: Text('Supprimer'),
              ),
              const ListTile(
                leading: Icon(Icons.notifications_off),
                title: Text('Désactiver les notifications de ce type'),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.update:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.update:
        return Icons.system_update;
    }
  }
}

class NotificationDetailPage extends StatelessWidget {
  final NotificationItem notification;

  const NotificationDetailPage({super.key, required this.notification});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(notification.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        notification.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              notification.content,
              style: const TextStyle(fontSize: 16),
            ),
            // Contenu détaillé de la notification
            const SizedBox(height: 16),
            // Actions supplémentaires selon le type de notification
            if (notification.type == NotificationType.message)
              ElevatedButton(
                onPressed: () {
                  // Action répondre
                },
                child: const Text('Répondre'),
              ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Colors.blue;
      case NotificationType.reminder:
        return Colors.orange;
      case NotificationType.update:
        return Colors.green;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.message:
        return Icons.message;
      case NotificationType.reminder:
        return Icons.alarm;
      case NotificationType.update:
        return Icons.system_update;
    }
  }
}

class NotificationSettingsSheet extends StatelessWidget {
  const NotificationSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options de notification',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Marquer tout comme lu'),
              onTap: () {
                Navigator.pop(context);
                // Marquer toutes les notifications comme lues
              },
            ),
            const ListTile(
              leading: Icon(Icons.delete_sweep),
              title: Text('Tout supprimer'),
            ),
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            const ListTile(
              leading: Icon(Icons.settings_applications),
              title: Text('Paramètres de notification'),
            ),
          ],
        ),
      ),
    );
  }
}

// Modèle de données pour les notifications
class NotificationItem {
  final String id;
  final String title;
  final String content;
  final String time;
  final bool isRead;
  final NotificationType type;

  NotificationItem({
    required this.id,
    required this.title,
    required this.content,
    required this.time,
    required this.isRead,
    required this.type,
  });
}

// Types de notifications
enum NotificationType {
  message,
  reminder,
  update,
}
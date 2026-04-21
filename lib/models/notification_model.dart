class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String ticketId;
  final String type; // status_update, new_comment, assigned, resolved
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.ticketId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });
}

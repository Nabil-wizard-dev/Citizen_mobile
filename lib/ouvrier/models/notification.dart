class NotificationModel {
  final String? trackingId;
  final String message;
  final bool lu;
  final String? entiteId;
  final String? destinataireId;

  NotificationModel({
    this.trackingId,
    required this.message,
    required this.lu,
    this.entiteId,
    this.destinataireId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      trackingId: json['trackingId'],
      message: json['message'] ?? '',
      lu: json['lu'] ?? false,
      entiteId: json['entiteId'],
      destinataireId: json['destinataireId'],
    );
  }
}

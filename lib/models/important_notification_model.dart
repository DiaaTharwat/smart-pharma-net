// lib/models/important_notification_model.dart

class ImportantNotificationModel {
  final int id;
  final String message;
  final String createdAt;
  final int pharmacyId;
  final int orderId;

  ImportantNotificationModel({
    required this.id,
    required this.message,
    required this.createdAt,
    required this.pharmacyId,
    required this.orderId,
  });

  factory ImportantNotificationModel.fromJson(Map<String, dynamic> json) {
    return ImportantNotificationModel(
      id: json['id'] ?? 0,
      message: json['message'] ?? 'No message content',
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      pharmacyId: json['pharmacy'] ?? 0,
      orderId: json['order'] ?? 0,
    );
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String senderId;
  final bool isPatient;
  final String message;
  final DateTime timestamp;

  ChatMessage({
    required this.senderId,
    required this.isPatient,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'senderId': senderId,
    'isPatient': isPatient,
    'message': message,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  static ChatMessage fromJson(Map<String, dynamic> json) => ChatMessage(
    senderId: json['senderId'] as String,
    isPatient: json['isPatient'],
    message: json['message'] as String,
    timestamp: (json['timestamp'] as Timestamp).toDate(),
  );
}

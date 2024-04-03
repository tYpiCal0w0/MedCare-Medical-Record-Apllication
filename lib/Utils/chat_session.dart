class ChatSession {
  final String chatId;
  final String patientId;
  // final String patientName;
  final String lastMessage;
  final DateTime timestamp;

  ChatSession({
    required this.chatId,
    required this.patientId,
    // required this.patientName,
    required this.lastMessage,
    required this.timestamp,
  });
}

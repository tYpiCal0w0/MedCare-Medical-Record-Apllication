import '../Utils/chat_session.dart';

class DoctorChatsViewModel {
  final String doctorId;
  List<ChatSession> chatSessions = [];

  DoctorChatsViewModel(this.doctorId);

  Future<void> fetchChats() async {
    // Fetch chats from your backend
    // For now, this is just a placeholder list
    chatSessions = [
      ChatSession(
        chatId: '',
          patientId: '1',
          // patientName: 'John Doe',
          lastMessage: 'Thanks, doctor!',
          timestamp: DateTime.now()
      ),
      // Add more sessions as per your data
    ];

    // Filter chats based on your conditions
    // You'll likely need to adjust this to integrate with your actual backend logic
  }
}

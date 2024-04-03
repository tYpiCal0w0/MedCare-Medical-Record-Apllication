import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Utils/notification_helper.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  final String patientId;
  final String doctorId;
  final bool isPatient;

  ChatScreen({required this.patientId, required this.doctorId, required this.isPatient});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();
    listenForMessages();
  }

  String getChatId() {
    List<String> ids = [widget.patientId, widget.doctorId];
    ids.sort();
    return ids.join('_');
  }

  Future<void> sendMessage(String messageText) async {
    if (messageText.trim().isEmpty) {
      return;
    }
    final chatId = getChatId();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set({
      'patientId': widget.patientId,
      'doctorId': widget.doctorId,
      'chatId': chatId,
    }, SetOptions(merge: true));

    final message = ChatMessage(
      senderId: widget.isPatient ? widget.patientId : widget.doctorId,
      message: messageText,
      timestamp: DateTime.now(),
      isPatient: widget.isPatient,
    );

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add(message.toJson());

    _controller.clear();
  }

  void listenForMessages() {
    final chatId = getChatId();

    FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots()
        .listen((snapshot) {
      var previousMessageCount = messages.length;
      setState(() {
        messages = snapshot.docs.map((doc) => ChatMessage.fromJson(doc.data() as Map<String, dynamic>)).toList();
      });

      // Check if there's a new message and the user is not the sender
      if (messages.length > previousMessageCount) {
        var latestMessage = messages.last;
        if (!(widget.isPatient ? latestMessage.isPatient : !latestMessage.isPatient)) {
          NotificationHelper.showNotification(
            id: 1, // Consider making this dynamic or based on message details
            title: 'MEDCARE - New Message',
            body: latestMessage.message,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isPatient ? 'Doctor' : 'Patient')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: false,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isSender = msg.senderId == (widget.isPatient ? widget.patientId : widget.doctorId);
                return Align(
                  alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSender ? Colors.blue[300] : Colors.green[300],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      msg.message,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: 'Type a message...',
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: Icon(Icons.send, color: Colors.white),
                    onPressed: () => sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

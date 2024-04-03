import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../Utils/chat_session.dart';
import 'chat_screen.dart'; // Your existing ChatScreen for messaging

class DoctorChatsScreen extends StatefulWidget {
  final String doctorId;

  DoctorChatsScreen({required this.doctorId});

  @override
  _DoctorChatsScreenState createState() => _DoctorChatsScreenState();
}

class _DoctorChatsScreenState extends State<DoctorChatsScreen> {
  List<ChatSession> chatSessions = [];
  var patId;

  @override
  void initState() {
    super.initState();
    fetchChatSessions();
  }

  void fetchChatSessions() async {
    FirebaseFirestore.instance
        .collection('chats')
        .where('doctorId', isEqualTo: widget.doctorId)
        .snapshots()
        .listen((snapshot) async {
      List<ChatSession> sessions = [];
      for (var doc in snapshot.docs) {
        // Assuming each chat document has a 'messages' subcollection
        var lastMessageSnapshot = await FirebaseFirestore.instance
            .collection('chats')
            .doc(doc.id)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(1)
            .get();

        patId = await FirebaseFirestore.instance
            .collection('chats')
            .doc(doc.id).get();

        String lastMessage = "";
        DateTime timestamp = DateTime.now(); // Default value, in case there's no message
        if (lastMessageSnapshot.docs.isNotEmpty) {
          final lastMessageDoc = lastMessageSnapshot.docs.first;
          lastMessage = lastMessageDoc['message']; // Assuming the message is stored in 'message' field
          timestamp = (lastMessageDoc['timestamp'] as Timestamp).toDate();
        }

        // Assuming you have a way to extract or store patient's name in chat doc or elsewhere
        String patientName = "Patient Name"; // This needs to be fetched or stored accordingly

        sessions.add(
          ChatSession(
            chatId: doc.id,
            // patientName: patientName,
            lastMessage: lastMessage,
            timestamp: timestamp,
            patientId: patId['patientId'],
          )
        );
      }

      setState(() {
        chatSessions = sessions;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),
      body: ListView.builder(
        itemCount: chatSessions.length,
        itemBuilder: (context, index) {
          final session = chatSessions[index];
          final formattedTime = DateFormat('MMM d, h:mm a').format(session.timestamp); // Formatting timestamp

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.teal[100],
                  borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                title: Text(session.patientId),
                leading: const CircleAvatar(
                  // Placeholder for a patient avatar. You might want to use patient's actual avatar if available
                  child: Icon(Icons.person), // Using first letter of patient's name as placeholder
                ),
                subtitle: Text(session.lastMessage),
                trailing: Text(formattedTime),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(
                    patientId: session.patientId,
                    doctorId: widget.doctorId, // You'll need to adjust how you handle chatPartnerId
                    isPatient: false,
                  )));
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

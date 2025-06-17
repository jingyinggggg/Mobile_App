import 'package:assignment_tripmate/screens/user/message.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {

  // SEND MESSAGE
  Future<void> sendMessage(String senderId, String senderName, String receiverId, String receiverName, String message) async {

    final Timestamp timestamp = Timestamp.now();

    // Create a new message
    Message newMessage = Message(
      senderId: senderId, 
      senderName: senderName, 
      receiverId: receiverId, 
      receiverName: receiverName, 
      message: message, 
      timestamp: timestamp
    );

    // Construct chat room id from current user id and receiver id (ensuring uniqueness)
    List<String> ids = [senderId, receiverId];
    ids.sort(); // Sort the ids (ensures the chat room id is always the same for any pair of people)
    String chatRoomId = ids.join('_');

    // Add the new message to the messages subcollection
    await FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages')
      .add(newMessage.toMap());

    // Ensure chat_rooms document exists with chatRoomId as a field
    await FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatRoomId)
      .set({
        'lastUpdate': timestamp,
      }, SetOptions(merge: true)); // Use merge: true to avoid overwriting existing data
  }

  // GET MESSAGES
  Stream<QuerySnapshot> getMessages(String userId, String otherUserId) {
    // Construct chat room id from user ids (sorted to ensure it matches the id used when sending messages)
    List<String> ids = [userId, otherUserId];
    ids.sort();
    String chatRoomId = ids.join('_');

    return FirebaseFirestore.instance
      .collection('chat_rooms')
      .doc(chatRoomId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .snapshots();
  }
}

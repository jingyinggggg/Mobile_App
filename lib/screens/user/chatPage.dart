import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatScreen extends StatefulWidget {
  final String userId;

  const ChatScreen({super.key, required this.userId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with AutomaticKeepAliveClientMixin {
  List<MessageList> _MessageList = [];
  List<MessageList> _foundedMessageList = [];
  bool isLoading = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState(){
    super.initState();
    fetchMessageList();
    setState(() {
      _foundedMessageList = _MessageList;
    });
  }

  String decryptText(String encryptedText) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final parts = encryptedText.split(':'); // Split to get IV and encrypted data

    if (parts.length != 2) {
      throw ArgumentError("Invalid encrypted format"); // Check for expected format
    }

    final iv = encrypt.IV.fromBase64(parts[0]); // Retrieve the original IV
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encryptedData, iv: iv); // Decrypt using original IV
  }

  Future<void> fetchMessageList() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Fetch all chat_rooms where the document ID contains widget.userId
      CollectionReference chatRef = FirebaseFirestore.instance.collection('chat_rooms');
      QuerySnapshot chatRoomsSnapshot = await chatRef
        .orderBy('lastUpdate', descending: true) // Order by lastUpdate field in descending order
        .get();

      // Clear the previous message list
      _MessageList.clear();

      // Iterate over all chat rooms
      for (var chatRoom in chatRoomsSnapshot.docs) {
        String docId = chatRoom.id.trim();
        List<String> ids = docId.split('_').map((id) => id.trim()).toList();

        // Ensure the current user ID is in the list of IDs
        if (ids.contains(widget.userId.trim())) {
          // Determine the other participant's ID
          String otherUserId = ids.firstWhere((id) => id != widget.userId.trim());

          // Fetch the latest message from the chat room
          CollectionReference messagesRef = chatRoom.reference.collection('messages');
          QuerySnapshot latestMessageSnapshot = await messagesRef
              .orderBy('timestamp', descending: true)
              .limit(1)
              .get();

          if (latestMessageSnapshot.docs.isNotEmpty) {
            var messageDoc = latestMessageSnapshot.docs.first; // Get the first (latest) message
            String senderId = messageDoc['senderId']; 

            // Fetch user profile based on the otherUserId type (User, Travel Agent, Admin)
            DocumentSnapshot userSnapshot;
            if (otherUserId.startsWith('U')) {
              userSnapshot = await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();
            } else if (otherUserId.startsWith('TA')) {
              userSnapshot = await FirebaseFirestore.instance.collection('travelAgent').doc(otherUserId).get();
            } else if (otherUserId.startsWith('A')) {
              userSnapshot = await FirebaseFirestore.instance.collection('admin').doc(otherUserId).get();
            } else {
              continue; // Skip if no valid collection is found
            }

            // If the user profile exists, extract profile image and message details
            if (userSnapshot.exists) {
              var userData = userSnapshot.data() as Map<String, dynamic>;
              String receiverProfile = userData['profileImage'] ?? ''; // Use a default or fallback image if null
              String receiverName = userData['name'] ?? 'Unknown'; // Use a default name if null

              // Determine if the sender is the current user
              bool isSenderCurrentUser = senderId == widget.userId;

              // Add the latest message along with the receiver's profile to the list
              _MessageList.add(
                MessageList(
                  receiverName,
                  receiverProfile,
                  otherUserId,
                  decryptText(messageDoc['message']), // Retrieve the message content, use empty string if null
                  messageDoc['timestamp'] as Timestamp? ?? Timestamp.now(),
                  isSenderCurrentUser
                ),
              );
            }
          }
        }
      }

      // Update UI after fetching the data
      setState(() {
        _foundedMessageList = _MessageList;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching messages: $e");
      setState(() {
        isLoading = false;  // Stop loading in case of an error
      });
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundedMessageList = _MessageList.where((MessageList) => 
        MessageList.receiverName.toUpperCase().contains(search.toUpperCase())).toList();
    });
  }

  String formatTimestamp(Timestamp timestamp) {
    DateTime messageDateTime = timestamp.toDate();
    DateTime now = DateTime.now();
    
    // Check if the message is from today
    if (messageDateTime.year == now.year && messageDateTime.month == now.month && messageDateTime.day == now.day) {
      return DateFormat.jm().format(messageDateTime); // Display time (without seconds)
    }
    
    // Check if the message is from yesterday
    if (messageDateTime.year == now.year && messageDateTime.month == now.month && 
        messageDateTime.day == now.day - 1) {
      return "Yesterday";
    }
    
    // Check if the message is from this week
    if (messageDateTime.isAfter(now.subtract(Duration(days: 7)))) {
      return DateFormat.EEEE().format(messageDateTime); // Display the day of the week
    }

    // If older than a week, display the date
    return DateFormat('MM/dd/yyyy').format(messageDateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
                child: Container(
                  height: 50,
                  child: TextField(
                    onChanged: (value) => onSearch(value),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20,),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), 
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), 
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF467BA1), width: 2), 
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red, width: 2), 
                      ),
                      hintText: "Search chat...",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

              // ElevatedButton(onPressed: fetchMessageList, child: Text("Fetch")),

              isLoading
                ? Expanded(child: Center(child: CircularProgressIndicator()))
                : _foundedMessageList.isNotEmpty
                  ? Expanded( // Ensures the ListView takes up the available space
                      child: Padding(
                        padding: EdgeInsets.only(right: 15, left: 15, top: 10), // Adjust padding
                        child: ListView.builder(
                          itemCount: _foundedMessageList.length,
                          itemBuilder: (context, index) {
                            return messageListComponent(messageList: _foundedMessageList[index]);
                          },
                        ),
                      ),
                    )
                  : Expanded(
                    child: Center(
                      child: Text(
                        'There are no message received currently.',
                        style: TextStyle(
                          fontSize: defaultFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  )
            ],
          ),
        ],
      ),
    );
  }

  Widget messageListComponent({required MessageList messageList}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => ChatDetailsScreen(userId: widget.userId, receiverUserId: messageList.receiverID))
        );
      },
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: [
            // Profile Image
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFF467BA1),
                  width: 2.0,
                ),
              ),
              child: CircleAvatar(
                radius: 25,
                backgroundImage: messageList.receiverProfile.isNotEmpty
                    ? NetworkImage(messageList.receiverProfile)
                    : AssetImage('images/profile.png'),
                backgroundColor: Colors.white,
              ),
            ),
            SizedBox(width: 15),

            // Expanded container to take available width
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          messageList.receiverName,
                          style: TextStyle(
                              color: Colors.black, 
                              fontWeight: FontWeight.w700, 
                              fontSize: 14),
                        ),
                        Text(
                          formatTimestamp(messageList.latestReceiveTime),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Text(
                      messageList.isCurrentUser ? 'You: ${messageList.latestMessage}' : messageList.latestMessage,
                      style: TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.w500, 
                        fontSize: 12,
                        overflow: TextOverflow.ellipsis
                      ),
                    ),
                    SizedBox(height: 10)
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }





}
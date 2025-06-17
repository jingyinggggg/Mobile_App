
import 'package:assignment_tripmate/chat_bubble.dart';
import 'package:assignment_tripmate/chat_service.dart';
import 'package:assignment_tripmate/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class ChatDetailsScreen extends StatefulWidget {
  final String userId;
  final String receiverUserId;

  const ChatDetailsScreen({super.key, required this.userId, required this.receiverUserId});

  @override
  State<ChatDetailsScreen> createState() => _ChatDetailsScreenState();
}

class _ChatDetailsScreenState extends State<ChatDetailsScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ChatService _chatService = ChatService();
  final ScrollController _scrollController = ScrollController(); 

  String? senderName;
  String? receiverName;
  String? senderProfileImage;
  String? receiverProfileImage;

  @override
  void initState() {
    super.initState();
    fetchSenderDetails();
    fetchReceiverDetails();
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      await _chatService.sendMessage(
        widget.userId,
        senderName!,
        widget.receiverUserId,
        receiverName!,
        encryptText(_messageController.text)
      );
      _messageController.clear();
    }
  }

  String encryptText(String text) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a random IV for each encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    // Combine IV and encrypted text with a delimiter
    return "${iv.base64}:${encrypted.base64}";
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

  Future<void> fetchSenderDetails() async {
    try {
      QuerySnapshot userQuery;

      if (widget.userId.startsWith('U')) {
        // Search in 'users' collection
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: widget.userId)
            .limit(1)
            .get();
      } else if (widget.userId.startsWith('TA')) {
        // Search in 'travelAgent' collection
        userQuery = await FirebaseFirestore.instance
            .collection('travelAgent')
            .where('id', isEqualTo: widget.userId)
            .limit(1)
            .get();
      } else {
        // Search in 'admin' collection
        userQuery = await FirebaseFirestore.instance
            .collection('admin')
            .where('id', isEqualTo: widget.userId)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        var receiverData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          senderName = receiverData['name'];
          senderProfileImage = receiverData['profileImage'];
        });
      } else {
        print("No user found with the given ID.");
      }

      // QuerySnapshot userQuery = await FirebaseFirestore.instance
      //   .collection('users')
      //   .where('id', isEqualTo: widget.userId)
      //   .limit(1)
      //   .get();
      
      // DocumentSnapshot userDoc = userQuery.docs.first;
      // var senderData = userDoc.data() as Map<String, dynamic>;

      // setState(() {
      //   senderName = senderData['name'];
      //   // senderProfileImage = senderData['profileImage'];
      // });
    } catch (e) {
      print("Error fetching sender details: $e");
    }
  }

  Future<void> fetchReceiverDetails() async {
    try {
      QuerySnapshot userQuery;

      if (widget.receiverUserId.startsWith('U')) {
        // Search in 'users' collection
        userQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('id', isEqualTo: widget.receiverUserId)
            .limit(1)
            .get();
      } else if (widget.receiverUserId.startsWith('TA')) {
        // Search in 'travelAgent' collection
        userQuery = await FirebaseFirestore.instance
            .collection('travelAgent')
            .where('id', isEqualTo: widget.receiverUserId)
            .limit(1)
            .get();
      } else {
        // Search in 'admin' collection
        userQuery = await FirebaseFirestore.instance
            .collection('admin')
            .where('id', isEqualTo: widget.receiverUserId)
            .limit(1)
            .get();
      }

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        var receiverData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          receiverName = receiverData['name'];
          receiverProfileImage = receiverData['profileImage'];
        });
      } else {
        print("No user found with the given ID.");
      }
    } catch (e) {
      print("Error fetching receiver details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(right: 20.0), // Add padding to the right of the back arrow
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, 
          children: [
            Container(
              width: 35, 
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.black, // Set your desired border color
                  width: 1.5, // Set your desired border width
                ),
              ),
              child: receiverProfileImage != null
              ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(receiverProfileImage ?? ''),
              )
              : CircleAvatar(
                  radius: 20,
                  backgroundImage: AssetImage("images/profile.png"),
                  backgroundColor: Colors.white,
                ),
            ),
            const SizedBox(width: 10), // Space between image and name
            // Name text
            Text(
              receiverName ?? '', // Use empty string as fallback if receiverName is null
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: defaultLabelFontSize,
              ),
            ),
          ],
        ),
        // centerTitle: true,
        backgroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),

      body: Column(
        children: [
          // messages
          Expanded(
            child: _buildMessageList(),
          ),
          // user input
          _buildMessageInput(),
        ],
      ),
    );
  }

  // build message list
  Widget _buildMessageList() {
    return StreamBuilder(
      stream: _chatService.getMessages(widget.receiverUserId, widget.userId), 
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ' + snapshot.error.toString());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...');
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        });

        return ListView(
          controller: _scrollController,
          children: snapshot.data!.docs
              .map((document) => _buildMessageItem(document))
              .toList(),
        );
      },
    );
  }

  // build message item
  Widget _buildMessageItem(DocumentSnapshot document) {
    Map<String, dynamic> data = document.data() as Map<String, dynamic>;

    // Check if the current user is the sender or receiver
    bool isSender = data['senderId'] == widget.userId;

    // Determine message alignment and profile image based on sender/receiver
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      alignment: isSender ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align at the top
        mainAxisAlignment: isSender ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isSender) // Show receiver's profile image if the current user is not the sender
            CircleAvatar(
              radius: 25, // Adjust the size as needed
              backgroundImage: receiverProfileImage != null && receiverProfileImage!.isNotEmpty
              ? NetworkImage(receiverProfileImage!)
              : AssetImage("images/profile.png")
            ),
          if (!isSender) SizedBox(width: 10), // Add space between profile and bubble
          Column(
            crossAxisAlignment: isSender ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Text(
                isSender ? 'You' : data['senderName'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              ChatBubble(message: decryptText( data['message'])), // Chat bubble
            ],
          ),
          if (isSender) SizedBox(width: 10), // Add space between bubble and profile
          if (isSender) // Show sender's profile image if the current user is the sender
            CircleAvatar(
              radius: 25, // Adjust the size as needed
              backgroundImage: senderProfileImage != null && senderProfileImage!.isNotEmpty
              ? NetworkImage(senderProfileImage ?? '')
              : AssetImage("images/profile.png")
            ),
        ],
      ),
    );
  }


  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: TextField(
        controller: _messageController,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          hintText: 'Enter message ...',
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          suffixIcon: IconButton(
            onPressed: sendMessage, 
            icon: ImageIcon(AssetImage('images/send.png'), size: 25, color: Color(0xFF467BA1),)
          ),
        ),
      ),
    );
  }
}

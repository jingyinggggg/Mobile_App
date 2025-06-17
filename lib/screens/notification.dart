import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/homepage.dart";
import "package:assignment_tripmate/screens/travelAgent/travelAgentHomepage.dart";
import "package:assignment_tripmate/screens/user/homepage.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class NotificationScreen extends StatefulWidget {
  final String userId;
  final bool isUser;
  final bool isTA;
  final bool isAdmin;

  const NotificationScreen({
    super.key, 
    required this.userId,
    this.isUser = false,
    this.isTA = false,
    this.isAdmin = false
    }
  );

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {

  List<Map<String, dynamic>> notiList = [];
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchNotiList(); // Fetch the list when initializing
  }

  Future<void> _fetchNotiList() async {
    setState(() {
      isFetching = true;
    });

    try {
      // Query the notification collection for documents where receiverID matches widget.userId
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notification')
          .where('receiverID', isEqualTo: widget.userId)
          .where('isRead', isEqualTo: 0)
          .orderBy('timestamp', descending: true)
          .get();

      // Map documents to include document ID
      notiList = querySnapshot.docs.map((doc) {
        return {
          'id': doc.id, // Add document ID here
          ...doc.data(), // Spread the notification data
        };
      }).toList();

      setState(() {
        isFetching = false;
      });
    } catch (e) {
      print("Error fetching notifications: $e");
      setState(() {
        isFetching = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Notification"),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            if(widget.isUser){
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => UserHomepageScreen(userId: widget.userId)
                )
              );
            } else if (widget.isTA){
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => TravelAgentHomepageScreen(userId: widget.userId)
                )
              );
            } else if (widget.isAdmin){
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => AdminHomepageScreen(userId: widget.userId)
                )
              );
            }
          },
        ),
      ),
      body: isFetching
          ? const Center(child: CircularProgressIndicator(color: primaryColor,)) // Show loading indicator while fetching
          : notiList.isEmpty
              ? const Center(child: Text("No notifications found")) // Show message if list is empty
              : notiComponent(notiList)
    );
  }


  Widget notiComponent(List<Map<String, dynamic>> data) {
    return ListView.builder(
      itemCount: data.length,
      itemBuilder: (context, index) {
        final notification = data[index];
        
        // Determine image based on type
        String imageAsset;
        switch (notification['type']) {
          case 'booking':
            imageAsset = 'images/bookingNoti.png';
            break;
          case 'cancellation':
            imageAsset = 'images/cancelBookingNoti.png';
            break;
          case 'refund':
            imageAsset = 'images/refund.png';
            break;
          case 'invoice':
            imageAsset = 'images/invoice.png';
            break;
          case 'withdraw':
            imageAsset = 'images/cash-withdrawal.png';
            break;
          default:
            imageAsset = 'images/default-image.png';
            break;
        }

        return GestureDetector(
          onTap: () async {
            // Update the notification to mark it as read using its document ID
            await FirebaseFirestore.instance
                .collection('notification')
                .doc(notification['id']) // Use the document ID here
                .update({'isRead': 1});
            
            // Optional: Refresh the UI after updating
            setState(() {
              data[index]['isRead'] = 1;
            });

            await _fetchNotiList();
          },
          child: Container(
            padding: EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.5)),
            ),
            child: Row(
              children: [
                // Left side: Icon based on type
                Image.asset(
                  imageAsset,
                  width: 50,
                  height: 50,
                ),
                const SizedBox(width: 15),
                
                // Right side: Notification content
                Expanded(
                  child: Text(
                    notification['content'] ?? 'No Content',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.justify,
                    maxLines: null,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

}

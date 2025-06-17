import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ViewAIItineraryScreen extends StatefulWidget {
  final String userId;
  final String itineraryID;
  final String fromAppLink;

  const ViewAIItineraryScreen({
    super.key, 
    required this.userId, 
    required this.itineraryID,
    required this.fromAppLink
  });

  @override
  State<ViewAIItineraryScreen> createState() => _ViewAIItineraryScreenState();
}

class _ViewAIItineraryScreenState extends State<ViewAIItineraryScreen> {
  bool isFetchingItinerary = false;
  Map<String, dynamic>? itineraryData;

  @override
  void initState() {
    super.initState();
    _fetchItinerary(widget.itineraryID);
  }

Future<void> _fetchItinerary(String itineraryId) async {
  setState(() {
    isFetchingItinerary = true;
  });
  
  try {
    CollectionReference itineraryRef = FirebaseFirestore.instance.collection('itineraries');

    // Query for a single document where the itineraryID field matches the specified itineraryId
    QuerySnapshot querySnapshot = await itineraryRef.where('itineraryID', isEqualTo: itineraryId).limit(1).get();

    if (querySnapshot.docs.isNotEmpty) {
      // If a document is found, get its data
      Map<String, dynamic> itineraryDatas = querySnapshot.docs.first.data() as Map<String, dynamic>;

      setState(() {
        itineraryData = itineraryDatas; // Store the fetched itinerary data
      });
    } else {
      print('No itinerary found for the given ID: $itineraryId');
    }
  } catch (e) {
    print('Error fetching itinerary: $e');
  } finally {
    setState(() {
      isFetchingItinerary = false;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    final String shareLink = 'https://tripmate.com/viewAIItinerary/${widget.userId}/${widget.itineraryID}/true';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Itinerary"),
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
            if (widget.fromAppLink == 'true') {
              // Show a message (SnackBar, Dialog, etc.)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please log into your account or register an account to explore more.'),
                ),
              );

              // Delay the navigation to the login page
              Future.delayed(const Duration(milliseconds: 500), () {
                // context.go('/login'); // Ensure you have a route defined for '/login'
                Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          Container(
            width: 50,
            child: IconButton(
              onPressed: () {
                if (widget.fromAppLink == 'true') {
                  // Show a message (SnackBar, Dialog, etc.)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please log into your account or register an account to explore more.'),
                    ),
                  );

                  // Delay the navigation to the login page
                  Future.delayed(const Duration(milliseconds: 500), () {
                    // context.go('/login'); // Ensure you have a route defined for '/login'
                    Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                  });
                } else {
                  Share.share(shareLink, subject: 'Check out this itinerary!');
                }
              },
              icon: Icon(
                Icons.share,
                color: Colors.white,
                size: 21,
              ),
              tooltip: "Share",
            )
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: 
          isFetchingItinerary
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : itineraryData == null
              ? Center(
                  child: Text(
                    "No record found in the system",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Text(
                        "Title: ${itineraryData!['title']}",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          height: 1.5
                        ),
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "${itineraryData!['content']}",
                        style: TextStyle(
                          fontSize: defaultFontSize,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                          height: 1.5
                        ),
                        textAlign: TextAlign.justify,
                        maxLines: null,
                        overflow: TextOverflow.visible,
                      ),
                    ],
                  ),
                )
      ),
    );
  }
}

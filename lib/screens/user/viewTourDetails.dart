import 'dart:io';
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/screens/user/createBooking.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ViewTourDetailsScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;
  final String tourID;
  final String fromAppLink;

  const ViewTourDetailsScreen({
    super.key,
    required this.userId,
    required this.countryName,
    required this.cityName,
    required this.tourID,
    required this.fromAppLink
  });

  @override
  State<StatefulWidget> createState() => _ViewTourDetailsScreenState();
}

class _ViewTourDetailsScreenState extends State<ViewTourDetailsScreen> with WidgetsBindingObserver {
  Map<String, dynamic>? tourData;
  bool isLoading = false;
  bool isOpenFile = false;
  bool isFavorited = false;
  bool isFetching = false;
  List<Map<String, dynamic>> reviewData = [];

  @override
  void initState() {
    super.initState();
    _fetchTourData();
    _checkIfFavorited();
    WidgetsBinding.instance.addObserver(this);
    _fetchReview();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Remove observer
    super.dispose();
  }

  Future<void> _checkIfFavorited() async {
    // Check if this tour package is already in the user's wishlist
    final wishlistQuery = await FirebaseFirestore.instance
        .collection('wishlist')
        .where('userID', isEqualTo: widget.userId)
        .get();

    if (wishlistQuery.docs.isNotEmpty) {
      final wishlistDocRef = wishlistQuery.docs.first.reference;
      final tourPackages = await wishlistDocRef.collection('tourPackage').where('tourPackageId', isEqualTo: widget.tourID).get();
      setState(() {
        isFavorited = tourPackages.docs.isNotEmpty; // Set the favorite status based on the query
      });
    }
  }

  Future<void> _fetchTourData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot docSnapshot = await tourRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          tourData = data ?? {}; // Ensure tourData is never null
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No tour found with the given tourID.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tour data: $e')),
      );
    }
  }

  Future openFile({required String url, String? fileName}) async {
    setState(() {
      isOpenFile = true;
    });
    final file = await downloadFile(url, fileName!);

    if(file == null) return;
    print('Path: ${file.path}');
    OpenFile.open(file.path);

    setState(() {
      isOpenFile = false;
    });
  }

  // Download file into private foler not visible to user
  Future<File?> downloadFile(String url, String name) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$name');

    try{
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: Duration(seconds: 10),
        )
      );

      final raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();

      return file;
    } catch(e){
      return null;
    }
  }

  Future<void> _fetchReview() async {
    setState(() {
      isFetching = true;
    });

    try {
      // Fetch reviews where packageID equals the widget.localBuddyId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('review')
          .where('packageID', isEqualTo: widget.tourID)
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Iterate over each review document
        for (var doc in snapshot.docs) {
          // Get userID from the review document
          String userID = doc['userID'];

          // Fetch the user data from the 'users' collection based on userID
          DocumentSnapshot userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userID)
              .get();

          if (userDoc.exists) {
            // Extract user details (assuming the fields exist)
            String userName = userDoc['name'] ?? 'Unknown';  // Provide default if the field doesn't exist
            String userProfile = userDoc['profileImage'] ?? '';  // Provide default if the field doesn't exist

            // Prepare the data to be added to the reviewData list
            Map<String, dynamic> reviewEntry = {
              'content': doc.data(),  // Store the review data
              'userName': userName,
              'userProfile': userProfile,
            };

            // Add the combined data (review + user details) to the list
            reviewData.add(reviewEntry);
          }
        }
      }

      // Now you can use reviewData list for displaying or processing further
      print('Review data: $reviewData');
    } catch (e) {
      print("Error fetching reviews: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  Future<void> _addToWishlist(String tourPackageId) async {
    try {
      // Reference to the Firestore collection
      final wishlistRef = FirebaseFirestore.instance.collection('wishlist');

      // Check if the wishlist document for the user exists
      final wishlistQuery = await wishlistRef.where('userID', isEqualTo: widget.userId).get();

      DocumentReference wishlistDocRef;

      if (wishlistQuery.docs.isEmpty) {
        // If no wishlist exists, create a new one with a custom ID format
        final snapshot = await wishlistRef.get();
        final wishlistID = 'WL${(snapshot.docs.length + 1).toString().padLeft(4, '0')}';

        wishlistDocRef = await wishlistRef.doc(wishlistID).set({
          'userID': widget.userId,
        }).then((_) => wishlistRef.doc(wishlistID)); // Get the reference of the new document
      } else {
        // Use the existing wishlist document
        wishlistDocRef = wishlistQuery.docs.first.reference;
      }

      // Now add the tour package ID to the 'tourPackage' subcollection
      await wishlistDocRef.collection('tourPackage').add({
        'tourPackageId': tourPackageId,
        // Add any other fields related to the tour package here
      });

      // Show SnackBar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current tour package is added to your wishlist!'),
          duration: Duration(seconds: 2), // Duration for which the SnackBar will be displayed
        ),
      );

      setState(() {
        isFavorited = true;
      });

      print('Current tour package is added to your wishlist.');
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }

  Future<void> _removeFromWishlist(String tourPackageId) async {
    try {
      final wishlistQuery = await FirebaseFirestore.instance
          .collection('wishlist')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (wishlistQuery.docs.isNotEmpty) {
        final wishlistDocRef = wishlistQuery.docs.first.reference;
        final tourPackages = await wishlistDocRef.collection('tourPackage').where('tourPackageId', isEqualTo: tourPackageId).get();

        if (tourPackages.docs.isNotEmpty) {
          // Delete the tour package document
          await tourPackages.docs.first.reference.delete();

          // Show SnackBar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Current tour package is removed from your wishlist!'),
              duration: Duration(seconds: 2),
            ),
          );

          setState(() {
            isFavorited = false; // Update favorite status
          });

          print('Current tour package is removed from your wishlist.');
        }
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }

  void _toggleWishlist() {
    if (isFavorited) {
      _removeFromWishlist(widget.tourID);
    } else {
      _addToWishlist(widget.tourID);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User has returned to the app
      setState(() {
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final String shareLink = 'https://tripmate.com/viewTourDetails/${widget.userId}/${widget.countryName}/${widget.cityName}/${widget.tourID}/true';
    // final String shareLink = 'https://tripmate.com/login';

    print(widget.fromAppLink);
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Group Tour"),
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
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show a loading indicator while data is being fetched
          : SingleChildScrollView(
            child: Column(
              children: [
                if (tourData?['tourCover'] != null) ...[
                  Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(tourData!['tourCover']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            width: double.infinity,
                            height: 60,
                            color: Colors.white.withOpacity(0.7),
                            child: Center(
                              child: Text(
                                tourData!['tourName'] ?? 'No Name',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0.5, 0.5),
                                      color: Colors.black87,
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                ] else ...[
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey,
                    ),
                    child: const Center(
                      child: Text(
                        'No Image Available',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],

                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Agency Info",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                child: IconButton(
                                  icon: isOpenFile
                                      ? SizedBox(
                                          width: 20.0, // Set the desired width
                                          height: 20.0, // Set the desired height
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF467BA1), // Set the color
                                          ),
                                        ) // Show loading indicator when loading
                                      : const ImageIcon(
                                          AssetImage("images/download-pdf.png"),
                                          size: 23,
                                          color: Colors.black,
                                        ),
                                  onPressed: isOpenFile
                                      ? null // Disable button when loading
                                      : () {
                                          openFile(
                                            url: tourData?['brochure'],
                                            fileName: '${tourData?['tourName']}.pdf',
                                          );
                                        },
                                ),
                              ),
                              Container(
                                width: 35,
                                child: IconButton(
                                  icon: Icon(
                                    isFavorited ? Icons.favorite : Icons.favorite_border,
                                    size: 23,
                                    color: isFavorited ? Colors.red : Colors.black,
                                  ),
                                  onPressed: (){
                                    _toggleWishlist();
                                  },
                                ),
                              ),
                              Container(
                                width: 35,
                                child: IconButton(
                                  icon: Icon(
                                    Icons.share,
                                    size: 23,
                                    color: Colors.black,
                                  ),
                                  onPressed: (){
                                    Share.share(shareLink, subject: 'Check out this tour!');
                                  },
                                ),
                              )
                            ],
                          ),
                        ],
                      ),

                      Text(
                        "Agency: ${tourData?['agency'] ?? 'No Agency Info'}",
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black
                        ),
                      ),

                      SizedBox(height: 20),

                      Text(
                        "Tour Highlights",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tourData?['tourHighlight']?.length ?? 0,
                        itemBuilder: (context, index) {
                          var tourHighlight = tourData!['tourHighlight'][index];
                          return tourHighlightComponent(
                            tourHighlight['no'] ?? 'No Numbering',
                            tourHighlight['description'] ?? 'No Description',
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Itinerary",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              final receiverUserId = tourData?['agentID']; // Safely get the value

                              if (receiverUserId != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ChatDetailsScreen(userId: widget.userId, receiverUserId: receiverUserId),
                                  ),
                                );
                              } else {
                                // Handle the case where receiverUserId is null
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Agent is not available')),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                const Text(
                                  "Enquiry",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 10),
                                const ImageIcon(
                                  AssetImage("images/communication.png"),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ],
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF467BA1),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(0),
                              ),
                            ),
                          )
                        ],
                      ),

                      SizedBox(height: 10),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tourData?['itinerary']?.length ?? 0,
                        itemBuilder: (context, index) {
                          var itinerary = tourData!['itinerary'][index];
                          return itineraryComponent(
                            itinerary['day'] ?? 'No Day',
                            itinerary['title'] ?? 'No Title',
                            itinerary['description'] ?? 'No Description',
                          );
                        },
                      ),

                      SizedBox(height: 20),

                      Text(
                        "Availability",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 10),

                      availabilityComponent(tourData!),

                      // SizedBox(height:30),
                      SizedBox(height: 30),
                      Padding(
                        padding: EdgeInsets.only(left: 0, right: 0),
                        child: Text(
                          "Reviews",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18
                          ),
                          textAlign: TextAlign.justify,
                        )
                      ),
                      SizedBox(height: 10),
                      reviewData.isNotEmpty
                      ? ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reviewData.length,
                        itemBuilder: (context, index){
                          var docData = reviewData[index];

                          return Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(15),
                            margin: EdgeInsets.only(bottom: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: primaryColor, width: 1.5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                    backgroundColor: Colors.white,
                                    backgroundImage: docData['userProfile'] != null
                                        ? NetworkImage(docData['userProfile'])
                                        : AssetImage("images/profile.png") as ImageProvider,
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded( // Use Expanded to avoid overflow
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        docData['userName'],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w700,
                                          fontSize: defaultFontSize,
                                        ),
                                      ),
                                      SizedBox(height: 5),
                                      Text(
                                        docData['content']['review'],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        textAlign: TextAlign.justify,
                                        overflow: TextOverflow.visible, // Handle long text
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        )
                      : Padding(
                          padding: EdgeInsets.only(left: 15, right: 15, bottom: 15),
                          child: Text(
                            "Selected tour package does not have any reviews yet.",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: defaultFontSize
                            ),
                            textAlign: TextAlign.center,
                          )
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 7.0,
            offset: Offset(0, -2),
          ),
        ],
        ),
        child: BottomAppBar(
          color: Colors.white,
          child: tourData != null ? bookNowComponent(tourData!) : SizedBox(), // Render empty widget if null
        ),
      ),

    );
  }

  Widget bookNowComponent(Map<String, dynamic> tourData) {
    double cheapestPrice = double.infinity; // Start with a high value

    // Check if availability is not empty
    if (tourData['availability'] != null && tourData['availability'].isNotEmpty) {
      // Extract prices safely and handle their types
      List<double> prices = [];
      for (var item in tourData['availability']) {
        // Safely access price and convert it to double
        final priceNum = item['price'] as num?;
        if (priceNum != null) {
          prices.add(priceNum.toDouble());
        }
      }
      
      // Find the cheapest price using fold
      if (prices.isNotEmpty) {
        cheapestPrice = prices.reduce((currentMin, price) => price < currentMin ? price : currentMin);
      } else {
        // Set default value if no prices are found
        cheapestPrice = 0.0; // or any default value you prefer
      }
    } else {
      // Handle case where availability is null or empty
      cheapestPrice = 0.0; // or any default value you prefer
    }

    return Container(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'From RM${cheapestPrice.toStringAsFixed(0)}/pax',
            style: TextStyle(
              fontSize: defaultLabelFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontStyle: FontStyle.italic,
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => createBookingScreen(userId: widget.userId, tour: true, tourID: widget.tourID,))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
            ),
            child: Text(
              'Book Now',
              style: TextStyle(
                color: Colors.white,
                fontSize: defaultFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget tourHighlightComponent(String numbering, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          Text(
            numbering + '.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 10),
          // Use Expanded to make sure the description text wraps properly
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
              textAlign: TextAlign.justify,
              maxLines: null, // Allow multi-line text
              overflow: TextOverflow.visible, // Show entire text
            ),
          ),
        ],
      ),
    );
  }

  Widget itineraryComponent(String day, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: IntrinsicHeight( // Ensure both sides of the Row stretch to the tallest child
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch both columns to match heights
          children: [
            Column(
              children: [
                Container(
                  width: 60,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF467BA1),
                    border: Border(
                      left: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      top: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      bottom: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      right: BorderSide.none,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "DAY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded( // Use Expanded here to stretch the Day number container
                  child: Container(
                    alignment: Alignment.center,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        top: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        bottom: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        right: BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF467BA1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget availabilityComponent(Map<String, dynamic> data) {
    if (data.isEmpty || data['availability'] == null || data['availability'].isEmpty || data['flight_info'] == null || data['flight_info'].isEmpty) {
      return Center(
        child: Text('No availability data found'),
      );
    } else {
      List<dynamic> availabilityList = data['availability'];
      List<dynamic> flightInfoList = data['flight_info'];

      // Ensure both lists are of equal length
      int length = availabilityList.length < flightInfoList.length ? availabilityList.length : flightInfoList.length;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFF467BA1), width: 1.0),
            ),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(1.2),
                1: FlexColumnWidth(1.1),
                2: FlexColumnWidth(1.2),
              },
              border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
              children: [
                // Header row
                TableRow(
                  children: [
                    _buildTableHeaderCell("Date"),
                    _buildTableHeaderCell("Flight"),
                    _buildTableHeaderCell("Price"),
                  ],
                ),
                // Data rows
                for (int i = 0; i < length; i++)
                  TableRow(
                    children: [
                      _buildTextFieldCell(availabilityList[i]['dateRange'] ?? 'No Date'),
                      _buildTextFieldCell(flightInfoList[i]['flightName'] ?? 'No Flight'),
                      _buildTextFieldCell('RM ' + (availabilityList[i]['price']?.toString() ?? '0') + '.00'),
                    ],
                  ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildTextFieldCell(String text) {
    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFF467BA1), width: 1.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w600
          ),
          maxLines: null, // Allows multiline input
          textAlign: TextAlign.center,
        ),
      )

    );
  }  

  Widget _buildTableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: const Color(0xFF467BA1).withOpacity(0.6),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }  

}

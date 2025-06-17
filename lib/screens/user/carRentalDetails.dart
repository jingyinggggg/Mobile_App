import 'dart:convert';
import 'package:assignment_tripmate/screens/login.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/screens/user/createBooking.dart';
import 'package:http/http.dart' as http;
import 'package:assignment_tripmate/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
// import 'package:latlong2/latlong.dart';

class CarRentalDetailsScreen extends StatefulWidget {
  final String userId;
  final String carId;
  final String fromAppLink;

  const CarRentalDetailsScreen({super.key, required this.userId, required this.carId, required this.fromAppLink});

  @override
  State<StatefulWidget> createState() => _CarRentalDetailsScreenState();
}

class _CarRentalDetailsScreenState extends State<CarRentalDetailsScreen> {
  Map<String, dynamic>? carData;
  bool isLoading = true;
  LatLng targetCarLocation = LatLng(0, 0);
  Set<Marker> _markers = {};
  bool isFavorited = false;
  bool isFetching = false;
  List<Map<String, dynamic>> reviewData = [];

  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
    _checkIfFavorited();
    _fetchReview();
  }

  Future<void> _checkIfFavorited() async {
    // Check if this tour package is already in the user's wishlist
    final wishlistQuery = await FirebaseFirestore.instance
        .collection('wishlist')
        .where('userID', isEqualTo: widget.userId)
        .get();

    if (wishlistQuery.docs.isNotEmpty) {
      final wishlistDocRef = wishlistQuery.docs.first.reference;
      final carRental = await wishlistDocRef.collection('carRental').where('carRentalId', isEqualTo: widget.carId).get();
      setState(() {
        isFavorited = carRental.docs.isNotEmpty; // Set the favorite status based on the query
      });
    }
  }  

  Future<void> _fetchCarDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference carRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carId);
      DocumentSnapshot carSnapshot = await carRef.get();

      if (carSnapshot.exists) {
        setState(() {
          carData = carSnapshot.data() as Map<String, dynamic>?;
        });
              
        // Convert the pickup location to LatLng
        await _fetchCoordinates(carSnapshot['pickUpLocation']);

      } else {
        _showSnackBar('Car not found');
      }
    } catch (e) {
      _showSnackBar('Error fetching car data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCoordinates(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          double lat = data['results'][0]['geometry']['location']['lat'];
          double lng = data['results'][0]['geometry']['location']['lng'];
          setState(() {
            targetCarLocation = LatLng(lat, lng);

            // Add marker at the target location
            _markers.add(
              Marker(
                markerId: MarkerId('targetLocation'),
                position: targetCarLocation,
                infoWindow: InfoWindow(
                  title: 'Car Location',
                ),
              ),
            );
          });
        } else {
          _showSnackBar('No locations found for the provided address.');
        }
      } else {
        _showSnackBar('Error fetching location data.');
      }
    } catch (e) {
      _showSnackBar('Error fetching location data: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _fetchReview() async {
    setState(() {
      isFetching = true;
    });

    try {
      // Fetch reviews where packageID equals the widget.localBuddyId
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('review')
          .where('packageID', isEqualTo: widget.carId)
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

  Future<void> _addToWishlist(String carRentalId) async {
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
      await wishlistDocRef.collection('carRental').add({
        'carRentalId': carRentalId,
        // Add any other fields related to the tour package here
      });

      // Show SnackBar to inform the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current car rental details is added to your wishlist!'),
          duration: Duration(seconds: 2), // Duration for which the SnackBar will be displayed
        ),
      );

      setState(() {
        isFavorited = true;
      });
    } catch (e) {
      print('Error adding to wishlist: $e');
    }
  }

  Future<void> _removeFromWishlist(String carRentalId) async {
    try {
      final wishlistQuery = await FirebaseFirestore.instance
          .collection('wishlist')
          .where('userID', isEqualTo: widget.userId)
          .get();

      if (wishlistQuery.docs.isNotEmpty) {
        final wishlistDocRef = wishlistQuery.docs.first.reference;
        final carRental = await wishlistDocRef.collection('carRental').where('carRentalId', isEqualTo: carRentalId).get();

        if (carRental.docs.isNotEmpty) {
          // Delete the tour package document
          await carRental.docs.first.reference.delete();

          // Show SnackBar to inform the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Current car rental details is removed from your wishlist!'),
              duration: Duration(seconds: 2),
            ),
          );

          setState(() {
            isFavorited = false; // Update favorite status
          });
        }
      }
    } catch (e) {
      print('Error removing from wishlist: $e');
    }
  }  

  void _toggleWishlist() {
    if (isFavorited) {
      _removeFromWishlist(widget.carId);
    } else {
      _addToWishlist(widget.carId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String shareLink = 'https://tripmate.com/carRentalDetails/${widget.userId}/${widget.carId}/true';
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Car Rental"),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: defaultAppBarTitleFontSize,
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
          Row(
            mainAxisSize: MainAxisSize.min, // To keep the Row tight and avoid expanding
            children: [
              Container(
                width: 35,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ChatDetailsScreen(userId: widget.userId, receiverUserId: carData?['agencyID'] ?? ''))
                    );
                  },
                  icon: ImageIcon(
                    AssetImage('images/chat.png'),
                    color: Colors.white,
                    size: 21,
                  ),
                  tooltip: "Chat",
                )
              ),
              Container(
                width: 30,
                child: IconButton(
                  icon: Icon(
                    Icons.favorite,
                    size: 23,
                    color: isFavorited ? Colors.red : Colors.white,
                  ),
                  tooltip: 'Wishlist',
                  onPressed: () {
                    _toggleWishlist();
                  },
                ),
              ),
              Container(
                width: 30,
                child: IconButton(
                  icon: Icon(
                    Icons.share,
                    size: 23,
                    color:  Colors.white,
                  ),
                  tooltip: 'Share',
                  onPressed: () {
                    Share.share(shareLink, subject: 'Check out this car rental!');
                  },
                ),
              ),
              SizedBox(width: 10,)
            ],
          ),
        ],

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Container(
                  height: getScreenHeight(context) * 0.3,
                  child: GoogleMap(

                    markers: _markers,
                    initialCameraPosition: CameraPosition(
                      target: targetCarLocation,
                      zoom: 13
                    ),
                    mapType: MapType.normal,
                  ),
                ),
                SizedBox(height: getScreenHeight(context) * 0.9,),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFF749CB9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4), // Adjust shadow color and opacity as needed
                              blurRadius: 10.0,
                              offset: Offset(0, -4), // Shadow above the container
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carData?['carModel'] ?? 'Car Model not available',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAgencyInfo(),
                                _buildAgencyContact(),
                              ],
                            )
                          ],
                        ),
                      ),
                      _buildScrollView(),
                      Container(
                        padding: EdgeInsets.only(left: 15, right: 15),
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2), // Adjust shadow color and opacity as needed
                              blurRadius: 4.0,
                              offset: Offset(0, -2), // Shadow above the container
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between
                          children: [
                            Text(
                              'RM${(carData?['pricePerDay'] ?? 0).toStringAsFixed(0)}/day',
                              style: TextStyle(
                                fontSize: defaultLabelFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(builder: (context) => createBookingScreen(userId: widget.userId, carRental: true, carRentalID: widget.carId,))
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10), // Button radius
                                ),
                              ),
                              child: Text(
                                'Rent Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: defaultFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                // _buildCarImage(),
              ],
            ),
    );
  }

  Widget _buildAgencyInfo() {
    return Row(
      children: [
        const Icon(Icons.support_agent, color: Colors.white, size: 20),
        const SizedBox(width: 5),
        Text(
          carData?['agencyName'] ?? 'N/A',
          style: const TextStyle(color: Colors.white, fontSize: defaultFontSize),
        ),
      ],
    );
  }

  Widget _buildAgencyContact() {
    return Row(
      children: [
        const Icon(Icons.phone, color: Colors.white, size: 20),
        const SizedBox(width: 5),
        Text(
          carData?['agencyContact'] ?? 'N/A',
          style: const TextStyle(color: Colors.white, fontSize: defaultFontSize),
        ),
      ],
    );
  }

  Widget _buildScrollView() {
    return Container(
      height: getScreenHeight(context) * 0.40, // Fixed height for the scrollable container
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Car Info", style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _buildCarInfoRow(),
              const SizedBox(height: 15),
              _buildLocationSection(),
              const SizedBox(height: 15),
              _buildConditionSection(),
              const SizedBox(height: 15),
              _buildInsuranceSection(),
              const SizedBox(height: 15),
              _buildRentalPolicySection(),
              SizedBox(height: 15),
              Padding(
                padding: EdgeInsets.only(left: 0, right: 0),
                child: Text(
                  "Reviews",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: defaultLabelFontSize
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
                    "Selected car rental package does not have any reviews yet.",
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
      ),
    );
  }

  Widget _buildCarInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        carInfoIcon(
          carData?['transmission'] == "Auto"
              ? const AssetImage("images/automatic-transmission.png")
              : const AssetImage("images/gearbox.png"),
          carData?['transmission'] ?? 'N/A',
          'Transmission',
        ),
        carInfoIcon(
          carData?['fuel'] == "Petrol"
              ? const AssetImage("images/gasoline.png")
              : carData?['fuel'] == "Electricity"
                  ? const AssetImage("images/charging-station.png")
                  : const AssetImage("images/hybrid-car.png"),
          carData?['fuel'] ?? 'N/A',
          'Fuel',
        ),
        carInfoIcon(
          const AssetImage("images/car.png"),
          carData!['carType'].toString(),
          'Car Type',
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _buildLocationContainer('Pick Up Location', carData?['pickUpLocation']),
      ],
    );
  }

  Widget _buildLocationContainer(String title, String? location) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding( // Adding some padding to avoid text touching the container's border
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          children: [
            Text(
              'Pick Up Location',
              style: TextStyle(
                fontSize: defaultFontSize,
                fontWeight: FontWeight.w600,
                ),
            ),
            SizedBox(height: 5), // Adding some space between the title and the content
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  carData!['pickUpLocation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Drop Off Location',
            style: TextStyle(
            fontSize: defaultFontSize,
            fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5), // Adding some space between the title and the content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  carData!['dropOffLocation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ] ,
        ),
      ),
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Car Condition",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['carCondition'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Insurance",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['insurance'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalPolicySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rental Policy",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['rentalPolicy'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarImage() {
    return Positioned(
      top: getScreenHeight(context) * 0.2,
      right: 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          width: getScreenWidth(context) * 0.37,
          height: getScreenHeight(context) * 0.18,
          child: carData?['carImage'] != null
              ? Image.network(
                  carData!['carImage'],
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Center(child: Text('Error loading image'));
                  },
                )
              : Center(child: Text('No image available')),
        ),
      ),
    );
  }

  Widget carInfoIcon(AssetImage image, String title, String subtitle) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF749CB9), width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Image(image: image, width: 30, height: 30),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

}

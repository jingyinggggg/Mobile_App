import 'dart:convert';

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/carRentalDetails.dart';
import 'package:assignment_tripmate/screens/user/localBuddyDetails.dart';
import 'package:assignment_tripmate/screens/user/viewTourDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WishlistScreen extends StatefulWidget {
  final String userID;

  const WishlistScreen({super.key, required this.userID});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> with SingleTickerProviderStateMixin{

  int currentPageIndex = 0;
  List<TourPackage> _tourPackage = [];
  List<CarRental> _carRental = [];
  List<LocalBuddy> _localBuddy = [];
  bool isLoading = false;

  @override
  void initState(){
    super.initState();
    fetchWishlist();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> fetchWishlist() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Step 1: Fetch wishlist documents for the current user
      CollectionReference wishlistRef = FirebaseFirestore.instance.collection('wishlist');
      QuerySnapshot wishlistSnapshot = await wishlistRef.where('userID', isEqualTo: widget.userID).get();

      List<String> tourPackageIDs = [];
      List<String> carRentalIDs = [];
      List<String> localBuddyIDs = [];

      // Step 2: Loop through each wishlist document and fetch tourPackageId and carRentalId from subcollections
      for (var wishlistDoc in wishlistSnapshot.docs) {
        CollectionReference tourPackageSubcollection = wishlistRef.doc(wishlistDoc.id).collection('tourPackage');
        QuerySnapshot tourPackageSnapshot = await tourPackageSubcollection.get();

        CollectionReference carRentalSubcollection = wishlistRef.doc(wishlistDoc.id).collection('carRental');
        QuerySnapshot carRentalSnapshot = await carRentalSubcollection.get();

        CollectionReference localBuddySubcollection = wishlistRef.doc(wishlistDoc.id).collection('localBuddy');
        QuerySnapshot localBuddySnapshot = await localBuddySubcollection.get();
        
        // Extract the tourPackageId from each document in the subcollection
        for (var tourDoc in tourPackageSnapshot.docs) {
          String tourPackageId = tourDoc['tourPackageId'] as String;
          tourPackageIDs.add(tourPackageId);
        }

        // Extract the carRentalId from each document in the subcollection
        for (var carDoc in carRentalSnapshot.docs) {
          String carRentalID = carDoc['carRentalId'] as String;
          carRentalIDs.add(carRentalID);
        }

        // Extract the localBuddyId from each document in the subcollection
        for (var localBuddyDoc in localBuddySnapshot.docs) {
          String localBuddyID = localBuddyDoc['localBuddyId'] as String;
          localBuddyIDs.add(localBuddyID);
        }
      }

      // Step 3: Fetch tour packages from 'tourPackage' collection using the retrieved IDs
      if (tourPackageIDs.isNotEmpty) {
        CollectionReference tourPackagesRef = FirebaseFirestore.instance.collection('tourPackage');
        QuerySnapshot tourPackageSnapshot = await tourPackagesRef.where(FieldPath.documentId, whereIn: tourPackageIDs).get();

        // Map the fetched documents to TourPackage objects and update the state
        setState(() {
          _tourPackage = tourPackageSnapshot.docs.map((doc) => TourPackage.fromFirestore(doc)).toList();
        });
      } else {
        setState(() {
          _tourPackage = [];
        });
      }

      // Step 4: Fetch car rentals from 'carRental' collection using the retrieved IDs
      if (carRentalIDs.isNotEmpty) {
        CollectionReference carRentalsRef = FirebaseFirestore.instance.collection('car_rental');
        QuerySnapshot carRentalSnapshot = await carRentalsRef.where(FieldPath.documentId, whereIn: carRentalIDs).get();

        // Map the fetched documents to CarRental objects and update the state
        setState(() {
          _carRental = carRentalSnapshot.docs.map((doc) => CarRental.fromFirestore(doc)).toList();
        });
      } else {
        setState(() {
          _carRental = [];
        });
      }

      // Step 5: Fetch local buddy from 'localBuddy' collection using the retrieved IDs
      if (localBuddyIDs.isNotEmpty) {
        CollectionReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddy');
        QuerySnapshot localBuddySnapshot = await localBuddyRef.where(FieldPath.documentId, whereIn: localBuddyIDs).get();

        List<LocalBuddy> localBuddies = [];

        // Loop through each localBuddy document to fetch details and profile image
        for (var localBuddyDoc in localBuddySnapshot.docs) {
          String userId = localBuddyDoc['userID'] as String;

          // Fetch user details including profile image from 'users' collection
          DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
          String profileImage = userDoc['profileImage'] as String;
          String localBuddyName = userDoc['name'] as String;

          // Get full address from the document
          String fullAddress = localBuddyDoc['location'];

          // Call the Geocoding API to extract country and area
          String? country = '';
          String? area = '';

          if (fullAddress.isNotEmpty) {
            var locationData = await _getLocationAreaAndCountry(fullAddress);
            country = locationData['country'];
            area = locationData['area'];
          }

          String locationArea = '$area, $country';

          LocalBuddy localBuddy = LocalBuddy.fromFirestore(localBuddyDoc);
          localBuddy.image = profileImage;
          localBuddy.locationArea = locationArea;
          localBuddy.localBuddyName = localBuddyName;

          localBuddies.add(localBuddy);

          // Map the fetched documents to CarRental objects and update the state
          setState(() {
            _localBuddy = localBuddies;
          });
        }
      } else {
        setState(() {
          _localBuddy = [];
        });
      }

      // End loading state
      setState(() {
        isLoading = false;
      });
      
    } catch (e) {
      print('Error fetching wishlist: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Function to get area and country from the full address using the Google Geocoding API
  Future<Map<String, String>> _getLocationAreaAndCountry(String address) async {
    final String apiKeys = apiKey; // Replace with your API key
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKeys';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];

        String country = '';
        String area = '';

        for (var component in addressComponents) {
          List<String> types = List<String>.from(component['types']);
          if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('administrative_area_level_1') || types.contains('locality')) {
            area = component['long_name'];
          }
        }

        return {'country': country, 'area': area};
      } else {
        return {'country': '', 'area': ''};
      }
    } else {
      print('Error fetching location data: ${response.statusCode}');
      return {'country': '', 'area': ''};
    }
  }

  @override
  Widget build(BuildContext content) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Wishlist"),
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
              Navigator.pop(context);
            },
          )
        ),
        body: Column(
          children: [

            const TabBar(
              labelColor: Color(0xFF467BA1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color(0xFF467BA1),
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600
              ),
              tabs: [
                Tab(text: "Tour Package"),
                Tab(text: "Car Rental"),
                Tab(text: "Local Buddy"),
              ],
            ),

            Expanded(
              child: TabBarView(
                children: [
                  isLoading
                      ? Center(child: CircularProgressIndicator(color: primaryColor))
                      : _tourPackage.isNotEmpty
                          ? Container(
                              padding: EdgeInsets.only(right: 10, left: 10),
                              child: ListView.builder(
                                itemCount: _tourPackage.length,
                                itemBuilder: (context, index) {
                                  return TPComponent(tourPackage: _tourPackage[index]);
                                }
                              ),
                            )
                          : Center(child: Text('No tour packages found in your wishlist')),
                  isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : _carRental.isNotEmpty
                      ? Container(
                        padding: EdgeInsets.only(right: 10, left: 10),
                        child: ListView.builder(
                          itemCount: _carRental.length,
                          itemBuilder: (context, index) {
                            return CarComponent(carRental: _carRental[index]);
                          }
                        ),
                      )
                    : Center(child: Text('No car rental details found in your wishlist')),
                  isLoading
                    ? Center(child: CircularProgressIndicator(color: primaryColor))
                    : _localBuddy.isNotEmpty
                      ? Container(
                        padding: EdgeInsets.only(right: 10, left: 10),
                        child: ListView.builder(
                          itemCount: _localBuddy.length,
                          itemBuilder: (context, index) {
                            return LBComponent(localBuddy: _localBuddy[index]);
                          }
                        ),
                      )
                    : Center(child: Text('No local buddy details found in your wishlist')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget TPComponent({required TourPackage tourPackage}) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => ViewTourDetailsScreen(userId: widget.userID, countryName: tourPackage.countryName, cityName: tourPackage.cityName, tourID: tourPackage.tourID, fromAppLink: 'false',))
        );
      },
      child: Container(
        padding: EdgeInsets.only(top: 20, bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wrap this inner Row with Expanded to make sure it takes the available space
            Expanded(
              child: Row(
                children: [
                  // Image container with fixed width and height
                  Container(
                    width: getScreenWidth(context) * 0.18,
                    height: getScreenHeight(context) * 0.13,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(tourPackage.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Text widget wrapped in Expanded to take remaining space
                  Expanded(
                    child: Text(
                      tourPackage.tourName, 
                      style: TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: defaultLabelFontSize,
                      ),
                      overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget CarComponent({required CarRental carRental}) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => CarRentalDetailsScreen(userId: widget.userID, carId: carRental.carID, fromAppLink: 'false',))
        );
      },
      child: Container(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wrap this inner Row with Expanded to make sure it takes the available space
            Expanded(
              child: Row(
                children: [
                  // Image container with fixed width and height
                  Container(
                    width: getScreenWidth(context) * 0.25,
                    height: getScreenHeight(context) * 0.11,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      // border: Border.all(color: primaryColor, width: 1.5),
                      image: DecorationImage(
                        image: NetworkImage(carRental.image),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  // Text widget wrapped in Expanded to take remaining space
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carRental.carName, 
                          style: TextStyle(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold, 
                            fontSize: defaultLabelFontSize,
                          ),
                          overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Provider: ${carRental.provider}',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: defaultFontSize
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    )
                    
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

  Widget LBComponent({required LocalBuddy localBuddy}) {
    return GestureDetector(
      onTap: (){
        Navigator.push(
          context, 
          MaterialPageRoute(builder: (context) => LocalBuddyDetailsScreen(userId: widget.userID, localBuddyId: localBuddy.localBuddyID, fromAppLink: 'false'))
        );
      },
      child: Container(
        padding: EdgeInsets.only(top: 20, bottom: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade100, width: 1.5))
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Wrap this inner Row with Expanded to make sure it takes the available space
            Expanded(
              child: Row(
                children: [
                  // Image container with fixed width and height
                  Container(
                    width: getScreenWidth(context) * 0.18,
                    height: getScreenHeight(context) * 0.13,
                    margin: EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(localBuddy.image),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  // Text widget wrapped in Expanded to take remaining space
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localBuddy.localBuddyName, 
                          style: TextStyle(
                            color: Colors.black, 
                            fontWeight: FontWeight.bold, 
                            fontSize: defaultLabelFontSize,
                          ),
                          overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Location: ${localBuddy.locationArea}',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: defaultFontSize
                          ),
                          overflow: TextOverflow.ellipsis,
                        )
                      ],
                    )
                    
                  ),
                ],
              ),
            ),
          ],
        ),
      )
    );
  }

}

class TourPackage {
  final String tourName;
  final String tourID;
  final String image;
  final String countryName;
  final String cityName;

  // Named parameters constructor
  TourPackage({
    required this.tourName,
    required this.tourID,
    required this.image,
    required this.countryName,
    required this.cityName
  });

  // Add a factory constructor to convert Firestore document to TourPackage object
  factory TourPackage.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TourPackage(
      tourID: doc.id, // Firestore document ID
      tourName: data['tourName'] ?? '',
      image: data['tourCover'] ?? '',
      countryName: data['countryName'] ?? '',
      cityName: data['cityName'] ?? ''
    );
  }
}

class CarRental {
  final String carName;
  final String carID;
  final String image;
  final String provider;

  // Named parameters constructor
  CarRental({
    required this.carName,
    required this.carID,
    required this.image,
    required this.provider,
  });

  // Add a factory constructor to convert Firestore document to TourPackage object
  factory CarRental.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return CarRental(
      carID: doc.id, // Firestore document ID
      carName: data['carModel'] ?? '',
      image: data['carImage'] ?? '',
      provider: data['agencyName'] ?? '',
    );
  }
}

class LocalBuddy {
  late String localBuddyName;
  final String localBuddyID;
  late String image; // Late variable, can be assigned later
  late String locationArea; // Late variable, can be assigned later

  // Constructor without image and locationArea
  LocalBuddy({
    required this.localBuddyID,
  });

  // Factory constructor to convert Firestore document to LocalBuddy object
  factory LocalBuddy.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    LocalBuddy localBuddy = LocalBuddy(
      localBuddyID: doc.id, // Firestore document ID
    );

    localBuddy.image = data['profileImage'] ?? '';
    localBuddy.locationArea = data['locationArea'] ?? '';
    localBuddy.localBuddyName = data['localBuddyName'] ?? '';

    return localBuddy;
  }
}



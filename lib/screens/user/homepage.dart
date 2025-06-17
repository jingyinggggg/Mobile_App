import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/notification.dart';
import 'package:assignment_tripmate/screens/user/accountPage.dart';
import 'package:assignment_tripmate/screens/user/bookings.dart';
import 'package:assignment_tripmate/screens/user/carRentalDetails.dart';
import 'package:assignment_tripmate/screens/user/carRentalHomepage.dart';
import 'package:assignment_tripmate/screens/user/itinerary.dart';
import 'package:assignment_tripmate/screens/user/chatPage.dart';
import 'package:assignment_tripmate/screens/user/languageTranslator.dart';
import 'package:assignment_tripmate/screens/user/localBuddyDetails.dart';
import 'package:assignment_tripmate/screens/user/localBuddyHomepage.dart';
import 'package:assignment_tripmate/screens/user/viewCity.dart';
import 'package:assignment_tripmate/screens/user/viewCountry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:assignment_tripmate/screens/user/bottom_nav_bar.dart';

class UserHomepageScreen extends StatefulWidget {
  final String userId;
  final int? currentPageIndex;

  const UserHomepageScreen({super.key, required this.userId, this.currentPageIndex = 0});

  @override
  State<UserHomepageScreen> createState() => _UserHomepageScreenState();
}

class _UserHomepageScreenState extends State<UserHomepageScreen> {
  late int currentPageIndex;
  bool isFetchingCountry = false;
  bool isFecthingCarRental = false;
  bool isFecthingLocalBuddy = false;
  bool hasNoti = false;
  List<Map<String, dynamic>> countryList = [];
  List<Map<String, dynamic>> carRentalList = [];
  List<Map<String, dynamic>> localBuddyList = [];

  final List<String> _screenTitles = [
    "Tripmate",
    "Itinerary",
    "Messages",
    "Bookings",
    "Account",
  ];

  @override
  void initState() {
    super.initState();
    currentPageIndex = widget.currentPageIndex ?? 0;
    _fetchNotificationCount();
    fetchRandomCountries();
    fetchRandomCarRentalPackage();
    fetchRandomLocalBuddies();
  }

  void _onNavBarTap(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  Future<void> fetchRandomCountries() async {
    setState(() {
      isFetchingCountry = true;
    });

    try {
      CollectionReference ref = FirebaseFirestore.instance.collection('countries');
      QuerySnapshot querySnapshot = await ref.get();

      // Convert documents to list of maps
      List<Map<String, dynamic>> allCountries = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Shuffle the list for randomness
      allCountries.shuffle();

      // Take the first 5 entries after shuffling
      countryList = allCountries.take(5).toList();
    } catch (e) {
      print("Error fetching countries: $e");
    } finally {
      setState(() {
        isFetchingCountry = false;
      });
    }
  }

  Future<void> fetchRandomCarRentalPackage() async {
    setState(() {
      isFecthingCarRental = true;
    });

    try {
      CollectionReference ref = FirebaseFirestore.instance.collection('car_rental');
      QuerySnapshot querySnapshot = await ref.get();

      // Convert documents to list of maps
      List<Map<String, dynamic>> allCar = querySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Shuffle the list for randomness
      allCar.shuffle();

      // Take the first 5 entries after shuffling
      carRentalList = allCar.take(5).toList();
    } catch (e) {
      print("Error fetching Car Rental Package: $e");
    } finally {
      setState(() {
        isFecthingCarRental = false;
      });
    }
  }

  Future<void> fetchRandomLocalBuddies() async {
    setState(() {
      isFecthingLocalBuddy = true; // Use a separate state variable if needed
    });

    try {
      CollectionReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddy');
      QuerySnapshot localBuddySnapshot = await localBuddyRef.where('registrationStatus', isEqualTo: 2).get();

      // Convert documents to list of maps
      List<Map<String, dynamic>> allBuddies = localBuddySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

      // Shuffle the list for randomness
      allBuddies.shuffle();

      // Take the first 5 entries after shuffling
      List<Map<String, dynamic>> randomBuddies = allBuddies.take(5).toList();

      // Fetch user details for each buddy
      List<Future<Map<String, dynamic>>> userFutures = randomBuddies.map((buddy) async {
        String userID = buddy['userID']; // Assuming userID is the field name in localBuddy
        DocumentSnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').doc(userID).get();
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

        // Combine buddy and user data
        return {
          ...buddy,
          'userName': userData?['name'], // Assuming 'name' is the field in users
          'profileImage': userData?['profileImage'], // Assuming 'profileImage' is the field in users
        };
      }).toList();

      // Wait for all user details to be fetched
      List<Map<String, dynamic>> buddiesWithUserDetails = await Future.wait(userFutures);

      // Assign the combined list to a state variable for use in your UI
      localBuddyList = buddiesWithUserDetails; // Define localBuddyList in your state

    } catch (e) {
      print("Error fetching Local Buddies: $e");
    } finally {
      setState(() {
        isFecthingLocalBuddy = false; // Update the loading state
      });
    }
  }

  Future<void> _fetchNotificationCount() async {
    try {
      // Query the notification collection for documents where receiverID matches widget.userID
      final querySnapshot = await FirebaseFirestore.instance
          .collection('notification')
          .where('receiverID', isEqualTo: widget.userId)
          .where('isRead', isEqualTo: 0)
          .get();
      
      print("Documents fetched: ${querySnapshot.docs.length}");

      // Check if there are any documents in the result
      setState(() {
        hasNoti = querySnapshot.docs.isNotEmpty;
      });
    } catch (e) {
      // Handle errors if needed
      print("Error fetching notification count: $e");
      setState(() {
        hasNoti = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Widget> _screens = [
      Container(
        padding: EdgeInsets.all(10),
        child: SingleChildScrollView(  // Wrap the Column with SingleChildScrollView
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Explore 💡",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal, // Enable horizontal scrolling
                child: Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => CarRentalHomepageScreen(userId: widget.userId))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white, // Button background color
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Rounded corners
                          side: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        ),
                        minimumSize: Size(screenWidth * 0.35, screenHeight * 0.1)
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Image(
                            image: AssetImage("images/car-rental.png"),
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            color: Color(0xFF467BA1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Car Rental",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF467BA1),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 10), // Add spacing between buttons if necessary
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => LocalBuddyHomepageScreen(userId: widget.userId))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        ),
                        minimumSize: Size(screenWidth * 0.35, screenHeight * 0.1)
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Image(
                            image: AssetImage("images/location.png"),
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            color: Color(0xFF467BA1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Local Buddy",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF467BA1),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => ViewCountryScreen(userId: widget.userId))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        ),
                        minimumSize: Size(screenWidth * 0.35, screenHeight * 0.1)
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Image(
                            image: AssetImage("images/tour-guide.png"),
                            width: screenWidth * 0.1,
                            height: screenWidth * 0.1,
                            color: Color(0xFF467BA1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Group Tour",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF467BA1),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                    SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => LanguageTranslatorScreen(userId: widget.userId))
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        ),
                        minimumSize: Size(screenWidth * 0.35, screenHeight * 0.1)
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 10),
                          Icon(
                            Icons.translate,
                            size: screenWidth * 0.1,
                            color: Color(0xFF467BA1),
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Translator",
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF467BA1),
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                "Country ✈️",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Display loading indicator or country list
              if (isFetchingCountry) 
                Center(child: CircularProgressIndicator())
              else if (countryList.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Loop through your list of country data and create each country card
                      for (var country in countryList)
                        Padding(
                          padding: const EdgeInsets.only(right: 10), // Spacing between cards
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ViewCityScreen(
                                    userId: widget.userId,
                                    countryName: country['name'],
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: screenWidth * 0.35, // Set width for each card
                              height: screenWidth * 0.35,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: NetworkImage(country['countryImage']), // Use country image
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.center,
                                    child: Container(
                                      color: Colors.white.withOpacity(0.7),
                                      width: double.infinity,
                                      height: 50,
                                      alignment: Alignment.center,
                                      child: Text(
                                        country['name'],
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 18,
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
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Center(child: Text("No countries found.")),
              SizedBox(height: 20),
              Text(
                "Car Rental 🚗",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Display loading indicator or country list
              if (isFecthingCarRental) 
                Center(child: CircularProgressIndicator(color: primaryColor,))
              else if (carRentalList.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Loop through your list of car rental data and create each card
                      for (var carRental in carRentalList)
                        Padding(
                          padding: const EdgeInsets.only(right: 10), // Spacing between cards
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to the view screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CarRentalDetailsScreen(
                                    userId: widget.userId, 
                                    carId: carRental['carID'], 
                                    fromAppLink: "false"
                                  )
                                ),
                              );
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              width: screenWidth * 0.5,
                              height: screenWidth * 0.45,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFCBE7EA).withOpacity(0.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center, // Center children horizontally
                                children: [
                                  // Centered car image
                                  Container(
                                    width: screenWidth * 0.35,
                                    height: screenHeight * 0.12,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(carRental['carImage']),
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Container(
                                    alignment: Alignment.centerLeft,
                                    // width: 155,
                                    child: Text(
                                      '${carRental['carModel']} - ${carRental['carType']}',
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.left, // Center text within the container
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between elements
                                    children: [
                                      Text(
                                        "Maximum ${carRental['seat']} 👤",
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'RM${(carRental['pricePerDay'] ?? 0).toStringAsFixed(0)}/day',
                                        style: TextStyle(
                                          color: Colors.black,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Center(child: Text("No car rentals found.")),
              SizedBox(height: 20),
              Text(
                "Local Buddy 🙋🏻‍♀️",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Display loading indicator or country list
              if (isFecthingLocalBuddy) 
                Center(child: CircularProgressIndicator(color: primaryColor,))
              else if (localBuddyList.isNotEmpty)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Loop through your list of car rental data and create each card
                      for (var localBuddy in localBuddyList)
                        Padding(
                          padding: const EdgeInsets.only(right: 10), // Spacing between cards
                          child: GestureDetector(
                            onTap: () {
                              // Navigate to the view screen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LocalBuddyDetailsScreen(
                                    userId: widget.userId,
                                    localBuddyId: localBuddy['localBuddyID'],
                                    fromAppLink: "false",
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                              width: screenWidth * 0.5,
                              height: screenWidth * 0.55,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Color(0xFFCBE7EA).withOpacity(0.5),
                                image: DecorationImage(
                                  image: localBuddy['profileImage'] != null 
                                      ? NetworkImage(localBuddy['profileImage']) 
                                      : AssetImage('images/profile.png'), // Placeholder image
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: Alignment.bottomCenter,
                                    child: Container(
                                      width: double.infinity,
                                      height: 70,
                                      color: Colors.white.withOpacity(0.8),
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(horizontal: 10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              localBuddy['userName'] ?? "No Name",
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.w700,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0.5, 0.5),
                                                    color: Colors.black87,
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                            // SizedBox(height: 10),
                                            Text(
                                              'Live in: ${localBuddy['locationArea'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0.5, 0.5),
                                                    color: Colors.black87,
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                            // SizedBox(height: 10),
                                            Text(
                                              'Language Spoken: ${localBuddy['languageSpoken'] ?? ''}',
                                              style: const TextStyle(
                                                color: Colors.black,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w500,
                                                shadows: [
                                                  Shadow(
                                                    offset: Offset(0.5, 0.5),
                                                    color: Colors.black87,
                                                  ),
                                                ],
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              )
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              else
                Center(child: Text("No local buddy found.")),
            ],
          ),
        ),
      ),

      ItineraryScreen(userId: widget.userId,),
      ChatScreen(userId: widget.userId),
      BookingsScreen(userID: widget.userId),
      AccountScreen(userId: widget.userId),
    ];

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_screenTitles[currentPageIndex]),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        automaticallyImplyLeading: false,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (context) => NotificationScreen(userId: widget.userId, isUser: true,))
                  );
                },
              ),
              if (hasNoti)
                Positioned(
                  right:14,
                  top:12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: currentPageIndex,
        onTap: _onNavBarTap,
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: _screens,
      ),
    );
  }
}

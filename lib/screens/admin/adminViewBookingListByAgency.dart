import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewBookingDetails.dart';
import 'package:assignment_tripmate/screens/admin/adminViewBookingListMainpage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminViewBookingListByAgentScreen extends StatefulWidget {
  final String userId;
  final String agentID;
  final String agencyName;

  const AdminViewBookingListByAgentScreen({
    super.key, 
    required this.userId,
    required this.agentID,
    required this.agencyName
  });

  @override
  State<AdminViewBookingListByAgentScreen> createState() => _AdminViewBookingListByAgentScreenState();
}

class _AdminViewBookingListByAgentScreenState extends State<AdminViewBookingListByAgentScreen> {
  
  List<TravelAgentTourBookingList> tourBookingList = [];
  List<TravelAgentCarRentalBookingList> carRentalBookingList = [];
  List<TravelAgentTourBookingList> filteredTourBookingList = [];
  List<TravelAgentCarRentalBookingList> filteredCarRentalBookingList = [];
  bool isFetchingTour = false;
  bool isFetchingCarRental = false;

  @override
  void initState() {
    super.initState();
    _fetchTourBookingList();
    _fetchCarRentalBookingList();
  }

  Future<void> _fetchTourBookingList() async {
    setState(() {
      isFetchingTour = true;
    });

    try {
      // Fetch all tour packages uploaded by the current user
      CollectionReference tourRef = FirebaseFirestore.instance.collection('tourPackage');
      QuerySnapshot querySnapshot = await tourRef.where('agentID', isEqualTo: widget.agentID).get();

      List<TravelAgentTourBookingList> tourBookingLists = [];

      // Loop through each tour package
      for (var doc in querySnapshot.docs) {
        // Extract tour details
        TravelAgentTourBookingList tourPackage = TravelAgentTourBookingList.fromFirestore(doc);

        // Fetch all bookings related to the current tourID
        CollectionReference tourBookingRef = FirebaseFirestore.instance.collection('tourBooking');
        QuerySnapshot tourBookingSnapshot = await tourBookingRef.where('tourID', isEqualTo: tourPackage.tourID).get();

        // Sum the total number of bookings for the current tour package
        int totalBookingCount = tourBookingSnapshot.size;

        // Update the totalBookingNumber for the tourPackage
        tourPackage.totalBookingNumber = totalBookingCount;

        // Add the tour package with booking info to the list
        tourBookingLists.add(tourPackage);
      }

      // After fetching all data, update the state
      setState(() {
        isFetchingTour = false;
        // Update the list with fetched data (assuming you have a list for display)
        tourBookingList = tourBookingLists;
        filteredTourBookingList = tourBookingList;
      });

    } catch (e) {
      setState(() {
        isFetchingTour = false;
      });
      print('Error fetching tour booking list: $e');
    }
  }

  Future<void> _fetchCarRentalBookingList() async {
    setState(() {
      isFetchingCarRental = true;
    });

    try {
      // Fetch all car rental uploaded by the current user
      CollectionReference carRentalRef = FirebaseFirestore.instance.collection('car_rental');
      QuerySnapshot querySnapshot = await carRentalRef.where('agencyID', isEqualTo: widget.agentID).get();

      List<TravelAgentCarRentalBookingList> carRentalBookingLists = [];

      // Loop through each car rental
      for (var doc in querySnapshot.docs) {
        // Extract car details
        TravelAgentCarRentalBookingList carRental = TravelAgentCarRentalBookingList.fromFirestore(doc);

        bool haveCancelBooking = false;

        // Fetch all bookings related to the current carID
        CollectionReference carRentalBookingRef = FirebaseFirestore.instance.collection('carRentalBooking');
        QuerySnapshot carRentalBookingSnapshot = await carRentalBookingRef.where('carID', isEqualTo: carRental.carRentalID).get();

        for (var doc in carRentalBookingSnapshot.docs) {
          if ((doc['bookingStatus'] == 2 && doc['isRefund'] == 0) || (doc['isCheckCarCondition'] == 1 && doc['isRefundDeposit'] == 0)) {
            haveCancelBooking = true; // Set to true if any status is 2
            break; // No need to continue checking
          }
        }

        // Sum the total number of bookings for the current car rental
        int totalBookingCount = carRentalBookingSnapshot.size;

        // Update the totalBookingNumber for the carRental
        carRental.totalBookingNumber = totalBookingCount;
        carRental.haveCancelBooking = haveCancelBooking;

        // Add the tour package with booking info to the list
        carRentalBookingLists.add(carRental);
      }

      // After fetching all data, update the state
      setState(() {
        isFetchingCarRental = false;
        // Update the list with fetched data (assuming you have a list for display)
        carRentalBookingList = carRentalBookingLists;
        filteredCarRentalBookingList = carRentalBookingList;
      });

    } catch (e) {
      setState(() {
        isFetchingCarRental = false;
      });
      print('Error fetching tour booking list: $e');
    }
  }

  // Search function for tour bookings
  void onTourSearch(String value) {
    setState(() {
      filteredTourBookingList = tourBookingList
          .where((booking) =>
              booking.tourName.toUpperCase().contains(value.toUpperCase()))
          .toList();
    });
  }

  // Search function for car rentals
  void onCarRentalSearch(String value) {
    setState(() {
      filteredCarRentalBookingList = carRentalBookingList
          .where((booking) =>
              booking.carName.toUpperCase().contains(value.toUpperCase()))
          .toList();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 241, 246, 249),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: const Text("Booking"),
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AdminViewBookingListMainpageScreen(userId: widget.userId))
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Container(
              height: 50,
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(
                    child: Text("Tour Package"),
                  ),
                  Tab(
                    child: Text("Car Rental"),
                  )
                ],
                labelColor: primaryColor,
                indicatorColor: primaryColor,
                indicatorWeight: 2,
                unselectedLabelColor: Color(0xFFA4B4C0), // Unselected tab text color
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelStyle: TextStyle(fontSize: defaultFontSize),
                labelStyle: TextStyle(fontSize: defaultFontSize),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              padding: EdgeInsets.all(15.0),
              child: isFetchingTour
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : tourBookingList.isEmpty
                ? Center(child: Text("No tour booking record found in the system.", style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                :  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agencyName,
                        style: TextStyle(
                          fontSize: defaultLabelFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 60,
                        child: TextField(
                          onChanged: (value) => onTourSearch(value),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
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
                            hintText: "Search tour name...",
                            hintStyle: TextStyle(
                              fontSize: defaultFontSize,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredTourBookingList.length,
                          itemBuilder: (context, index) {
                            return TourBookingComponent(tourBooking: filteredTourBookingList[index]);
                          }
                        )
                      )
                    ],
                  )
            ),
            Container(
              padding: EdgeInsets.all(15.0),
              child: isFetchingCarRental
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : carRentalBookingList.isEmpty
                ? Center(child: Text("No car rental booking record found in the system.", style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                :  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agencyName,
                        style: TextStyle(
                          fontSize: defaultLabelFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        ),
                      ),
                      SizedBox(height: 10),
                      Container(
                        height: 60,
                        child: TextField(
                          onChanged: (value) => onCarRentalSearch(value),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
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
                            hintText: "Search car model...",
                            hintStyle: TextStyle(
                              fontSize: defaultFontSize,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items at the top
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0), // Adjust the icon's vertical position
                            child: Icon(Icons.circle, color: Colors.red, size: 8),
                          ),
                          SizedBox(width: 5), // Space between icon and text
                          Expanded(
                            child: Text(
                              "means cancellation/ deposit refund request exist in the car rental booking list, you need to issue the refund.",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: null,
                              overflow: TextOverflow.visible,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredCarRentalBookingList.length,
                          itemBuilder: (context, index) {
                            return CarRentalBookingComponent(carRentalBooking: filteredCarRentalBookingList[index]);
                          }
                        )
                      )
                    ],
                  )
            ),
          ],
        ),
      )
    );
  }

  Widget TourBookingComponent({required TravelAgentTourBookingList tourBooking}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminViewBookingDetailsScreen(
              userId: widget.userId,
              tourID: tourBooking.tourID,
              totalBookingNumber: tourBooking.totalBookingNumber,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 3), // Changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
              child: Text(
                "Tour Package ID: ${tourBooking.tourID}",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(10.0), // Added padding for better spacing
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Ensure the image displays correctly with a fallback
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Rounded corners for the image
                    child: Image.network(
                      tourBooking.tourImage,
                      width: getScreenWidth(context) * 0.18,
                      height: getScreenHeight(context) * 0.13,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: getScreenWidth(context) * 0.18,
                          height: getScreenHeight(context) * 0.13,
                          color: Colors.grey, // Grey background
                          alignment: Alignment.center,
                          child: Text(
                            "Image N/A",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded( // Use Expanded to take the remaining space
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tourBooking.tourName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: defaultFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.book, color: primaryColor, size: 18), // Icon for tour bookings
                            SizedBox(width: 5),
                            Text(
                              "Total Bookings: ${tourBooking.totalBookingNumber}",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget CarRentalBookingComponent({required TravelAgentCarRentalBookingList carRentalBooking}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminViewBookingDetailsScreen(
              userId: widget.userId,
              carRentalID: carRentalBooking.carRentalID,
              totalBookingNumber: carRentalBooking.totalBookingNumber,
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Rounded corners
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              spreadRadius: 1,
              offset: Offset(0, 3), // Changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300, width: 1.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Car Rental ID: ${carRentalBooking.carRentalID}",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (carRentalBooking.haveCancelBooking)
                    Icon(Icons.circle, color: Colors.red, size: 10),
                ],
              )
            ),
            Container(
              padding: EdgeInsets.all(10.0), // Added padding for better spacing
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Ensure the image displays correctly with a fallback
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8), // Rounded corners for the image
                    child: Image.network(
                      carRentalBooking.carImage,
                      width: getScreenWidth(context) * 0.3,
                      height: getScreenHeight(context) * 0.15,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: getScreenWidth(context) * 0.3,
                          height: getScreenHeight(context) * 0.15,
                          color: Colors.grey, // Grey background
                          alignment: Alignment.center,
                          child: Text(
                            "Image N/A",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded( // Use Expanded to take the remaining space
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          carRentalBooking.carName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: defaultFontSize,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(Icons.directions_car, color: Colors.green, size: 18), // Icon for car bookings
                            SizedBox(width: 5),
                            Text(
                              "Total Bookings: ${carRentalBooking.totalBookingNumber}",
                              style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

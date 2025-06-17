import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewBookingDetails.dart';
import 'package:assignment_tripmate/screens/admin/adminViewBookingListByAgency.dart';
import 'package:assignment_tripmate/screens/admin/homepage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminViewBookingListMainpageScreen extends StatefulWidget {
  final String userId;

  const AdminViewBookingListMainpageScreen({
    super.key, 
    required this.userId,
  });

  @override
  State<AdminViewBookingListMainpageScreen> createState() => _AdminViewBookingListMainpageScreenState();
}

class _AdminViewBookingListMainpageScreenState extends State<AdminViewBookingListMainpageScreen> {

  List<AdminLocalBuddyBookingList> localBuddyList = [];
  List<AdminAgencyList> agencyList = [];
  List<AdminLocalBuddyBookingList> filteredLocalBuddyList = [];
  List<AdminAgencyList> filteredAgencyList = [];
  bool isFetchingLocalBuddyList = false;
  bool isFetchingAgencyList = false;
  
  @override
  void initState() {
    super.initState();
    _fetchAgencyList();
    _fetchLocalBuddyList();
  }

  Future<void> _fetchAgencyList() async {
    setState(() {
      isFetchingAgencyList = true;
    });
    try {
      CollectionReference agencyRef = FirebaseFirestore.instance.collection('travelAgent');
      QuerySnapshot agencySnapshot = await agencyRef.where('accountApproved', isEqualTo: 1).get();

      List<AdminAgencyList> agencyLists = [];

      for (var doc in agencySnapshot.docs) {
        AdminAgencyList agency = AdminAgencyList.fromFirestore(doc);

        // Reset the haveCancelBooking flag for each agency
        bool haveCancelBooking = false;

        // Fetch tour packages for the current agent
        QuerySnapshot tourPackagesSnapshot = await FirebaseFirestore.instance
            .collection('tourPackage')
            .where('agentID', isEqualTo: agency.agentID)
            .get();

        List<String> tourIDs = [];
        for (var tourDoc in tourPackagesSnapshot.docs) {
          tourIDs.add(tourDoc.id); // Collecting tour IDs
        }

        // Now fetch tour bookings for these tour IDs
        int totalTourBookingNumber = 0;
        if (tourIDs.isNotEmpty) {
          QuerySnapshot tourBookingsSnapshot = await FirebaseFirestore.instance
              .collection('tourBooking')
              .where('tourID', whereIn: tourIDs)
              .get();

          // Count the total bookings for these tours
          totalTourBookingNumber = tourBookingsSnapshot.docs.length;

        }

        // Set the total tour booking number
        agency.totalTourBookingNumber = totalTourBookingNumber;

        // Fetch car rentals for the current agent
        QuerySnapshot carSnapshot = await FirebaseFirestore.instance
            .collection('car_rental')
            .where('agencyID', isEqualTo: agency.agentID)
            .get();

        List<String> carIDs = [];
        for (var carDoc in carSnapshot.docs) {
          carIDs.add(carDoc.id); // Collecting car IDs
        }

        int totalCarBookingNumber = 0;
        if (carIDs.isNotEmpty) {
          QuerySnapshot carBookingsSnapshot = await FirebaseFirestore.instance
              .collection('carRentalBooking')
              .where('carID', whereIn: carIDs)
              .get();

          totalCarBookingNumber = carBookingsSnapshot.docs.length;

          // Check for any booking status of 2
          for (var bookingDoc in carBookingsSnapshot.docs) {
            if ((bookingDoc['bookingStatus'] == 2 && bookingDoc['isRefund'] == 0) || bookingDoc['isCheckCarCondition'] == 1 && bookingDoc['isRefundDeposit'] == 0) {
              haveCancelBooking = true; // Set to true if any status is 2
              break; // No need to continue checking
            }
          }
        }

        // Set the total car booking number
        agency.totalCarBookingNumber = totalCarBookingNumber;

        // Set the final haveCancelBooking flag for the agency
        agency.haveCancelBooking = haveCancelBooking;

        // Add the agency to the list
        agencyLists.add(agency);
      }

      // Update your state with the agency list
      setState(() {
        agencyList = agencyLists;
        filteredAgencyList = agencyList;
      });

    } catch (e) {
      print("Error in fetching agency list: $e");
    } finally {
      setState(() {
        isFetchingAgencyList = false;
      });
    }
  }

  Future<void> _fetchLocalBuddyList() async {
    setState(() {
      isFetchingLocalBuddyList = true;
    });
    try {
      CollectionReference LBRef = FirebaseFirestore.instance.collection('localBuddy');
      QuerySnapshot querySnapshot = await LBRef.where('registrationStatus', isEqualTo: 2).get();

      List<AdminLocalBuddyBookingList> buddyBookingLists = [];

      for (var doc in querySnapshot.docs) {
        AdminLocalBuddyBookingList localBuddy = AdminLocalBuddyBookingList.fromFirestore(doc);

        bool haveCancelBooking = false;

        CollectionReference localBuddyBookingRef = FirebaseFirestore.instance.collection('localBuddyBooking');
        QuerySnapshot localBuddyBookingSnapshot = await localBuddyBookingRef.where('localBuddyID', isEqualTo: localBuddy.localBuddyID).get();

        for(var doc in localBuddyBookingSnapshot.docs){
          if(doc['bookingStatus'] == 2 && doc['isRefund'] == 0){
            haveCancelBooking = true;
            break;
          }
        }

        DocumentReference buddyRef = FirebaseFirestore.instance.collection('users').doc(localBuddy.userID);
        DocumentSnapshot buddyDoc = await buddyRef.get();

        int totalBookingCount = localBuddyBookingSnapshot.size;
        localBuddy.totalBookingNumber = totalBookingCount;
        localBuddy.haveCancelBooking = haveCancelBooking;

        if (buddyDoc.exists) {
          Map<String, dynamic>? data = buddyDoc.data() as Map<String, dynamic>?;

          localBuddy.localBuddyName = data?['name'] ?? ''; // Default to empty string if null
          localBuddy.localBuddyImage = data?['profileImage'] ?? ''; // Default to empty string if null
        } else {
          // If the buddyDoc doesn't exist, set default values
          localBuddy.localBuddyName = 'Unknown'; // or some default value
          localBuddy.localBuddyImage = 'default_image_url'; // or some placeholder image URL
        }

        buddyBookingLists.add(localBuddy);
      }

      setState(() {
        localBuddyList = buddyBookingLists;
        filteredLocalBuddyList = localBuddyList;
      });
    } catch (e) {
      print('Error fetching local buddy booking list: $e');
    } finally {
      setState(() {
        isFetchingLocalBuddyList = false;
      });
    }
  }

  // Search function for agency list
  void onAgencySearch(String value) {
    setState(() {
      filteredAgencyList = agencyList
          .where((booking) =>
              booking.agencyName.toUpperCase().contains(value.toUpperCase()))
          .toList();
    });
  }

  // Search function for local buddy booking
  void onLocalBuddySearch(String value) {
    setState(() {
      filteredLocalBuddyList = localBuddyList
          .where((booking) =>
              booking.localBuddyName.toUpperCase().contains(value.toUpperCase()))
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
                MaterialPageRoute(builder: (context) => AdminHomepageScreen(userId: widget.userId))
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
                    child: Text("Tour Package/Car Rental"),
                  ),
                  Tab(
                    child: Text("Local Buddy"),
                  )
                ],
                labelColor: primaryColor,
                indicatorColor: primaryColor,
                indicatorWeight: 2,
                unselectedLabelColor: Color(0xFFA4B4C0), // Unselected tab text color
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelStyle: TextStyle(fontSize: defaultFontSize),
                labelStyle: TextStyle(fontSize: defaultFontSize, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            Container(
              padding: EdgeInsets.all(15.0),
              child: isFetchingAgencyList
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : agencyList.isEmpty
                ? Center(child: Text("No agency record in the system.", style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                :  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 60,
                        child: TextField(
                          onChanged: (value) => onAgencySearch(value),
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
                            hintText: "Search agency name...",
                            hintStyle: TextStyle(
                              fontSize: defaultFontSize,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "***Note: The agency list only showed approved agency.***",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 5),
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
                              "means cancellation exist in the agency booking list, you need to issue the refund. Only car rental bookings require handling the cancellation.",
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
                          itemCount: filteredAgencyList.length,
                          itemBuilder: (context, index) {
                            return AgencyListComponent(agency: filteredAgencyList[index]);
                          }
                        )
                      )
                    ],
                  )
            ),
            Container(
              padding: EdgeInsets.all(15.0),
              child: isFetchingLocalBuddyList
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : localBuddyList.isEmpty
                ? Center(child: Text("No local buddy booking in the system.", style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                : Column(
                    children: [
                      Container(
                        height: 60,
                        child: TextField(
                          onChanged: (value) => onLocalBuddySearch(value),
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
                            hintText: "Search local buddy name...",
                            hintStyle: TextStyle(
                              fontSize: defaultFontSize,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        "***Note: The booking list only showed approved local buddy.***",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: 5),
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
                              "means cancellation exist in the local buddy booking list, you need to issue the refund.",
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
                          itemCount: filteredLocalBuddyList.length,
                          itemBuilder: (context, index) {
                            return BuddyBookingComponent(buddyBooking: filteredLocalBuddyList[index]);
                          }
                        )
                      )
                    ],
                  )
            )
          ],
        ),
      ),
    );
  }

  Widget AgencyListComponent({required AdminAgencyList agency}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminViewBookingListByAgentScreen(
              userId: widget.userId,
              agentID: agency.agentID,
              agencyName: agency.agencyName,
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
              offset: Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(10.0),
              alignment: Alignment.centerLeft,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300, width: 1.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Agency ID: ${agency.agencyID}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (agency.haveCancelBooking)
                    Icon(Icons.circle, color: Colors.red, size: 10), // Circle aligned to rightmost
                ],
              )
            ),
            Container(
              padding: EdgeInsets.all(10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Agency: ${agency.agencyName}",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 16, // Slightly larger font size
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.book, color: primaryColor, size: 18), // Icon for tour bookings
                                SizedBox(width: 5),
                                Text(
                                  "Total Tour Bookings: ${agency.totalTourBookingNumber}",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 5),
                            Row(
                              children: [
                                Icon(Icons.directions_car, color: Colors.green, size: 18), // Icon for car bookings
                                SizedBox(width: 5),
                                Text(
                                  "Total Car Bookings: ${agency.totalCarBookingNumber}",
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget BuddyBookingComponent({required AdminLocalBuddyBookingList buddyBooking}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminViewBookingDetailsScreen(
              userId: widget.userId,
              localBuddyID: buddyBooking.localBuddyID,
              localBuddyUserID: buddyBooking.userID,
              totalBookingNumber: buddyBooking.totalBookingNumber,
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
                    "Local Buddy ID: ${buddyBooking.localBuddyID}",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if(buddyBooking.haveCancelBooking)
                    Icon(Icons.circle, color: Colors.red, size: 10),
                ],
              )
            ),
            Container(
              padding: EdgeInsets.all(10.0), // Added padding for better spacing
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  // Check if the image URL is null or empty
                  buddyBooking.localBuddyImage.isNotEmpty
                    ? Container(
                        width: getScreenWidth(context) * 0.18,
                        height: getScreenHeight(context) * 0.13,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8), // Rounded corners for image
                          image: DecorationImage(
                            image: NetworkImage(buddyBooking.localBuddyImage),
                            fit: BoxFit.cover,
                          ),
                        ),
                      )
                    : Container(
                        width: getScreenWidth(context) * 0.18,
                        height: getScreenHeight(context) * 0.13,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey, // Grey background
                          borderRadius: BorderRadius.circular(8), // Rounded corners
                        ),
                        alignment: Alignment.center, // Center the text
                        child: Text(
                          "N/A",
                          style: TextStyle(
                            color: Colors.white, // Text color
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  SizedBox(width: 10),
                  Expanded( // Use Expanded to take the remaining space
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buddyBooking.localBuddyName,
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                            fontSize: 16, // Slightly larger font size
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 10),
                        Row(
                          children: [
                            Icon(Icons.book, color: primaryColor, size: 18), // Icon for tour bookings
                            SizedBox(width: 5),
                            Text(
                              "Total Bookings: ${buddyBooking.totalBookingNumber}",
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

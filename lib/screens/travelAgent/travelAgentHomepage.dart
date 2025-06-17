import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/admin_bottom_nav_bar.dart';
import 'package:assignment_tripmate/screens/notification.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentAccountPage.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewAnalyticsChart.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewBookingList.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewCarInfo.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewCountry.dart';
import 'package:assignment_tripmate/screens/user/chatPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TravelAgentHomepageScreen extends StatefulWidget {
  final String userId;

  const TravelAgentHomepageScreen({super.key, required this.userId});

  @override
  State<TravelAgentHomepageScreen> createState() => _TravelAgentHomepageScreenState();
}

class _TravelAgentHomepageScreenState extends State<TravelAgentHomepageScreen> {
  int currentPageIndex = 0;
  int currentAccountStatus = 0;
  String? rejectReason;
  bool isFetchingStatus = false;
  bool hasNoti = false;

  final List<String> _screenTitles = [
    "Tripmate",
    "Messages",
    "Account",
  ];

  @override
  void initState() {
    super.initState();
    _fetchNotificationCount();
    _fetchAccountStatus();
  }

  void _onNavBarTap(int index) {
    setState(() {
      currentPageIndex = index;
    });
  }

  Future<void>_fetchAccountStatus() async{
    setState((){
      isFetchingStatus = true;
    });
    try{
      DocumentReference userDoc = FirebaseFirestore.instance.collection('travelAgent').doc(widget.userId);
      DocumentSnapshot userSnapshot = await userDoc.get();

      if(userSnapshot.exists){
        Map<String, dynamic>? data = userSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          currentAccountStatus = data?['accountApproved'] ?? 0;
          rejectReason = data?['rejectReason'] ?? '';
          isFetchingStatus = false;
        });
      }
    }catch(e){
      setState(() {
        isFetchingStatus = false;
      });
      print('Error fetching account status: $e');
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
    final List<Widget> _screens = [
      Center( // Wrap in Center to align content in the middle
        child: Column(
          mainAxisSize: MainAxisSize.min, // Align content in the vertical center
          children: [
            // Display text when accountStatus is 0
            currentAccountStatus == 0
            ? Padding(
                padding: const EdgeInsets.all(10.0), // External padding around the container
                child: Container(
                  padding: const EdgeInsets.all(10.0), // Internal padding inside the container
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 228, 243, 255),
                    border: Border.all(color: primaryColor, width: 2.0),
                  ),
                  child: Text(
                    "Note:\n"
                    "Your account is pending approve by admin. Some features may be disabled.",
                    style: TextStyle(
                      fontSize: defaultFontSize,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                ),
              )

            : currentAccountStatus == 2 && rejectReason != null
              ? Container(
                  padding: EdgeInsets.all(10.0),
                  margin: EdgeInsets.only(left:10, right:10),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 228, 243, 255),
                    border: Border.all(color: primaryColor, width: 2.0)
                  ),
                  child: Text(
                    "Note:\n"
                    "Your account is rejected by admin. Please check for the reject reason and update the details.\n"
                    "Reject reason: $rejectReason",
                    style: TextStyle(
                      fontSize: defaultFontSize,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.justify,
                  ),
                )
              : Container(),
            
            GridView.builder(
              shrinkWrap: true, // Make sure GridView doesn't take infinite height
              physics: NeverScrollableScrollPhysics(), // Prevent scrolling in GridView
              padding: const EdgeInsets.all(20.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Two buttons per row
                crossAxisSpacing: 20, // Horizontal spacing between buttons
                mainAxisSpacing: 25,  // Vertical spacing between buttons
                childAspectRatio: 1, // Keep square buttons
              ),
              itemCount: 4, // Number of items (buttons) in grid
              itemBuilder: (context, index) {
                final menuItems = [
                  {
                    'icon': currentAccountStatus == 1 ? 'images/countries.png' : 'images/countries_disable.png',
                    'label': 'Tour',
                    'onPressed': () {
                      if (currentAccountStatus != 0 && currentAccountStatus != 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TravelAgentViewCountryScreen(userId: widget.userId)),
                        );
                      }
                    },
                    'enabled': currentAccountStatus != 0 && currentAccountStatus != 2,
                  },
                  {
                    'icon': currentAccountStatus == 1 ?  'images/CarRentalIcon.png' : 'images/car-rental_disable.png',
                    'label': 'Car Rental',
                    'onPressed': () {
                      if (currentAccountStatus != 0 && currentAccountStatus != 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TravelAgentViewCarListingScreen(userId: widget.userId)),
                        );
                      }
                    },
                    'enabled': currentAccountStatus != 0 && currentAccountStatus != 2,
                  },
                  {
                    'icon': currentAccountStatus == 1 ?  'images/manage_booking.png' : 'images/booking_disable.png',
                    'label': 'Booking',
                    'onPressed': () {
                      if (currentAccountStatus != 0 && currentAccountStatus != 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TravelAgentViewBookingListScreen(userId: widget.userId)),
                        );
                      }
                    },
                    'enabled': currentAccountStatus != 0 && currentAccountStatus != 2,
                  },
                  {
                    'icon': currentAccountStatus == 1 ? 'images/report.png' : 'images/report_disable.png',
                    'label': 'Analytics Chart',
                    'onPressed': () {
                      if (currentAccountStatus != 0 && currentAccountStatus != 2) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => TravelAgentViewAnalyticsChartScreen(userId: widget.userId)),
                        );
                      }
                    },
                    'enabled': currentAccountStatus != 0 && currentAccountStatus != 2,
                  }
                ];

                return _buildMenuButton(
                  context,
                  icon: menuItems[index]['icon'] as String,
                  label: menuItems[index]['label'] as String,
                  onPressed: (currentAccountStatus == 0 || currentAccountStatus == 2) 
                      ? () {}  // Provide a no-op function to satisfy the VoidCallback type
                      : menuItems[index]['onPressed'] as VoidCallback,
                  isEnabled: menuItems[index]['enabled'] as bool,
                );
              },
            ),
          ],
        ),
      ),
      ChatScreen(userId: widget.userId),
      TravelAgentAccountScreen(userId: widget.userId),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(_screenTitles[currentPageIndex]),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
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
                    MaterialPageRoute(builder: (context) => NotificationScreen(userId: widget.userId, isTA: true))
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
      bottomNavigationBar: AdminCustomBottomNavBar(
        currentIndex: currentPageIndex,
        onTap: _onNavBarTap,
      ),
      body: IndexedStack(
        index: currentPageIndex,
        children: _screens,
      ),
    );
  }


  Widget _buildMenuButton(BuildContext context, {required String icon, required String label, required VoidCallback onPressed, required bool isEnabled}) {
    Color colors = isEnabled ? primaryColor : Colors.grey;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors, width: 2),
        ),
        elevation: 10,
        shadowColor: colors,
        minimumSize: Size(getScreenWidth(context) * 0.4, getScreenWidth(context) * 0.4)
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          isEnabled
          ? Image(
              image: AssetImage(icon),
              width: getScreenWidth(context) * 0.2, 
              height: getScreenWidth(context) * 0.2, 
            )
          :
          ImageIcon(
            AssetImage(icon),
            color: Colors.grey,
            size: getScreenWidth(context) * 0.2,
          ),
          // Image(
          //     image: AssetImage(icon),
          //     width: getScreenWidth(context) * 0.2, 
          //     height: getScreenWidth(context) * 0.2, 
          //   ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: colors,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

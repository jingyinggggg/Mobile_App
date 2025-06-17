import 'package:assignment_tripmate/screens/admin/adminAccountPage.dart';
import 'package:assignment_tripmate/screens/admin/adminManageWithdrawalRequestMainpage.dart';
import 'package:assignment_tripmate/screens/admin/adminViewAnalyticsMainpage.dart';
import 'package:assignment_tripmate/screens/admin/adminViewBookingListMainpage.dart';
import 'package:assignment_tripmate/screens/admin/admin_bottom_nav_bar.dart';
import 'package:assignment_tripmate/screens/admin/manageCarList.dart';
import 'package:assignment_tripmate/screens/admin/manageCountryList.dart';
import 'package:assignment_tripmate/screens/admin/manageUserList.dart';
import 'package:assignment_tripmate/screens/admin/registrationRequest.dart';
import 'package:assignment_tripmate/screens/notification.dart';
import 'package:assignment_tripmate/screens/user/chatPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminHomepageScreen extends StatefulWidget {
  final String userId;

  const AdminHomepageScreen({super.key, required this.userId});

  @override
  State<AdminHomepageScreen> createState() => _AdminHomepageScreenState();
}

class _AdminHomepageScreenState extends State<AdminHomepageScreen> {
  int currentPageIndex = 0;
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
  }

  void _onNavBarTap(int index) {
    setState(() {
      currentPageIndex = index;
    });
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
      Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // Two buttons per row
                  crossAxisSpacing: 20, // Horizontal spacing between buttons
                  mainAxisSpacing: 25,  // Vertical spacing between buttons
                  childAspectRatio: 1, // Buttons will be square
                ),
                itemCount: 7, // Total number of menu buttons
                itemBuilder: (context, index) {
                  final menuItems = [
                    {
                      'icon': 'images/countries.png',
                      'label': 'Tour',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminManageCountryListScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/CarRentalIcon.png',
                      'label': 'Car Listing',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminManageCarListScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/registration_request.png',
                      'label': 'Registration',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RegistrationRequestScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/manage_booking.png',
                      'label': 'Booking',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminViewBookingListMainpageScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/report.png',
                      'label': 'Analytics Chart',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminViewAnalyticsMainpageScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/withdrawal.png',
                      'label': 'Withdrawal Request',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminRevenueMainpageScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                    {
                      'icon': 'images/user-list.png',
                      'label': 'User List',
                      'onPressed': () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminManageUserListScreen(userId: widget.userId),
                          ),
                        );
                      },
                    },
                  ];
                  return _buildMenuButton(
                    context,
                    icon: menuItems[index]['icon'] as String,
                    label: menuItems[index]['label'] as String,
                    onPressed: menuItems[index]['onPressed'] as VoidCallback,
                  );
                },
              ),
            ],
          ),
        )
      ),
      ChatScreen(userId: widget.userId),
      AdminAccountScreen(userId: widget.userId),
    ];

    return Scaffold(
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
                    MaterialPageRoute(builder: (context) => NotificationScreen(userId: widget.userId, isAdmin: true,))
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

  Widget _buildMenuButton(BuildContext context, {required String icon, required String label, required VoidCallback onPressed}) {
    final screenWidth = MediaQuery.of(context).size.width;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFF467BA1), width: 2),
        ),
        minimumSize: Size(screenWidth * 0.4, screenWidth * 0.4), // 40% of screen width for the button
        elevation: 10,
        shadowColor: const Color(0xFF467BA1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image(
            image: AssetImage(icon),
            width: screenWidth * 0.2, // 20% of screen width for the icon
            height: screenWidth * 0.2, // 20% of screen width for the icon
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF467BA1),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

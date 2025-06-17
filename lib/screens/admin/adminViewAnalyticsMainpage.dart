import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/adminViewAnalyticsChart.dart";
import "package:assignment_tripmate/screens/admin/adminViewAnalyticsDetailsChart.dart";
import "package:assignment_tripmate/screens/admin/homepage.dart";
import "package:assignment_tripmate/utils.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";

class AdminViewAnalyticsMainpageScreen  extends StatefulWidget{
  final String userId;

  const AdminViewAnalyticsMainpageScreen ({
    super.key,
    required this.userId,
  });

  @override
  State<AdminViewAnalyticsMainpageScreen> createState() => _AdminViewAnalyticsMainpageScreenState();
}

class _AdminViewAnalyticsMainpageScreenState extends State<AdminViewAnalyticsMainpageScreen> {

  Map<String, int> localBuddyBookingByMonth = {};
  bool isFetchingLocalBuddyBooking = false;
  bool isFetchingLocalBuddyList = false;
  bool isFetchingAgencyList = false;
  int selectedYear = DateTime.now().year;
  List<AdminLocalBuddyBookingList> localBuddyList = [];
  List<AdminLocalBuddyBookingList> filteredLocalBuddyList = [];
  List<Map<String, dynamic>> agencyList = [];
  List<Map<String, dynamic>> filteredAgencyList = [];

  @override
  void initState() {
    super.initState();
    _initializeMonthlyData();
    _fetchLocalBuddyBookingList(selectedYear);
    _fetchAgencyList();
    _fetchLocalBuddyList();
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return; // Handle null case if necessary
    setState(() {
      selectedYear = newYear;
      _initializeMonthlyData();
      _fetchLocalBuddyBookingList(selectedYear);
      _fetchAgencyList();
     _fetchLocalBuddyList();
    });
  }

  void _initializeMonthlyData() {
    localBuddyBookingByMonth = {for (var i = 1; i <= 12; i++) DateFormat('MMM').format(DateTime(0, i)): 0};
  }

  Future<void> _fetchAgencyList() async {
    setState(() {
      isFetchingAgencyList = true;
    });
    try {
      CollectionReference agencyRef = FirebaseFirestore.instance.collection('travelAgent');
      QuerySnapshot agencySnapshot = await agencyRef.where('accountApproved', isEqualTo: 1).get();

      List<Map<String, dynamic>> agencyLists = agencySnapshot.docs.map((doc) {
        return doc.data() as Map<String, dynamic>;
      }).toList();

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


  Future<void> _fetchLocalBuddyBookingList(int year) async {
    setState(() {
      isFetchingLocalBuddyBooking = true;
    });

    try {

      CollectionReference carBookingRef = FirebaseFirestore.instance.collection('localBuddyBooking');
      QuerySnapshot carBookingSnapshot = await carBookingRef
          .get();

      for (var doc in carBookingSnapshot.docs) {
        // Assuming bookingDate is an array of timestamps
        List<Timestamp> bookingDates = List.from(doc['bookingDate'] ?? []);
        
        if (bookingDates.isNotEmpty) {
          // Get the first date in the array
          DateTime bookingDate = bookingDates.first.toDate();

          if (bookingDate.year == year) {
            String monthKey = DateFormat('MMM').format(bookingDate);
            localBuddyBookingByMonth[monthKey] = (localBuddyBookingByMonth[monthKey] ?? 0) + 1;
          }
        }
      }

      setState(() {
        isFetchingLocalBuddyBooking = false;
      });
    } catch (e) {
      setState(() {
        isFetchingLocalBuddyBooking = false;
      });
      print('Error fetching local buddy booking list: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching local buddy booking list: $e')),
      );
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

  List<FlSpot> _getDataPoints(Map<String, int> bookingData) {
    List<String> months = bookingData.keys.toList();
    if (months.isEmpty) {
      return [FlSpot(0, 0)]; // Prevent errors by returning a default point
    }
    return months.asMap().entries.map((entry) {
      int index = entry.key;
      String month = entry.value;
      return FlSpot(index.toDouble(), bookingData[month]?.toDouble() ?? 0); // Ensure you're using integers here
    }).toList();
  }

  double _getMaxYValue(Map<String, int> bookingData) {
    // Get the maximum value in the booking data
    int maxValue = bookingData.values.reduce((a, b) => a > b ? a : b);
    // Determine the appropriate maximum value for the y-axis
    if (maxValue > 25) {
      return (maxValue + 5 - (maxValue % 10)).toDouble(); // Round up to the next multiple of 10
    }
    return 25.0; // Default maximum
  }

  Widget _buildLineChart(List<FlSpot> dataPoints, String chartTitle) {
    double maxYValue = _getMaxYValue(localBuddyBookingByMonth); // Use tour bookings to determine max Y value
    return Column(
      children: [
        Text(
          chartTitle,
          style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 10),
        Container(
          height: 200, // Increased height to provide more space
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10), // Add horizontal padding
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1, // Show each month
                    getTitlesWidget: (value, _) {
                      List<String> months = localBuddyBookingByMonth.keys.toList();
                      return Padding(
                        padding: const EdgeInsets.only(top: 5), // Add some top padding
                        child: Text(months[value.toInt()], style: const TextStyle(color: Colors.black, fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20, // Increase reserved size for y-axis titles
                    interval: 5, // Set y-axis interval
                    getTitlesWidget: (value, _) {
                      return value == 0 
                          ? Text('0', style: const TextStyle(color: Colors.black, fontSize: 10))
                          : value > 0
                            ? Text(value.toInt().toString(), style: const TextStyle(color: Colors.black, fontSize: 10))
                            : Container(); // Return empty widget for negative values
                    },
                  ),
                ),
                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true),
              gridData: FlGridData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: dataPoints,
                  isCurved: false,
                  color: Colors.blue,
                  barWidth: 2,
                  belowBarData: BarAreaData(show: false),
                  dotData: FlDotData(show: true),
                ),
              ],
              maxY: maxYValue, // Set maximum y value dynamically
            ),
          ),
        ),
      ],
    );
  }

  List<String> getBestSellerLocalBuddy(List<AdminLocalBuddyBookingList> localBuddies) {
    if (localBuddies.isEmpty) return ["No rentals available"];

    // Find the maximum booking number
    int maxBookings = localBuddies.map((c) => c.totalBookingNumber).reduce((a, b) => a > b ? a : b);

    // Collect all car rental names with the maximum booking number
    return localBuddies
        .where((lb) => lb.totalBookingNumber == maxBookings)
        .map((lb) => lb.localBuddyName) // Replace 'carName' with the actual property for the car rental name
        .toList();
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

  void onAgencySearch(String value) {
    setState(() {
      filteredAgencyList = agencyList
          .where((booking) =>
              booking['companyName'].toUpperCase().contains(value.toUpperCase()))
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
          title: const Text("Analytics"),
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
          actions: [
            Theme(
              data: Theme.of(context).copyWith(
                canvasColor: Colors.black,
                textTheme: TextTheme(
                  titleMedium: TextStyle(color: Colors.white),
                ),
              ),
              child: DropdownButton<int>(
                value: selectedYear,
                items: List.generate(2, (index) {
                  int year = DateTime.now().year + index;
                  return DropdownMenuItem(value: year, child: Text(year.toString(), style: TextStyle(color: Colors.white)));
                }),
                onChanged: _onYearChanged,
                underline: Container(), // Remove underline if preferred
                iconEnabledColor: Colors.white,
              ),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Container(
              height: 50,
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(
                    child: Text("Agency"),
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
        body: isFetchingLocalBuddyBooking || isFetchingLocalBuddyList || isFetchingAgencyList
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : TabBarView(
          children: [
            agencyList.isEmpty
            ? Center(child: Text("No agency record in the system.", style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
            : Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 50,
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
                          fontSize: 12,
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
                      itemCount: filteredAgencyList.length,
                      itemBuilder: (context, index) {
                        return AgencyListComponent(agency: filteredAgencyList[index]);
                      }
                    )
                  )
                ],
              ),
            ),
            Padding(
                padding: const EdgeInsets.all(15.0),
                child: ListView(
                  children: [
                    _buildLineChart(_getDataPoints(localBuddyBookingByMonth), "Total Local Buddy Bookings"),
                    const SizedBox(height: 10),
                    Text(
                      "Best Seller Local Buddy Packages: ${getBestSellerLocalBuddy(filteredLocalBuddyList).join(", ")}",
                      style: TextStyle(
                        color: Colors.black, 
                        fontSize: defaultFontSize, 
                        fontWeight: FontWeight.w600
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      height: 50,
                      child: TextField(
                        onChanged: (value) => onLocalBuddySearch(value),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 15),
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
                          hintText: "Search local buddy name...",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...filteredLocalBuddyList.map((localBuddyBooking) {
                      return BuddyBookingComponent(
                        buddyBooking: localBuddyBooking,
                      );
                    }).toList(),
                  ],
                ),
              ),
          ]
        )
      )
    );    
  }

  Widget AgencyListComponent({required Map<String, dynamic> agency}) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminViewAnalyticsChartScreen(userId: widget.userId, agencyId: agency['id'])
        ),
      );
    },
    child: Container(
      margin: EdgeInsets.only(bottom: 16.0),
      padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Agency ID: ${agency['companyID']}",
            style: TextStyle(
              fontSize: defaultFontSize,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            agency['companyName'] ?? "Agency Name",
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: defaultLabelFontSize,
            ),
            overflow: TextOverflow.ellipsis,
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
            builder: (context) => AdminViewAnalyticsChartDetailScreen(
              userId: widget.userId, 
              year: selectedYear,
              localBuddyID: buddyBooking.localBuddyID,
              localBuddyName: buddyBooking.localBuddyName,
            )
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

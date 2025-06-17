import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewAnalyticsDetailsChart.dart';
import 'package:assignment_tripmate/screens/admin/adminViewAnalyticsMainpage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AdminViewAnalyticsChartScreen extends StatefulWidget {
  final String userId;
  final String agencyId;

  const AdminViewAnalyticsChartScreen({super.key, required this.userId, required this.agencyId});

  @override
  State<AdminViewAnalyticsChartScreen> createState() => _AdminViewAnalyticsChartScreenState();
}

class _AdminViewAnalyticsChartScreenState extends State<AdminViewAnalyticsChartScreen> {
  Map<String, int> tourBookingByMonth = {};
  Map<String, int> carRentalBookingByMonth = {};
  bool isFetchingTour = false;
  bool isFetchingTourList = false;
  bool isFetchingCarRental = false;
  bool isFetchingCarRentalList = false;
  int selectedYear = DateTime.now().year; // Default to the current year
  List<TravelAgentTourBookingList> tourBookingList = [];
  List<TravelAgentCarRentalBookingList> carRentalBookingList = [];
  List<TravelAgentTourBookingList> filteredTourBookingList = [];
  List<TravelAgentCarRentalBookingList> filteredCarRentalBookingList = [];

  @override
  void initState() {
    super.initState();
    _initializeMonthlyData();
    _fetchTourBookingList(selectedYear);
    _fetchCarRentalBookingList(selectedYear);
    _fetchTourList();
    _fetchCarRentalList();
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return; // Handle null case if necessary
    setState(() {
      selectedYear = newYear;
      _initializeMonthlyData();
      _fetchTourBookingList(selectedYear);
      _fetchCarRentalBookingList(selectedYear);
      _fetchTourList();
      _fetchCarRentalList();
    });
  }

  // Initializes each month in the map to 0
  void _initializeMonthlyData() {
    tourBookingByMonth = {for (var i = 1; i <= 12; i++) DateFormat('MMM').format(DateTime(0, i)): 0};
    carRentalBookingByMonth = {for (var i = 1; i <= 12; i++) DateFormat('MMM').format(DateTime(0, i)): 0};
  }

  Future<void> _fetchTourBookingList(int year) async {
    setState(() {
      isFetchingTour = true;
    });

    try {
      CollectionReference tourPackagesRef = FirebaseFirestore.instance.collection('tourPackage');
      QuerySnapshot tourPackagesSnapshot = await tourPackagesRef
          .where('agentID', isEqualTo: widget.agencyId)
          .get();

      List<String> tourIds = tourPackagesSnapshot.docs.map((doc) => doc.id).toList();

      if (tourIds.isNotEmpty) {
        CollectionReference tourBookingRef = FirebaseFirestore.instance.collection('tourBooking');
        QuerySnapshot tourBookingSnapshot = await tourBookingRef
            .where('tourID', whereIn: tourIds)
            .get();

        for (var doc in tourBookingSnapshot.docs) {
          DateTime bookingDate = (doc['bookingCreateTime'] as Timestamp).toDate();

          if (bookingDate.year == year) {
            String monthKey = DateFormat('MMM').format(bookingDate); // e.g., Jan, Feb
            tourBookingByMonth[monthKey] = (tourBookingByMonth[monthKey] ?? 0) + 1;
          }
        }
      }

      setState(() {
        isFetchingTour = false;
      });
    } catch (e) {
      setState(() {
        isFetchingTour = false;
      });
      print('Error fetching tour booking list: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tour booking list: $e')),
      );
    }
  }

  Future<void> _fetchCarRentalBookingList(int year) async {
    setState(() {
      isFetchingCarRental = true;
    });

    try {
      CollectionReference carPackagesRef = FirebaseFirestore.instance.collection('car_rental');
      QuerySnapshot carPackagesSnapshot = await carPackagesRef
          .where('agencyID', isEqualTo: widget.agencyId)
          .get();

      List<String> carIds = carPackagesSnapshot.docs.map((doc) => doc.id).toList();

      if (carIds.isNotEmpty) {
        CollectionReference carBookingRef = FirebaseFirestore.instance.collection('carRentalBooking');
        QuerySnapshot carBookingSnapshot = await carBookingRef
            .where('carID', whereIn: carIds)
            .get();

        for (var doc in carBookingSnapshot.docs) {
          // Assuming bookingDate is an array of timestamps
          List<Timestamp> bookingDates = List.from(doc['bookingDate'] ?? []);
          
          if (bookingDates.isNotEmpty) {
            // Get the first date in the array
            DateTime bookingDate = bookingDates.first.toDate();

            if (bookingDate.year == year) {
              String monthKey = DateFormat('MMM').format(bookingDate);
              carRentalBookingByMonth[monthKey] = (carRentalBookingByMonth[monthKey] ?? 0) + 1;
            }
          }
        }
      }

      setState(() {
        isFetchingCarRental = false;
      });
    } catch (e) {
      setState(() {
        isFetchingCarRental = false;
      });
      print('Error fetching car booking list: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching car booking list: $e')),
      );
    }
  }

  Future<void> _fetchTourList() async {
    setState(() {
      isFetchingTourList = true;
    });

    try {
      // Fetch all tour packages uploaded by the current user
      CollectionReference tourRef = FirebaseFirestore.instance.collection('tourPackage');
      QuerySnapshot querySnapshot = await tourRef.where('agentID', isEqualTo: widget.agencyId).get();

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
        isFetchingTourList = false;
        // Update the list with fetched data (assuming you have a list for display)
        tourBookingList = tourBookingLists;
        filteredTourBookingList = tourBookingList;
      });

    } catch (e) {
      setState(() {
        isFetchingTourList = false;
      });
      print('Error fetching tour booking list: $e');
    }
  }

  Future<void> _fetchCarRentalList() async {
    setState(() {
      isFetchingCarRentalList = true;
    });

    try {
      // Fetch all car rental uploaded by the current user
      CollectionReference carRentalRef = FirebaseFirestore.instance.collection('car_rental');
      QuerySnapshot querySnapshot = await carRentalRef.where('agencyID', isEqualTo: widget.agencyId).get();

      List<TravelAgentCarRentalBookingList> carRentalBookingLists = [];

      // Loop through each car rental
      for (var doc in querySnapshot.docs) {
        // Extract car details
        TravelAgentCarRentalBookingList carRental = TravelAgentCarRentalBookingList.fromFirestore(doc);

        // Fetch all bookings related to the current carID
        CollectionReference carRentalBookingRef = FirebaseFirestore.instance.collection('carRentalBooking');
        QuerySnapshot carRentalBookingSnapshot = await carRentalBookingRef.where('carID', isEqualTo: carRental.carRentalID).get();

        // Sum the total number of bookings for the current car rental
        int totalBookingCount = carRentalBookingSnapshot.size;

        // Update the totalBookingNumber for the carRental
        carRental.totalBookingNumber = totalBookingCount;

        // Add the tour package with booking info to the list
        carRentalBookingLists.add(carRental);
      }

      // After fetching all data, update the state
      setState(() {
        isFetchingCarRentalList = false;
        // Update the list with fetched data (assuming you have a list for display)
        carRentalBookingList = carRentalBookingLists;
        filteredCarRentalBookingList = carRentalBookingList;
      });

    } catch (e) {
      setState(() {
        isFetchingCarRentalList = false;
      });
      print('Error fetching car rental list: $e');
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

  Widget _buildLineChart(List<FlSpot> dataPoints, String chartTitle, Map<String, int> data) {
    double maxYValue = _getMaxYValue(data); // Use tour bookings to determine max Y value
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
                      List<String> months = data.keys.toList();
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
                  color: chartTitle == "Total Tour Bookings" ? Colors.blue : Colors.green,
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

  List<String> getBestSellerTourPackages(List<TravelAgentTourBookingList> tourBookings) {
    if (tourBookings.isEmpty) return ["No tours available"];

    // Find the maximum booking number
    int maxBookings = tourBookings.map((t) => t.totalBookingNumber).reduce((a, b) => a > b ? a : b);

    // Collect all tour names with the maximum booking number
    return tourBookings
        .where((tour) => tour.totalBookingNumber == maxBookings)
        .map((tour) => tour.tourName) 
        .toList();
  }

  List<String> getBestSellerCarRentals(List<TravelAgentCarRentalBookingList> carRentals) {
    if (carRentals.isEmpty) return ["No rentals available"];

    // Find the maximum booking number
    int maxBookings = carRentals.map((c) => c.totalBookingNumber).reduce((a, b) => a > b ? a : b);

    // Collect all car rental names with the maximum booking number
    return carRentals
        .where((car) => car.totalBookingNumber == maxBookings)
        .map((car) => car.carName) 
        .toList();
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
                MaterialPageRoute(builder: (context) => AdminViewAnalyticsMainpageScreen(userId: widget.userId)),
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
                  Tab(child: Text("Tour Package")),
                  Tab(child: Text("Car Rental")),
                ],
                labelColor: primaryColor,
                indicatorColor: primaryColor,
                indicatorWeight: 2,
                unselectedLabelColor: Color(0xFFA4B4C0),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelStyle: TextStyle(fontSize: defaultFontSize),
                labelStyle: TextStyle(fontSize: defaultFontSize),
              ),
            ),
          ),
        ),
        body: isFetchingTour || isFetchingCarRental || isFetchingTourList || isFetchingCarRentalList
        ? const Center(child: CircularProgressIndicator(color: primaryColor,))
        : TabBarView(
            children: [
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: ListView(
                  children: [
                    _buildLineChart(_getDataPoints(tourBookingByMonth), "Total Tour Bookings", tourBookingByMonth),
                    const SizedBox(height: 10),
                    // Best Seller Tour Packages
                    Text(
                      "Best Seller Tour Packages: ${getBestSellerTourPackages(tourBookingList).join(", ")}",
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
                        onChanged: (value) => onTourSearch(value),
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
                          hintText: "Search tour name...",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                          
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...filteredTourBookingList.map((tourBooking) {
                      return TourBookingComponent(
                        // key: ValueKey(tourBooking.id), // Ensure unique keys for dynamic lists
                        tourBooking: tourBooking,
                      );
                    }).toList(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: ListView(
                  children: [
                    _buildLineChart(_getDataPoints(carRentalBookingByMonth), "Total Car Rental Bookings", carRentalBookingByMonth),
                    const SizedBox(height: 10),
                    Text(
                      "Best Seller Car Rental Packages: ${getBestSellerCarRentals(carRentalBookingList).join(", ")}",
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
                        onChanged: (value) => onCarRentalSearch(value),
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
                          hintText: "Search car name...",
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...filteredCarRentalBookingList.map((carRentalBooking) {
                      return CarRentalBookingComponent(
                        carRentalBooking: carRentalBooking,
                      );
                    }).toList(),
                  ],
                ),
              ),
            ],
          ),

      ),
    );
  }


  Widget TourBookingComponent({required TravelAgentTourBookingList tourBooking}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AdminViewAnalyticsChartDetailScreen(userId: widget.userId,tourID: tourBooking.tourID,year: selectedYear, agencyID: widget.agencyId,)
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
              blurRadius: 10,
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
            builder: (context) => AdminViewAnalyticsChartDetailScreen(userId: widget.userId,carID: carRentalBooking.carRentalID, year: selectedYear, agencyID: widget.agencyId,)
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
                "Car Rental ID: ${carRentalBooking.carRentalID}",
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

import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/user/localBuddyViewAppointment.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:pie_chart/pie_chart.dart' as pie;

class LocalBuddyViewAnalyticsChartDetailScreen extends StatefulWidget {
  final String userId;
  final String localBuddyID;

  const LocalBuddyViewAnalyticsChartDetailScreen({
    super.key,
    required this.userId,
    required this.localBuddyID,
  });

  @override
  State<LocalBuddyViewAnalyticsChartDetailScreen> createState() =>
      _LocalBuddyViewAnalyticsChartDetailScreenState();
}

class _LocalBuddyViewAnalyticsChartDetailScreenState extends State<LocalBuddyViewAnalyticsChartDetailScreen> {

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> localBuddyBookingByMonth = {};
  int selectedYear = DateTime.now().year;
  bool isFetchingLocalBuddyBooking = false;

  @override
  void initState() {
    super.initState();
    _initializeMonthlyData();
    _fetchBookings();
  }

  void _onYearChanged(int? newYear) {
    if (newYear == null) return; // Handle null case if necessary
    setState(() {
      selectedYear = newYear;
      _initializeMonthlyData();
      _fetchBookings();
    });
  }

  void _initializeMonthlyData() {
    localBuddyBookingByMonth = {for (var i = 1; i <= 12; i++) DateFormat('MMM').format(DateTime(0, i)): 0};
  }

  Future<List<Map<String, dynamic>>> _fetchBookings() async {
    List<Map<String, dynamic>> bookings = [];
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('localBuddyBooking')
          .where('localBuddyID', isEqualTo: widget.localBuddyID)
          .get();

      // Initialize monthly data
      _initializeMonthlyData(); // Ensure this is called before processing bookings

      for (var doc in snapshot.docs) {
        List<Timestamp>? bookingDates = List.from(doc['bookingDate'] ?? []);
        if (bookingDates.isNotEmpty) {
          DateTime bookingDate = bookingDates.first.toDate();
          if (bookingDate.year == selectedYear) {
            String monthKey = DateFormat('MMM').format(bookingDate);
            localBuddyBookingByMonth[monthKey] = (localBuddyBookingByMonth[monthKey] ?? 0) + 1;
          }
        }
        bookings.add({
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        });
      }
    } catch (e) {
      print('Error fetching bookings: $e');
      // Optionally rethrow the error or handle it further
    }
    return bookings; // Return the list of bookings
  }


  List<FlSpot> _getDataPoints() {
    List<String> months = localBuddyBookingByMonth.keys.toList();
    if (months.isEmpty) {
      return [FlSpot(0, 0)]; // Prevent errors by returning a default point
    }
    return months.asMap().entries.map((entry) {
      int index = entry.key;
      String month = entry.value;
      return FlSpot(index.toDouble(), localBuddyBookingByMonth[month]?.toDouble() ?? 0); // Ensure you're using integers here
    }).toList();
  }

  double _getMaxYValue() {
    // Get the maximum value in the booking data
    int maxValue = localBuddyBookingByMonth.values.reduce((a, b) => a > b ? a : b);
    // Determine the appropriate maximum value for the y-axis
    if (maxValue > 25) {
      return (maxValue + 5 - (maxValue % 10)).toDouble(); // Round up to the next multiple of 10
    }
    return 25.0; // Default maximum
  }

  Widget _buildLineChart(List<FlSpot> dataPoints) {
    double maxYValue = _getMaxYValue(); // Use tour bookings to determine max Y value
    return Column(
      children: [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                MaterialPageRoute(builder: (context) => LocalBuddyViewAppointmentScreen(userId: widget.userId, localBuddyId: widget.localBuddyID,))
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
        ),
        body: FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchBookings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: primaryColor));
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final bookings = snapshot.data!;
            final totalBookings = bookings.length;
            if (totalBookings == 0) {
              return Center(child: Text("No bookings available."));
            }

            final upcomingBookings =
                bookings.where((b) => b['bookingStatus'] == 0).toList();
            final completedBookings =
                bookings.where((b) => b['bookingStatus'] == 1).toList();
            final cancelledBookings =
                bookings.where((b) => b['bookingStatus'] == 2).toList();

            // Prepare data for pie chart as percentages
            Map<String, double> dataMap = {
              "Completed": (completedBookings.length / totalBookings) * 100,
              "Upcoming": (upcomingBookings.length / totalBookings) * 100,
              "Cancelled": (cancelledBookings.length / totalBookings) * 100,
            };

            return SingleChildScrollView(
              child: Column(
                children: [
                  // Title section with fetched name
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text(
                      "Your appointment analytics chart in $selectedYear",
                      style: TextStyle(
                        fontSize: defaultLabelFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _buildLineChart(_getDataPoints()),
                  SizedBox(height: 10),
                  Divider(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Text(
                      "Pie Chart (All Time)",
                      style: TextStyle(
                        fontSize: defaultLabelFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 300,  // Set desired width
                    height: 150, // Set desired height
                    child: pie.PieChart(
                      dataMap: dataMap.map((key, value) => MapEntry(key, value)),
                      chartType: pie.ChartType.disc,
                      animationDuration: const Duration(milliseconds: 800),
                      colorList: [
                        Color.fromARGB(255, 179, 244, 181),
                        const Color.fromARGB(255, 249, 207, 144),
                        const Color.fromARGB(255, 255, 154, 147),
                      ],
                      chartRadius: MediaQuery.of(context).size.width / 3.0,
                      legendOptions: const pie.LegendOptions(
                        showLegends: true,
                        legendPosition: pie.LegendPosition.left,
                        legendShape: BoxShape.circle,
                        showLegendsInRow: false,
                        legendTextStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12, // Set legend font size
                        ),
                      ),
                      chartValuesOptions: pie.ChartValuesOptions(
                        showChartValues: true,
                        chartValueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 12
                        ),
                        decimalPlaces: 1, // Set how many decimal places you want
                        showChartValuesInPercentage: true, // This will display values as percentages
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 5),
                  // Summary Section
                  Text(
                    "Summary (All Time)",
                    style: TextStyle(
                      fontSize: defaultLabelFontSize,
                      color: Colors.black,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildSummaryRow("Completed Bookings:", completedBookings.length),
                        SizedBox(height: 10),
                        _buildSummaryRow("Upcoming Bookings:", upcomingBookings.length),
                        SizedBox(height: 10),
                        _buildSummaryRow("Cancelled Bookings:", cancelledBookings.length),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              )
            );
          },
        )
    );   
  }

  Widget _buildSummaryRow(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: defaultFontSize)),
        Text(count.toString(), style: const TextStyle(fontSize: defaultFontSize)),
      ],
    );
  }

}
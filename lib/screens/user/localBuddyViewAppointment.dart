import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';
import 'package:assignment_tripmate/screens/user/localBuddyViewAnalyticsChartDetails.dart';
import 'package:assignment_tripmate/screens/user/localBuddyViewAppointmentDetails.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LocalBuddyViewAppointmentScreen extends StatefulWidget {
  final String userId;
  final String localBuddyId;

  const LocalBuddyViewAppointmentScreen({
    super.key,
    required this.userId,
    required this.localBuddyId,
  });

  @override
  State<LocalBuddyViewAppointmentScreen> createState() =>
      _LocalBuddyViewAppointmentScreenState();
}

class _LocalBuddyViewAppointmentScreenState
    extends State<LocalBuddyViewAppointmentScreen> {
  Map<DateTime, List<localBuddyCustomerAppointment>> appointments = {};
  bool isFetchLoading = false;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fetchAppointmentList();
  }

  Future<void> _fetchAppointmentList() async {
    setState(() {
      isFetchLoading = true;
    });

    try {
      CollectionReference ref =
          FirebaseFirestore.instance.collection('localBuddyBooking');
      QuerySnapshot snapshot = await ref
          .where('localBuddyID', isEqualTo: widget.localBuddyId)
          .get();

      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          localBuddyCustomerAppointment appointment =
              localBuddyCustomerAppointment.fromFirestore(doc);

          // Get customer name
          CollectionReference custRef =
              FirebaseFirestore.instance.collection('users');
          QuerySnapshot querySnapshot =
              await custRef.where('id', isEqualTo: appointment.custID).get();

          if (querySnapshot.docs.isNotEmpty) {
            var userData =
                querySnapshot.docs.first.data() as Map<String, dynamic>?;
            appointment.custName = userData?['name'] ?? 'Unknown';
          } else {
            appointment.custName = 'Unknown';
          }

          for (var date in appointment.bookingDate) {
            DateTime normalized = DateTime(date.year, date.month, date.day);
            appointments[normalized] ??= [];
            appointments[normalized]!.add(appointment);
          }
        }

        appointments.forEach((date, list) {
          print("📅 $date:");
          for (var appt in list) {
            print("  - Booking ID: ${appt.localBuddyBookingID}, "
                  "Customer: ${appt.custName}, "
                  "Cust ID: ${appt.custID}");
          }
        });
      }
    } catch (e) {
      print("Error fetching appointments: $e");
    } finally {
      setState(() {
        isFetchLoading = false;
      });
    }
  }

  void _goToPreviousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _goToNextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Appointment"),
        centerTitle: true,
        backgroundColor: const Color(0xFFE57373),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: defaultAppBarTitleFontSize,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => UserHomepageScreen(
                  userId: widget.userId,
                  currentPageIndex: 4,
                ),
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_outlined,
                color: Colors.white, size: 25),
            tooltip: "Analytics Chart",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      LocalBuddyViewAnalyticsChartDetailScreen(
                    userId: widget.userId,
                    localBuddyID: widget.localBuddyId,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: isFetchLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendarHeader(),
                _buildCalendarGrid(),
                const Divider(height: 1),
                Expanded(child: _buildAppointmentsForSelectedDate()),
              ],
            ),
    );
  }

  Widget _buildCalendarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _goToPreviousMonth,
          ),
          Expanded(
            child: Center(
              child: Text(
                DateFormat.yMMMM().format(_focusedMonth),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _goToNextMonth,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final totalDays =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final daysBefore = firstDay.weekday % 7;
    final totalCells = daysBefore + totalDays;

    final List<DateTime?> calendarDays = List.generate(totalCells, (index) {
      if (index < daysBefore) return null;
      return DateTime(_focusedMonth.year, _focusedMonth.month,
          index - daysBefore + 1);
    });

    return Column(
      children: [
        // ✅ WEEKDAY LABELS
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.grey),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // ✅ DATE GRID
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: calendarDays.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
          ),
          itemBuilder: (context, index) {
            final date = calendarDays[index];

            final isToday = date != null &&
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month &&
                date.day == DateTime.now().day;

            final isSelected = date != null &&
                date.year == _selectedDate.year &&
                date.month == _selectedDate.month &&
                date.day == _selectedDate.day;

            final hasAppointment = date != null &&
                appointments.containsKey(
                    DateTime(date.year, date.month, date.day));

            Color? bgColor;
            Color? textColor;

            if (isSelected) {
              bgColor = primaryColor.withOpacity(0.3);
              textColor = Colors.black;
            } else if (isToday) {
              bgColor = primaryColor;
              textColor = Colors.white;
            }

            // If today but not selected
            if (!isSelected && isToday) {
              bgColor = null;
              textColor = Colors.blue;
            }

            return GestureDetector(
              onTap: () {
                if (date != null) {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                  border: isSelected
                      ? Border.all(color: primaryColor, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        date != null ? "${date.day}" : "",
                        style: TextStyle(color: textColor),
                      ),
                      if (hasAppointment)
                        const Icon(Icons.event, size: 12, color: Colors.green),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAppointmentsForSelectedDate() {
    final normalizedDate = DateTime(
        _selectedDate.year, _selectedDate.month, _selectedDate.day);
    final list = appointments[normalizedDate] ?? [];

    return list.isEmpty
        ? const Center(child: Text("No appointments on this day."))
        : ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final appt = list[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50, // Light blue background
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade300, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(2, 3),
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    "Booking ID: ${appt.localBuddyBookingID}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text("Customer: ${appt.custName}"),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocalBuddyViewAppointmentDetailsScreen(
                          userId: widget.userId,
                          localBuddyId: widget.localBuddyId,
                          custID: appt.custID,
                          localBuddyBookingID: appt.localBuddyBookingID,
                          appointments: [appt],
                        ),
                      ),
                    );
                  },
                ),
              );

            },
          );
  }
}

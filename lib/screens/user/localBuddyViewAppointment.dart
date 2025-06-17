import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';
import 'package:assignment_tripmate/screens/user/localBuddyViewAnalyticsChartDetails.dart';
import 'package:assignment_tripmate/screens/user/localBuddyViewAppointmentDetails.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:syncfusion_flutter_calendar/calendar.dart';

class LocalBuddyViewAppointmentScreen extends StatefulWidget {
  final String userId;
  final String localBuddyId;

  const LocalBuddyViewAppointmentScreen({
    super.key,
    required this.userId,
    required this.localBuddyId,
  });

  @override
  State<LocalBuddyViewAppointmentScreen> createState() => _LocalBuddyViewAppointmentScreenState();
}

class _LocalBuddyViewAppointmentScreenState extends State<LocalBuddyViewAppointmentScreen> {
  List<localBuddyCustomerAppointment> appointmentList = [];
  Map<DateTime, List<localBuddyCustomerAppointment>> appointments = {};
  bool isFetchLoading = false;

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
      CollectionReference ref = FirebaseFirestore.instance.collection('localBuddyBooking');
      QuerySnapshot snapshot = await ref.where('localBuddyID', isEqualTo: widget.localBuddyId).get();

      // Group appointments by booking date
      if (snapshot.docs.isNotEmpty) {
        for (var doc in snapshot.docs) {
          localBuddyCustomerAppointment appointment = localBuddyCustomerAppointment.fromFirestore(doc);

          // Retrieve customer name using custID
          CollectionReference custRef = FirebaseFirestore.instance.collection('users');
          QuerySnapshot querySnapshot = await custRef.where('id', isEqualTo: appointment.custID).get();

          if (querySnapshot.docs.isNotEmpty) {
            var userData = querySnapshot.docs.first.data() as Map<String, dynamic>?;
            if (userData != null && userData.containsKey('name')) {
              appointment.custName = userData['name'];
            } else {
              appointment.custName = 'Unknown';
            }
          } else {
            appointment.custName = 'Unknown';
          }

          for (var date in appointment.bookingDate) {
            // Normalize the date to remove the time component
            DateTime normalizedDate = DateTime(date.year, date.month, date.day);
            if (appointments[normalizedDate] == null) {
              appointments[normalizedDate] = [];
            }
            appointments[normalizedDate]!.add(appointment);
          }
        }
      }
    } catch (e) {
      print("Error fetching appointments: $e");
    } finally {
      setState(() {
        isFetchLoading = false;
      });
    }
  }

  // List<Appointment> _getAppointments() {
  //   List<Appointment> appointmentsList = [];
  //   appointments.forEach((date, appointmentList) {
  //     for (var appointment in appointmentList) {
  //       appointmentsList.add(
  //         Appointment(
  //           startTime: date, // Start time is the booking date
  //           endTime: date, // Keep the end time as the same date to show the full day
  //           subject: 'Booking ID: ${appointment.localBuddyBookingID}\nCustomer: ${appointment.custName}',
  //           color: primaryColor, // Set the color for the appointment
  //           isAllDay: true, // Set to true to indicate it's an all-day event
  //         ),
  //       );
  //     }
  //   });
  //   return appointmentsList;
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Appointment"),
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
              MaterialPageRoute(builder: (context) => UserHomepageScreen(userId: widget.userId, currentPageIndex: 4,)),
            );
          },
        ),
        actions: [
          Container(
            width:40,
            child: IconButton(
              icon: Icon(Icons.analytics_outlined, color: Colors.white, size: 25,),
              onPressed: (){
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => LocalBuddyViewAnalyticsChartDetailScreen(userId: widget.userId, localBuddyID: widget.localBuddyId))
                );
              },
              tooltip: "Analytics Chart",
            ),
          )
        ],
      ),
      body: isFetchLoading
          ? Center(child: CircularProgressIndicator())
          : Container()
          // : SfCalendar(
          //     view: CalendarView.month,
          //     initialSelectedDate: DateTime.now(),
          //     dataSource: AppointmentDataSource(_getAppointments()),
          //     todayHighlightColor: primaryColor,
          //     todayTextStyle: TextStyle(
          //       color: primaryColor,
          //       fontWeight: FontWeight.bold
          //     ),
          //     monthCellBuilder: (BuildContext context, MonthCellDetails details) {
          //       DateTime cellDate = details.date;
          //       List<localBuddyCustomerAppointment>? cellAppointments = appointments[cellDate];

          //       bool isCurrentMonth = details.date.month == details.visibleDates[0].month;
          //       bool isToday = cellDate.isAtSameMomentAs(DateTime.now());

          //       return Container(
          //         padding: EdgeInsets.all(4),
          //         decoration: BoxDecoration(
          //           color: cellAppointments != null && cellAppointments.isNotEmpty 
          //               ? primaryColor.withOpacity(0.2) 
          //               : Colors.transparent,
          //         ),
          //         child: Column(
          //           crossAxisAlignment: CrossAxisAlignment.end,
          //           children: [
          //             Text(
          //               cellDate.day.toString(),
          //             ),
          //             if (cellAppointments != null && cellAppointments.isNotEmpty)
          //               Expanded(
          //                 child: ListView.builder(
          //                   shrinkWrap: true,
          //                   itemCount: cellAppointments.length,
          //                   itemBuilder: (context, index) {
          //                     final appointment = cellAppointments[index];
          //                     return Text(
          //                       'Customer\n(${appointment.custName})',
          //                       maxLines: null,
          //                       overflow: TextOverflow.visible,
          //                       style: TextStyle(
          //                         fontSize: 9,
          //                         color: Colors.black,
          //                         fontWeight: FontWeight.w600,
          //                       ),
          //                     );
          //                   },
          //                 ),
          //               ),
          //           ],
          //         ),
          //       );
          //     },
          //     onTap: (CalendarTapDetails details) {
          //       if (details.targetElement == CalendarElement.calendarCell) {
          //         // Handle tap on calendar cell
          //         DateTime tappedDate = details.date!;
                  
          //         // Check if there are appointments for the tapped date
          //         if (appointments[tappedDate] != null && appointments[tappedDate]!.isNotEmpty) {
          //           // Retrieve the first appointment (or however you want to select an appointment)
          //           final appointment = appointments[tappedDate]!.first;

          //           // Now you can access custID and localBuddyBookingID from the appointment object
          //           Navigator.push(
          //             context,
          //             MaterialPageRoute(
          //               builder: (context) => LocalBuddyViewAppointmentDetailsScreen(
          //                 userId: widget.userId,
          //                 localBuddyId: widget.localBuddyId,
          //                 custID: appointment.custID, // Pass the custID
          //                 localBuddyBookingID: appointment.localBuddyBookingID, // Pass the booking ID
          //                 appointments: appointments[tappedDate]!, // Pass the list of appointments for details
          //               ),
          //             ),
          //           );
          //         } else {
          //           // Handle case where no appointments exist for the selected date
          //           print('No appointments found for this date.');
          //         }
          //       }
          //     },

            // ),
    );
  }
}

// class AppointmentDataSource extends CalendarDataSource {
//   AppointmentDataSource(List<Appointment> source) {
//     appointments = source;
//   }
// }

class AppointmentDetailsScreen extends StatelessWidget {
  final List<localBuddyCustomerAppointment> appointments;
  final DateTime date;

  const AppointmentDetailsScreen({Key? key, required this.appointments, required this.date}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Appointments on ${date.toLocal()}"),
        backgroundColor: const Color(0xFF749CB9),
      ),
      body: ListView.builder(
        itemCount: appointments.length,
        itemBuilder: (context, index) {
          final appointment = appointments[index];
          return ListTile(
            title: Text('Booking ID: ${appointment.localBuddyBookingID}'),
            subtitle: Text('Customer: ${appointment.custName}'),
            onTap: () {
              // Handle tap to show more details about the appointment
            },
          );
        },
      ),
    );
  }
}

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewCarInfo.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TravelAgentCarMaintenanceScreen extends StatefulWidget {
  final String userId;
  final String carId;

  const TravelAgentCarMaintenanceScreen({super.key, required this.userId, required this.carId});

  @override
  State<TravelAgentCarMaintenanceScreen> createState() => _TravelAgentCarMaintenanceScreenState();
}

class _TravelAgentCarMaintenanceScreenState extends State<TravelAgentCarMaintenanceScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate; // Keep this as null initially
  String? _selectedCarStatus;
  String? carModel;
  bool isUpdating = false;
  bool _isDataInitialized = false;
  bool isFetchingCarMaintenance = false;
  List<String> carStatus = ['Maintenance'];
  // List<Map<String, dynamic>> _carMaintenanceData = [];
  List<DateTime> _maintenanceDates = [];
  Map<String, List<DateTime>> groupedMaintenanceDates = {};
  List<DateTime> _carRentalBookingDates = [];
  List<DateTime> selectedMaintenanceDates = [];
  final dateFormat = DateFormat('dd/MM/yyyy'); 

  @override
  void initState() {
    super.initState();
    _fetchCarData();
    // _fetchCarMaintenanceData();
    _fetchMaintenanceDates();
    _fetchCarRentalBookingDates();
  }

  Future<void> _fetchMaintenanceDates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('car_maintenance')
        .where('carID', isEqualTo: widget.carId)
        .orderBy(FieldPath.documentId, descending: true)
        .get();

    // Map to group dates by maintenance ID
    Map<String, List<DateTime>> maintenanceDatesMap = {};
    List<DateTime> maintenanceDates = [];

    for (var doc in snapshot.docs) {
      String maintenanceId = doc['carMaintenanceID']; // Assuming each document has a unique ID for maintenance
      List<dynamic> maintenanceDatesArray = doc['carMaintenanceDate'];

      for (var date in maintenanceDatesArray) {
        DateTime dateTime = (date as Timestamp).toDate();

        // Add to the grouped map
        if (!maintenanceDatesMap.containsKey(maintenanceId)) {
          maintenanceDatesMap[maintenanceId] = [];
        }
        maintenanceDatesMap[maintenanceId]!.add(dateTime);

        // Add to the list of all maintenance dates
        maintenanceDates.add(dateTime);
      }
    }

    setState(() {
      groupedMaintenanceDates = maintenanceDatesMap; // Set grouped dates by ID
      _maintenanceDates = maintenanceDates;           // Set all fetched dates
      _normalizeDates(_maintenanceDates);             // Normalize if needed
    });
  }


  Future<void> _fetchCarRentalBookingDates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('carRentalBooking')
        .where('carID', isEqualTo: widget.carId)
        .get();

    List<DateTime> carRentalBookingDates = [];

    for (var doc in snapshot.docs) {
      // Fetch the array of booking dates from Firebase
      List<dynamic> bookingDatesArray = doc['bookingDate'];
      
      // Convert each Timestamp in the array to DateTime and add to the list
      for (var date in bookingDatesArray) {
        carRentalBookingDates.add((date as Timestamp).toDate());
      }
    }

    setState(() {
      _carRentalBookingDates = carRentalBookingDates; // Set the fetched dates
      _normalizeDates(_carRentalBookingDates); // Normalize dates if needed
    });
  }

  // This function normalizes the maintenance dates
  void _normalizeDates(List<DateTime> list) {
    list = list
        .toSet() // Convert to a Set to remove duplicates
        .toList(); // Convert back to List
  }

  Future<void> _fetchCarData() async {
    setState(() {
      _isDataInitialized = true;
    });
    try {
      DocumentReference carRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carId);
      DocumentSnapshot carSnapshot = await carRef.get();

      if (carSnapshot.exists) {
        Map<String, dynamic>? data = carSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _isDataInitialized = false;
          carModel = data?['carModel'] ?? '';
        });
      } else {
        setState(() {
          _isDataInitialized = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current car does not exist in the system')),
          );
        });
      }
    } catch (e) {
      setState(() {
        _isDataInitialized = false;
      });
      print("Error fetching car details: $e");
    }
  }

  Future<void> _submitCarMaintenance() async {
    // Check if the required fields are not null
    if (_selectedStartDate == null || _selectedEndDate == null || _selectedCarStatus == null || _selectedCarStatus!.isEmpty) {
      // Show error dialog if any field is empty
      showCustomDialog(
        context: context,
        title: 'Error',
        content: 'Please ensure all fields are filled (Start Date, End Date, and Car Status).',
        onPressed: () {
          Navigator.pop(context); // Close the dialog
        },
      );
      return; // Exit the function to avoid proceeding with submission
    }

    setState(() {
      isUpdating = true;
    });

    try {
      // Get the count of existing car maintenance records
      final cmSnapshot = await FirebaseFirestore.instance.collection('car_maintenance').get();

      List<String> carMIDs = [];

      for (var doc in cmSnapshot.docs) {
        carMIDs.add(doc['carID']); // Assuming the document ID is the country ID
      }

      String newCarMID = _generateNewCarMID(carMIDs);

      // Save the car maintenance data to Firestore
      await FirebaseFirestore.instance.collection('car_maintenance').doc(newCarMID).set({
        'carMaintenanceID': newCarMID,
        'carMaintenanceDate': selectedMaintenanceDates,
        // 'carMaintenanceStartDate': _selectedStartDate,
        // 'carMaintenanceEndDate': _selectedEndDate,
        'carStatus': _selectedCarStatus,
        'carID': widget.carId
      });

      setState(() {
        isUpdating = false;
      });

      // Show success dialog
      showCustomDialog(
        context: context,
        title: 'Success',
        content: 'You have submitted the maintenance form successfully.',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TravelAgentViewCarListingScreen(userId: widget.userId)),
          );
        },
      );
    } catch (e) {
      // Handle any errors during the submission process
      showCustomDialog(
        context: context,
        title: 'Error',
        content: 'An error occurred while submitting the maintenance form. Please try again.',
        onPressed: () {
          Navigator.pop(context); // Close the dialog
        },
      );
    } finally {
      setState(() {
        isUpdating = false; // Reset the loading state
      });
    }
  }

  String _generateNewCarMID(List<String> existingIDs) {
    // Extract numeric parts from existing IDs and convert to integers
    List<int> numericIDs = existingIDs
        .map((id) => int.tryParse(id.substring(1)) ?? 0) // Convert "Cxxxx" to xxxx
        .toList();

    // Find the highest ID
    int maxID = numericIDs.isNotEmpty ? numericIDs.reduce((a, b) => a > b ? a : b) : 0;

    // Generate new ID
    return 'CM${(maxID + 1).toString().padLeft(4, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Car Maintenance"),
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
              MaterialPageRoute(builder: (context) => TravelAgentViewCarListingScreen(userId: widget.userId)),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          if (!_isDataInitialized)
            Column(
              children: [
                Container(
                  width: double.infinity,
                  height: 90,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        offset: Offset(0, 4),
                        blurRadius: 6.0,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carModel ?? 'N/A',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: defaultLabelFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Car ID: ${widget.carId}',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: defaultFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Text(
                        'Please choose the maintenance date of selected car:',
                        style: TextStyle(
                          fontSize: defaultFontSize,
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildDatePickerTextFieldCell(
                        context,
                        _startDateController, 
                        'Start Date', 
                        'Select Maintenance Start Date',
                        onDateSelected: (DateTime selectedDate){
                          setState(() {
                            _selectedStartDate = selectedDate;
                          });

                          DateTime firstEndDate = selectedDate.add(Duration(days:1));
                          _updateEndDatePicker(firstEndDate);
                        }
                      ),
                      SizedBox(height: 20),
                      _buildDatePickerTextFieldCell(
                        context,
                        _endDateController, 
                        'End Date', 
                        'Select Maintenance End Date',
                        firstDate: _getFirstDate(),
                        isEndDate: true,
                        startDateSelected: _startDateController.text.isNotEmpty,
                        onDateSelected: (DateTime selectedDate){
                          setState(() {
                            _selectedEndDate = selectedDate;
                          });
                        }
                      ),
                      // maintenanceDate('Select Maintenance Start Date', 'Start Date', _selectedStartDate, _selectStartDate),
                      // SizedBox(height: 20),
                      // maintenanceDate('Select Maintenance End Date', 'End Date', _selectedEndDate, _selectEndDate),
                      SizedBox(height: 20),
                      buildDropDownList(
                        carStatus, 
                        'Select status of car', 
                        'Car Status', 
                        _selectedCarStatus,
                        (newValue){
                          setState(() {
                            _selectedCarStatus = newValue;
                          });
                        }
                      ),
                      SizedBox(height: 10),
                      // Align the button to the right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {_submitCarMaintenance();},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Button radius
                              ),
                            ),
                            child: Text(
                              'Submit',
                              style: TextStyle(
                                fontSize: defaultFontSize,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),
                      if(groupedMaintenanceDates.isNotEmpty)...[
                        Text(
                          "Car Maintenance History",
                          style: TextStyle(
                            fontSize: defaultLabelFontSize,
                            fontWeight: FontWeight.w600,
                            color: Colors.black
                          ),
                        ),
                        SizedBox(height: 10,),
                        SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(color: Colors.white),
                                child: Table(
                                  border: TableBorder.all(color: primaryColor, width: 1.5),
                                  columnWidths: {
                                    0: FixedColumnWidth(40), // Width for the "No" column
                                    1: FixedColumnWidth(300), // Width for the "Maintenance Date" column
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: Colors.grey.shade300),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('No', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text('Maintenance Date', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    for (int index = 0; index < groupedMaintenanceDates.length; index++)
                                      TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text('${index + 1}', textAlign: TextAlign.center),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(
                                              groupedMaintenanceDates.values.elementAt(index)
                                                  .map((date) => dateFormat.format(date))
                                                  .join(', '), // Join dates with a comma
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      ]
                      // Text(
                      //   "Car Maintenance History",
                      //   style: TextStyle(
                      //     fontSize: defaultLabelFontSize,
                      //     fontWeight: FontWeight.w600,
                      //     color: Colors.black
                      //   ),
                      // ),
                      // SizedBox(height: 10,),
                      // SingleChildScrollView(
                      //   child: Column(
                      //     crossAxisAlignment: CrossAxisAlignment.start,
                      //     children: [
                      //       Container(
                      //         width: double.infinity,
                      //         decoration: BoxDecoration(color: Colors.white),
                      //         child: Table(
                      //           border: TableBorder.all(color: primaryColor, width: 1.5),
                      //           columnWidths: {
                      //             0: FixedColumnWidth(40), // Width for the "No" column
                      //             1: FixedColumnWidth(150), // Width for the "Start Date" column
                      //             2: FixedColumnWidth(150), // Width for the "End Date" column
                      //           },
                      //           children: [
                      //             TableRow(
                      //               decoration: BoxDecoration(color: Colors.grey.shade300),
                      //               children: [
                      //                 Padding(
                      //                   padding: const EdgeInsets.all(8.0),
                      //                   child: Text('No', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold),),
                      //                 ),
                      //                 Padding(
                      //                   padding: const EdgeInsets.all(8.0),
                      //                   child: Text('Start Date', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      //                 ),
                      //                 Padding(
                      //                   padding: const EdgeInsets.all(8.0),
                      //                   child: Text('End Date', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                      //                 ),
                      //               ],
                      //             ),
                      //             for (int index = 0; index < _carMaintenanceData.length; index++)
                      //               TableRow(
                      //                 children: [
                      //                   Padding(
                      //                     padding: const EdgeInsets.all(8.0),
                      //                     child: Text('${index + 1}', textAlign: TextAlign.center),
                      //                   ),
                      //                   Padding(
                      //                     padding: const EdgeInsets.all(8.0),
                      //                     child: Text(_carMaintenanceData[index]['startDate'] ?? '', textAlign: TextAlign.center),
                      //                   ),
                      //                   Padding(
                      //                     padding: const EdgeInsets.all(8.0),
                      //                     child: Text(_carMaintenanceData[index]['endDate'] ?? '', textAlign: TextAlign.center),
                      //                   ),
                      //                 ],
                      //               ),
                      //           ],
                      //         ),
                      //       ),
                      //     ],
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ],
            ),
          if (isUpdating)
            Center(
              child: CircularProgressIndicator(),
            ),
          if (_isDataInitialized)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget maintenanceDate(String hintText, String labelText, DateTime? selectedDate, Function(BuildContext) onSelect) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: TextFormField(
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: defaultFontSize,
          color: Colors.black54,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labelText,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(
              color: Color(0xFF467BA1),
              width: 2.5,
            ),
          ),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelStyle: const TextStyle(
            fontSize: defaultLabelFontSize,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            shadows: [
              Shadow(
                offset: Offset(0.5, 0.5),
                color: Colors.black87,
              ),
            ],
          ),
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF467BA1),
              size: 20,
            ),
            onPressed: () => onSelect(context),
          ),
        ),
        controller: TextEditingController(
          text: selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(selectedDate)
              : hintText,
        ),
        readOnly: true,
      ),
    );
  }

    Widget buildDropDownList(
      List<String> listname, String hintText, String label, String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(hintText),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: defaultLabelFontSize,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          shadows: [
            Shadow(
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
      items: listname.map<DropdownMenuItem<String>>((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: onChanged, // Use the passed in function
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: defaultFontSize,
        color: Colors.black,
      ),
    );
  }

    void _updateEndDatePicker(DateTime firstDate) {
    setState(() {
      // Reset the return date controller
      _endDateController.clear();
      _endDateController.text = ""; // Resetting the text field
    });
  }

  DateTime _getFirstDate() {
    // Return the first available return date based on the selected depart date or a default date
    return _selectedStartDate?.add(const Duration(days: 0)) ?? DateTime.now().add(const Duration(days: 0));
  }

  Future<void> _showDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required TextEditingController controller,
    DateTime? lastDate,
    void Function(DateTime)? onDateSelected,
    bool isEndDate = false,
    bool startDateSelected = true,
  }) async {
    DateTime minimumDate = DateTime.now().add(Duration(days: 3));

    // print("Maintenance Dates: ${_maintenanceDates.map((d) => DateFormat('dd/MM/yyyy').format(d)).join(', ')}");

    DateTime validInitialDate = _findNextSelectableDate(
      initialDate.isBefore(minimumDate) ? minimumDate : initialDate,
      (DateTime date) {
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        bool isSelectable = normalizedDate.isAfter(minimumDate) &&
                            !_maintenanceDates.any((maintenanceDate) =>
                                maintenanceDate.year == normalizedDate.year &&
                                maintenanceDate.month == normalizedDate.month &&
                                maintenanceDate.day == normalizedDate.day) &&
                            !_carRentalBookingDates.any((bookingDate) =>
                                bookingDate.year == normalizedDate.year &&
                                bookingDate.month == normalizedDate.month &&
                                bookingDate.day == normalizedDate.day);
        print("Checking date: ${DateFormat('dd/MM/yyyy').format(normalizedDate)} - Selectable: $isSelectable");
        return isSelectable;
      },
    );

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: validInitialDate,
      firstDate: firstDate,
      lastDate: lastDate ?? DateTime(2101),
      selectableDayPredicate: (DateTime date) {
        DateTime normalizedDate = DateTime(date.year, date.month, date.day);
        bool isSelectable = normalizedDate.isAfter(minimumDate) &&
                            !_maintenanceDates.any((maintenanceDate) =>
                                maintenanceDate.year == normalizedDate.year &&
                                maintenanceDate.month == normalizedDate.month &&
                                maintenanceDate.day == normalizedDate.day) &&
                            !_carRentalBookingDates.any((bookingDate) =>
                                bookingDate.year == normalizedDate.year &&
                                bookingDate.month == normalizedDate.month &&
                                bookingDate.day == normalizedDate.day);
        print("Selectable Predicate - Date: ${DateFormat('dd/MM/yyyy').format(normalizedDate)} - Selectable: $isSelectable");
        return isSelectable;
      },
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      controller.text = formattedDate;
      if (onDateSelected != null) {
        onDateSelected(pickedDate);
      }
    }
  }

  // Helper function to find the next selectable date using a predicate
  DateTime _findNextSelectableDate(DateTime date, bool Function(DateTime) predicate) {
    DateTime normalizedDate = DateTime(date.year, date.month, date.day);

    // Check if the current date meets the predicate conditions
    while (!predicate(normalizedDate)) {
      // print("Next Selectable Date Check - Date: ${DateFormat('dd/MM/yyyy').format(normalizedDate)}");
      normalizedDate = normalizedDate.add(Duration(days: 1)); // Move to the next day
    }

    return normalizedDate;
  }


  Widget _buildDatePickerTextFieldCell(
    BuildContext context,
    TextEditingController controller,
    String labelText,
    String hintText, {
    DateTime? firstDate,
    void Function(DateTime)? onDateSelected,
    bool isEndDate = false,
    bool startDateSelected = true,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black,
      ),
      readOnly: true,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.calendar_today_outlined,
            color: Color(0xFF467BA1),
            size: 20,
          ),
          onPressed: () {
            DateTime initialDate = controller.text.isNotEmpty
                ? DateFormat('dd/MM/yyyy').parse(controller.text)
                : DateTime.now();

            // Determine the minimum date based on whether it’s the end date or start date
            DateTime minimumDate = isEndDate
                ? _selectedStartDate?.add(Duration(days: 1)) ?? DateTime.now()
                : initialDate;

            // Use `_findNextSelectableDate` to get a valid initial date
            DateTime validInitialDate = _findNextSelectableDate(
              minimumDate,
              (DateTime date) {
                DateTime normalizedDate = DateTime(date.year, date.month, date.day);
                return normalizedDate.isAfter(DateTime.now().add(Duration(days: 3))) &&
                      !_maintenanceDates.contains(normalizedDate) && !_carRentalBookingDates.contains(normalizedDate);
              },
            );

            _showDatePicker(
              context: context,
              initialDate: validInitialDate,
              firstDate: firstDate ?? DateTime.now(),
              controller: controller,
              onDateSelected: (DateTime selectedDate) {
                if (isEndDate) {
                  _selectedEndDate = selectedDate; 
                  if(_selectedStartDate != null && _selectedEndDate != null){
                    int totalDays = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;

                    List<DateTime> dateRange = List.generate(
                      totalDays,
                      (index) => _selectedStartDate!.add(Duration(days: index)),
                    );

                    List<DateTime> validBookingDates = [];
                    for (DateTime date in dateRange) {
                      if (!_maintenanceDates.contains(date) && !_carRentalBookingDates.contains(date)) {
                        validBookingDates.add(date);
                      }
                    }

                    setState(() {
                      selectedMaintenanceDates = validBookingDates;
                    });

                    // Format valid booking dates as "dd/MM/yyyy" and join them into a single string
                    final dateFormat = DateFormat('dd/MM/yyyy');
                    String selectedBookingDateString = selectedMaintenanceDates.map((date) => dateFormat.format(date)).join(', ');

                    print("Selected maintenance dates: $selectedMaintenanceDates");
                    print("Selected maintenance dates string: $selectedBookingDateString");
                  }
                  
                } else {
                  _selectedStartDate = selectedDate;
                  // Clear end date controller and reset end date
                  _endDateController.text = '';
                  _selectedEndDate = null;
                }

                // Trigger the onDateSelected callback if provided
                if (onDateSelected != null) {
                  onDateSelected(selectedDate);
                }
              },
              isEndDate: isEndDate,
              startDateSelected: _selectedStartDate != null,
            );
          },
        ),
      ),
    );
  }
}

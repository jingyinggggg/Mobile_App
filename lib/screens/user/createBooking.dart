import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:assignment_tripmate/constants.dart';
// import 'package:assignment_tripmate/customerModel.dart';
import 'package:assignment_tripmate/invoiceModel.dart';
import 'package:assignment_tripmate/pdf_invoice_api.dart';
// import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';
// import 'package:assignment_tripmate/supplierModel.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class createBookingScreen extends StatefulWidget {
  final String userId;
  final String? tourID;
  final String? carRentalID;
  final String? localBuddyID;
  final bool tour;
  final bool carRental;
  final bool localBuddy;

  const createBookingScreen({
    super.key,
    required this.userId,
    this.tourID,
    this.carRentalID,
    this.localBuddyID,
    this.tour = false,
    this.carRental = false,
    this.localBuddy = false,
  });

  @override
  State<createBookingScreen> createState() => _createBookingScreenState();
}

class _createBookingScreenState extends State<createBookingScreen> {
  // User (Customer)
  Map<String, dynamic> _userData = {};

  // Company 
  Map<String, dynamic> _companyData = {};

  // Tour 
  UserViewTourList? _tour; 
  bool isLoadingTour = false;
  bool isBookTour = false;
  List<String> availableDateRanges = []; 
  List<Map<String, dynamic>> availabilityList = []; 
  String? selectedDateRange;
  int? selectedSlot;
  int? price;
  double? calculatedTotalTourPrice;
  double? remainingPrice;
  String? _paxErrorMessage;
  final TextEditingController _paxController = TextEditingController();

  // Car Rental
  bool isLoadingCarRental = false;
  bool isBookCar = false;
  CarList? _carRental;
  final TextEditingController _rentStartDateController = TextEditingController();
  final TextEditingController _rentEndDateController = TextEditingController();
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  double carRentalDeposit = 300.0;
  double? carRentalTotalPrice;
  double? rentPrice;
  int? CRDifferenceInDays;
  List<DateTime> _maintenanceDates = [];
  List<DateTime> _carRentalBookingDates = [];
  List<DateTime> selectedBookingDates = [];
  String? selectedBookingDateString;

  // Local Buddy
  bool isLoadingLocalBuddy = false;
  bool isBookLocalBuddy = false;
  LocalBuddy? _localBuddy;
  final TextEditingController _LbStartDateController = TextEditingController();
  final TextEditingController _LbEndDateController = TextEditingController();
  DateTime? _selectedLbStartDate;
  DateTime? _selectedLbEndDate;
  String? locationArea;
  List<String> availableLocalBuddyDay = [];
  List<String> availableLocalBuddyTime = [];
  List<Map<String, dynamic>> availabilityLocalBuddyList = [];
  double? LBTotalPrice;
  int? LBDifferenceInDays;
  List<DateTime> _localBuddyBookingDates = [];
  List<DateTime> selectedLocalBuddyBookingDates = [];
  String? selectedLocalBuddyBookingDateString;

  bool isInvoiceLoading = false;

  bool isSelectingImage = false;
  Uint8List? _transferProof;
  String? uploadedProof;
  final TextEditingController _proofNameController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  List<int> _getValidWeekdays(List<String> availableDays) {
    Map<String, int> dayToWeekdayMap = {
      'Monday': DateTime.monday,
      'Tuesday': DateTime.tuesday,
      'Wednesday': DateTime.wednesday,
      'Thursday': DateTime.thursday,
      'Friday': DateTime.friday,
      'Saturday': DateTime.saturday,
      'Sunday': DateTime.sunday,
    };

    return availableDays.map((day) => dayToWeekdayMap[day]!).toList();
  }

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    if (widget.tour) {
      _fetchTourDetails();
    } else if (widget.carRental) {
      _fetchMaintenanceDates();
      _fetchCarRentalBookingDates();
      _fetchCarDetails();
    } else {
      _fetchLocalBuddyBookingDate();
      _fetchLocalBuddyDetails();
    }
  }

  String encryptText(String text) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a random IV for each encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    // Combine IV and encrypted text with a delimiter
    return "${iv.base64}:${encrypted.base64}";
  }

  Future<void> _fetchMaintenanceDates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('car_maintenance')
        .where('carID', isEqualTo: widget.carRentalID)
        .get();

    List<DateTime> maintenanceDates = [];

    for (var doc in snapshot.docs) {
      List<dynamic> maintenanceDatesArray = doc['carMaintenanceDate'];

      for (var date in maintenanceDatesArray) {
        maintenanceDates.add((date as Timestamp).toDate());
      }
    }

    setState(() {
      _maintenanceDates = maintenanceDates; // Set the fetched dates
      _normalizeDates(_maintenanceDates); // Normalize the dates to remove duplicates
    });

    // Optional: Check the contents of _maintenanceDates
    for (var date in _maintenanceDates) {
      print("Maintenance Date Fetched: ${date}"); // Outputs the dates in the format you expect
    }
  }

  Future<void> _fetchCarRentalBookingDates() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('carRentalBooking')
        .where('carID', isEqualTo: widget.carRentalID)
        .where('bookingStatus', isEqualTo: 0)
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

    // Optional: Print the fetched booking dates
    for (var date in _carRentalBookingDates) {
      print("Car Rental Booking Date Fetched: ${date}");
    }
  }

  Future<void> _fetchLocalBuddyBookingDate() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('localBuddyBooking')
        .where('localBuddyID', isEqualTo: widget.localBuddyID)
        .get();

    List<DateTime> localBuddyBookingDates = [];

    for (var doc in snapshot.docs) {
      // Fetch the array of booking dates from Firebase
      List<dynamic> bookingDatesArray = doc['bookingDate'];
      
      // Convert each Timestamp in the array to DateTime and add to the list
      for (var date in bookingDatesArray) {
        localBuddyBookingDates.add((date as Timestamp).toDate());
      }
    }

    setState(() {
      _localBuddyBookingDates = localBuddyBookingDates; // Set the fetched dates
      _normalizeDates(_localBuddyBookingDates); // Normalize dates if needed
    });

    // Optional: Print the fetched booking dates
    for (var date in _localBuddyBookingDates) {
      print("Local Buddy Booking Date Fetched: ${date}");
    }
  }

  // This function normalizes the maintenance dates
  void _normalizeDates(List<DateTime> list) {
    list = list
        .toSet() // Convert to a Set to remove duplicates
        .toList(); // Convert back to List
  }

  Future<void> _fetchUserDetails() async{
    try{
      DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(widget.userId);
      DocumentSnapshot userSnapshot = await userRef.get();

      if(userSnapshot.exists){
        Map<String, dynamic>? userData = userSnapshot.data() as Map<String, dynamic>?;

        if(userData != null){
          setState(() {
            _userData = userData;
          });
        }
      }
    }catch(e){
      print('Error fetching user data: $e');
    }
  }

  Future<void> _fetchTourDetails() async {
    setState(() {
      isLoadingTour = true;
    });

    try {
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot tourSnapshot = await tourRef.get();

      if (tourSnapshot.exists) {
        Map<String, dynamic>? tourData = tourSnapshot.data() as Map<String, dynamic>?;

        if (tourData != null) {
          setState(() {
            _tour = UserViewTourList(
              tourData['tourName'],
              tourData['tourID'],
              tourData['tourCover'],
              tourData['agency'],
              tourData['tourHighlight'],
              tourData['availability'], 
            );

            if (tourData['availability'] != null) {
              availabilityList = List<Map<String, dynamic>>.from(tourData['availability']);
              availableDateRanges = availabilityList.map((item) => item['dateRange'] as String).toList();
            }
          });

          DocumentReference companyRef = FirebaseFirestore.instance.collection('travelAgent').doc(tourData['agentID']);
          DocumentSnapshot companySnapshot = await companyRef.get();

          if(companySnapshot.exists){
            Map<String, dynamic>? companyData = companySnapshot.data() as Map<String, dynamic>?;

            if(companyData != null){
              setState(() {
                _companyData = companyData;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching tour data: $e');
    } finally {
      setState(() {
        isLoadingTour = false;
      });
    }
  }

  Future<void> _fetchCarDetails() async {
    setState(() {
      isLoadingCarRental = true;
    });

    try {
      DocumentReference carRentalRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carRentalID);
      DocumentSnapshot carRentalSnapshot = await carRentalRef.get();

      if (carRentalSnapshot.exists) {
        Map<String, dynamic>? carData = carRentalSnapshot.data() as Map<String, dynamic>?;

        if (carData != null) {
          setState(() {
            _carRental = CarList(
              carData['carID'],
              carData['carModel'],
              carImage: carData['carImage'],
              agentID: carData['agencyID'],
              agencyName: carData['agencyName'],
              price: carData['pricePerDay'],
              carType: carData['carType'],
              fuel: carData['fuel'],
              transmission: carData['transmission'],
              seat: carData['seat'],
              pickUpLocation: carData['pickUpLocation'],
              dropOffLocation: carData['dropOffLocation']
            );
          });

          DocumentReference companyRef = FirebaseFirestore.instance.collection('travelAgent').doc(carData['agencyID']);
          DocumentSnapshot companySnapshot = await companyRef.get();

          if(companySnapshot.exists){
            Map<String, dynamic>? companyData = companySnapshot.data() as Map<String, dynamic>?;

            if(companyData != null){
              setState(() {
                _companyData = companyData;
              });
            }
          }
        }
      }
    } catch (e) {
      print('Error fetching tour data: $e');
    } finally {
      setState(() {
        isLoadingCarRental = false;
      });
    }
  }

  Future<void> _fetchLocalBuddyDetails() async {
    setState(() {
      isLoadingLocalBuddy = true;
    });

    try {
      DocumentReference LBRef = FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyID);
      DocumentSnapshot LBSnapshot = await LBRef.get();

      if (LBSnapshot.exists) {
        Map<String, dynamic>? LBData = LBSnapshot.data() as Map<String, dynamic>?;

        if (LBData != null) {
          DocumentReference ref = FirebaseFirestore.instance.collection('users').doc(LBData['userID']);
          DocumentSnapshot snapshot = await ref.get();

          Map<String, dynamic>? userData = snapshot.data() as Map<String, dynamic>?;

          if (LBData.containsKey('location')) {
            String fullAddress = LBData['location'] ?? '';

            String? country = '';
            String? area = '';

            if (fullAddress.isNotEmpty) {
              var locationData = await _getLocationAreaAndCountry(fullAddress);
              country = locationData['country'];
              area = locationData['area'];
            } else {
              country = 'Unknown Country';
              area = 'Unknown Area';
            }

            locationArea = '$area, $country';

            setState(() {
              _localBuddy = LocalBuddy(
                localBuddyID: LBData['localBuddyID'],
                localBuddyName: userData?['name'],
                localBuddyImage: userData?['profileImage'],
                locationArea: locationArea,
                price: LBData['price']
              );
            });

            if(LBData['availability'] != null){
              availabilityLocalBuddyList = List<Map<String, dynamic>>.from(LBData['availability']);
              availableLocalBuddyDay = availabilityLocalBuddyList.map((item) => item['day'] as String).toList();
            }
            
          } else{
            setState(() {
              isLoadingLocalBuddy = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching local buddy data: $e');
    } finally {
      setState(() {
        isLoadingLocalBuddy = false;
      });
    }
  }

  Future<Map<String, String>> _getLocationAreaAndCountry(String address) async {
    final String apiKeys = apiKey; // Replace with your API key
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKeys';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];

        String country = '';
        String area = '';

        for (var component in addressComponents) {
          List<String> types = List<String>.from(component['types']);
          if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('administrative_area_level_1') || types.contains('locality')) {
            area = component['long_name'];
          }
        }

        return {'country': country, 'area': area};
      } else {
        return {'country': '', 'area': ''};
      }
    } else {
      print('Error fetching location data: ${response.statusCode}');
      return {'country': '', 'area': ''};
    }
  }

  Future<String> uploadImageToStorage(String childName, Uint8List file) async{
  
    Reference ref = FirebaseStorage.instance.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadURL = await snapshot.ref.getDownloadURL();
    return downloadURL;
  }

  Future<void> selectImage() async {
    setState(() {
      isSelectingImage = true;
    });

    Uint8List? img = await ImageUtils.selectImage(context);

    setState(() {
      _transferProof = img;
      _proofNameController.text = img != null ? 'Proof Uploaded' : 'No proof uploaded';
      isSelectingImage = false;
    });
  }


  // Future<void> selectImage() async {
  //   setState(() {
  //     isSelectingImage = true;
  //     _proofNameController.text = 'Uploading...';
  //   });
    
  //   Uint8List? img = await ImageUtils.selectImage(context);
  //   if (img != null) {
  //     setState(() {
  //       _transferProof = img;
  //       _proofNameController.text = 'Proof Uploaded';
  //     });
  //   } else {
  //     setState(() {
  //       _proofNameController.text = 'No proof uploaded';
  //     });
  //   }
    
  //   setState(() {
  //     isSelectingImage = false;
  //   });
  // }

  Future<void> bookTour() async {
    setState(() {
      isBookTour = true;
    });

    try {
      // Retrieve the current number of tour booking
      final snapshot = await FirebaseFirestore.instance.collection('tourBooking').get();
      final id = 'TBK${(snapshot.docs.length + 1).toString().padLeft(4, '0')}';

      String fileName = "transferProof.jpg";

      if(_transferProof != null){
        uploadedProof = await uploadImageToStorage("invoice/Tour Package/${widget.userId}/$id/$fileName", _transferProof!);

        // Add the booking details
        await FirebaseFirestore.instance.collection('tourBooking').doc(id).set({
          'bookingID': id,
          'userID': widget.userId,
          'tourID': widget.tourID,
          'travelDate': selectedDateRange,
          'numberOfPeople': int.parse(_paxController.text),
          'totalPrice': calculatedTotalTourPrice,
          'fullyPaid': 0,
          'remainingPrice': remainingPrice,
          'bookingStatus': 0,
          'bookingCreateTime': DateTime.now(),
          'transferProof': uploadedProof!,
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Customer(${widget.userId}) has booked the tour package with id (${widget.tourID}).",
          'isRead': 0,
          'type': "booking",
          'timestamp': DateTime.now(),
          'receiverID': _companyData['id']
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Customer(${widget.userId}) has make payment for the tour package with id (${widget.tourID}). Please generate invoice for the customer.",
          'isRead': 0,
          'type': "invoice",
          'timestamp': DateTime.now(),
          'receiverID': "A1001"
        });
      }

      // Get the current availability of the tour package
      final tourPackageDoc = await FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID).get();
      
      if (tourPackageDoc.exists) {
        List availability = tourPackageDoc.data()?['availability'] ?? [];

        // Find the availability entry for the selected date range
        for (int i = 0; i < availability.length; i++) {
          if (availability[i]['dateRange'] == selectedDateRange) {
            // Reduce the slot count by the number of people booked
            int updatedSlots = availability[i]['slot'] - int.parse(_paxController.text);
            
            // Ensure slots don't go negative
            if (updatedSlots < 0) {
              throw Exception('Not enough slots available for the selected date.');
            }

            // Update the slots for the specific date range
            availability[i]['slot'] = updatedSlots;

            // Save the updated availability back to Firestore
            await FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID).update({
              'availability': availability,
            });

            break;
          }
        }
      }

      // Show success dialog
      showCustomDialog(
        context: context, 
        title: "Payment Successful", 
        content: "You have successfully booked this tour package. Please wait for the admin to process your booking and generate the invoice.", 
        onPressed: () async {
          // Close the payment successful dialog
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomepageScreen(
                userId: widget.userId,
                currentPageIndex: 3,
              ),
            ),
          );

          // // Use Future.microtask to show the loading dialog after the previous dialog is closed
          // Future.microtask(() {
          //   showLoadingDialog(context, "Generating Invoice...");
          // });

          // final date = DateTime.now();
          // // final date = DateTime(2024, 10, 19);

          // final invoice = Invoice(
          //   supplier: Supplier(
          //     name: _companyData['companyName'],
          //     address: _companyData['companyAddress'],
          //   ),
          //   customer: Customer(
          //     name: _userData['name'],
          //     address: _userData['address'],
          //   ),
          //   info: InvoiceInfo(
          //     date: date,
          //     description: "You have paid the deposit. Below is the invoice summary:",
          //     number: '${DateTime.now().year}-$id',
          //   ),
          //   // Wrap the single InvoiceItem in a list
          //   items: [
          //     InvoiceItem(
          //       description: "Deposit for ${_tour!.tourName} - (${selectedDateRange!})",
          //       quantity: 1,
          //       unitPrice: 1000,
          //       total: 1000 ,
          //     ),
          //   ],
          // );

          // // Perform some async operation
          // await generateInvoice(id, invoice, "Tour Package", "tourBooking", "deposit", true, false, false);

          // // After the operation is done, hide the loading dialog
          // Navigator.of(context).pop(); // This will close the loading dialog

          // // Navigate to the homepage after PDF viewer
          // Future.delayed(Duration(milliseconds: 500), () {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => UserHomepageScreen(
          //         userId: widget.userId,
          //         currentPageIndex: 3,
          //       ),
          //     ),
          //   );
          // });
        },
        textButton: "Done",
      );
    } catch (e) {
      // Show failure dialog
      showCustomDialog(
        context: context, 
        title: "Failed", 
        content: "Something went wrong! Please try again...", 
        onPressed: () {
          Navigator.pop(context);
        }
      );
    } finally {
      setState(() {
        isBookTour = false;
      });
    }
  }

  Future<void> bookCarRental() async {
    setState(() {
      isBookCar = true;
    });

    try {
      // Retrieve the current number of tour booking
      final snapshot = await FirebaseFirestore.instance.collection('carRentalBooking').get();
      final id = 'CarBK${(snapshot.docs.length + 1).toString().padLeft(4, '0')}';

      // Encrypt bank details
      final encryptedBankName = encryptText(_bankNameController.text);
      final encryptedAccountName = encryptText(_accountNameController.text);
      final encryptedAccountNumber = encryptText(_accountNumberController.text);

      String fileName = "transferProof.jpg";

      if(_transferProof != null){
        uploadedProof = await uploadImageToStorage("invoice/Car Rental/${widget.userId}/$id/$fileName", _transferProof!);
      }

      // Add the booking details
      await FirebaseFirestore.instance.collection('carRentalBooking').doc(id).set({
        'bookingID': id,
        'userID': widget.userId,
        'carID': widget.carRentalID,
        'bookingDate': selectedBookingDates,
        'totalDays': CRDifferenceInDays,
        'totalPrice': carRentalTotalPrice,
        'isCheckCarCondition': 0,
        'isRefund': 0,
        'isRefundDeposit': 0,
        'bookingStatus': 0,
        'bookingCreateTime': DateTime.now(),
        'transferProof': uploadedProof!,
        'bankName': encryptedBankName,
        'accountName': encryptedAccountName,
        'accountNumber': encryptedAccountNumber,
      });

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Customer(${widget.userId}) has booked the car rental package with id (${widget.carRentalID}).",
        'isRead': 0,
        'type': "booking",
        'timestamp': DateTime.now(),
        'receiverID': _companyData['id']
      });

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Customer(${widget.userId}) has make payment for the car rental package with id (${widget.carRentalID}). Please generate invoice for the customer.",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': "A1001"
      });

      // Show success dialog
      showCustomDialog(
        context: context, 
        title: "Payment Successful", 
        content: "You have rented this car successfully. Please wait for the admin to process your booking and generate the invoice.", 
        onPressed: () async {
          // Close the payment successful dialog
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomepageScreen(
                userId: widget.userId,
                currentPageIndex: 3,
              ),
            ),
          );

          // Use Future.microtask to show the loading dialog after the previous dialog is closed
          // Future.microtask(() {
          //   showLoadingDialog(context, "Generating Invoice...");
          // });

          // final date = DateTime.now();
          // final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

          // final invoice = Invoice(
          //   supplier: Supplier(
          //     name: _companyData['companyName'] ?? "Unknown Company",
          //     address: _companyData['companyAddress'] ?? "Unknown Company Address",
          //   ),
          //   customer: Customer(
          //     name: _userData['name'] ?? "Unknown Customer",
          //     address: _userData['address'] ?? "Unknown Customer Address",
          //   ),
          //   info: InvoiceInfo(
          //     date: date,
          //     description: "You have paid the bill. Below is the invoice summary:",
          //     number: '${DateTime.now().year}-$id',
          //   ),
          //   // Wrap the single InvoiceItem in a list
          //   items: [
          //     InvoiceItem(
          //       description: "Deposit (Refundable)",
          //       quantity: 1,
          //       unitPrice: carRentalDeposit.toInt(),
          //       total: carRentalDeposit,
          //     ),
          //     InvoiceItem(
          //       description: "${_carRental!.carModel} - ($selectedBookingDateString))",
          //       // description: "${_carRental!.carModel} (${dateFormat.format(selectedBookingDates)})",
          //       quantity: CRDifferenceInDays!,
          //       unitPrice: _carRental!.price!.toInt(),
          //       total:  rentPrice ?? 0.0,
          //     ),
          //   ],
          // );

          // // Perform some async operation
          // await generateInvoice(id, invoice, "Car Rental", "carRentalBooking", "invoice", false, false, false);

          // // After the operation is done, hide the loading dialog
          // Navigator.of(context).pop(); // This will close the loading dialog

          // // Navigate to the homepage after PDF viewer
          // Future.delayed(Duration(milliseconds: 500), () {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => UserHomepageScreen(
          //         userId: widget.userId,
          //         currentPageIndex: 3,
          //       ),
          //     ),
          //   );
          // });
        },
        textButton: "Done"
      );
    } catch (e) {
      // Show failure dialog
      showCustomDialog(
        context: context, 
        title: "Failed", 
        content: "Something went wrong! Please try again...", 
        onPressed: () {
          Navigator.pop(context);
        }
      );
    } finally {
      setState(() {
        isBookCar = false;
      });
    }
  }

  Future<void> bookLocalBuddy() async {
    setState(() {
      isBookLocalBuddy = true;
    });

    try {
      // Retrieve the current number of local buddy booking
      final snapshot = await FirebaseFirestore.instance.collection('localBuddyBooking').get();
      final id = 'LBK${(snapshot.docs.length + 1).toString().padLeft(4, '0')}';

      String fileName = "transferProof.jpg";

      if(_transferProof != null){
        uploadedProof = await uploadImageToStorage("invoice/Local Buddy/${widget.userId}/$id/$fileName", _transferProof!);

      }

      // Add the booking details
      await FirebaseFirestore.instance.collection('localBuddyBooking').doc(id).set({
        'bookingID': id,
        'userID': widget.userId,
        'localBuddyID': widget.localBuddyID,
        'bookingDate': selectedLocalBuddyBookingDates,
        'totalDays': LBDifferenceInDays,
        'totalPrice': LBTotalPrice,
        'bookingStatus': 0,
        'isRefund': 0,
        'bookingCreateTime': DateTime.now(),
        'transferProof': uploadedProof!,
      });

      final lbDoc = await FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyID).get();

      if(lbDoc.exists){
        String lbUserID = lbDoc.data()?['userID'] ?? "";

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Customer(${widget.userId}) has booked your local buddy slot with booking id ($id)).",
          'isRead': 0,
          'type': "booking",
          'timestamp': DateTime.now(),
          'receiverID': lbUserID
        });
      }

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Customer(${widget.userId}) has make payment for the local buddy package with id (${widget.localBuddyID}). Please generate invoice for the customer.",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': "A1001"
      });

      // Show success dialog
      showCustomDialog(
        context: context, 
        title: "Payment Successful", 
        content: "You have booked this local buddy successfully. Please wait for the admin to process your booking and generate the invoice.", 
        onPressed: () async {
          // Close the payment successful dialog
          Navigator.of(context).pop();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomepageScreen(
                userId: widget.userId,
                currentPageIndex: 3,
              ),
            ),
          );

          // Use Future.microtask to show the loading dialog after the previous dialog is closed
          // Future.microtask(() {
          //   showLoadingDialog(context, "Generating Invoice...");
          // });

          // final date = DateTime.now();
          // final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

          // final invoice = Invoice(
          //   supplier: Supplier(
          //     name: "Admin",
          //     address: "admin@tripmate.com",
          //   ),
          //   customer: Customer(
          //     name: _userData['name'] ?? "Unknown Customer",
          //     address: _userData['address'] ?? "Unknown Customer Address",
          //   ),
          //   info: InvoiceInfo(
          //     date: date,
          //     description: "You have paid the bill. Below is the invoice summary:",
          //     number: '${DateTime.now().year}-$id',
          //   ),
          //   // Wrap the single InvoiceItem in a list
          //   items: [
          //     InvoiceItem(
          //       description: "Local Buddy: ${_localBuddy!.localBuddyName} ($selectedLocalBuddyBookingDateString)",
          //       quantity: LBDifferenceInDays!,
          //       unitPrice: _localBuddy!.price!.toInt(),
          //       total:  LBTotalPrice ?? 0.0,
          //     ),
          //   ],
          // );

          // // Perform some async operation
          // await generateInvoice(id, invoice, "Local Buddy", "localBuddyBooking", "invoice", false, false, false);

          // // After the operation is done, hide the loading dialog
          // Navigator.of(context).pop(); // This will close the loading dialog

          // // Navigate to the homepage after PDF viewer
          // Future.delayed(Duration(milliseconds: 500), () {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => UserHomepageScreen(
          //         userId: widget.userId,
          //         currentPageIndex: 3,
          //       ),
          //     ),
          //   );
          // });
        },
        textButton: "Done"
      );
    } catch (e) {
      // Show failure dialog
      showCustomDialog(
        context: context, 
        title: "Failed", 
        content: "Something went wrong! Please try again...", 
        onPressed: () {
          Navigator.pop(context);
        }
      );
    } finally {
      setState(() {
        isBookLocalBuddy = false;
      });
    }
  }

  void showPaymentOption(BuildContext context, String amount, Function onSubmit, String type) {
    bool isProofUploaded = _proofNameController.text.isNotEmpty;
    bool isAccountDetailsFill = _bankNameController.text.isNotEmpty && _accountNameController.text.isNotEmpty && _accountNumberController.text.isNotEmpty;

    void updateAccountDetailsFill() {
      // Update the isAccountDetailsFill state based on the current input
      isAccountDetailsFill = _bankNameController.text.isNotEmpty &&
          _accountNameController.text.isNotEmpty &&
          _accountNumberController.text.isNotEmpty;
    }


    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text("Bank Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max, // Change this to max
                  children: [
                    Text("Please transfer $amount to the following account:", textAlign: TextAlign.justify),
                    const SizedBox(height: 8),
                    const Text(
                      "Bank: Hong Leong Bank\nAccount Name: TripMate\nAccount Number: 1234567890",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        setDialogState(() {
                          isSelectingImage = true; // Start showing the loading indicator in the dialog
                        });

                        await selectImage();

                        // Check if proof is uploaded
                        setDialogState(() {
                          isSelectingImage = false; // Stop showing the loading indicator in the dialog
                          isProofUploaded = _proofNameController.text.isNotEmpty; // Update proof upload status
                        });
                      },
                      icon: const Icon(Icons.upload_file),
                      label: const Text("Upload Transfer Proof"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: primaryColor, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            "Proof: ${_proofNameController.text.isNotEmpty ? _proofNameController.text : "No proof uploaded"}",
                            style: const TextStyle(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (isSelectingImage)
                          const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                          ),
                      ],
                    ),
                    if (type == 'Car Rental') ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Please enter your bank details for deposit refund:",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: defaultFontSize),
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _bankNameController,
                        decoration: InputDecoration(
                          labelText: "Bank Name",
                          hintText: "Bank Name",
                          labelStyle: TextStyle(color: Colors.black, fontSize: defaultLabelFontSize),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2.5),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: defaultFontSize),
                        onChanged: (value) {
                          setDialogState(() {
                            updateAccountDetailsFill();
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _accountNameController,
                        decoration: InputDecoration(
                          labelText: "Account Name",
                          hintText: "Account Name",
                          labelStyle: TextStyle(color: Colors.black, fontSize: defaultLabelFontSize),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2.5),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: defaultFontSize),
                        onChanged: (value) {
                          setDialogState(() {
                            updateAccountDetailsFill();
                          });
                        },
                      ),
                      SizedBox(height: 10),
                      TextField(
                        controller: _accountNumberController,
                        decoration: InputDecoration(
                          labelText: "Account Number",
                          hintText: "Account Number",
                          labelStyle: TextStyle(color: Colors.black, fontSize: defaultLabelFontSize),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF467BA1),
                              width: 2.5,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2.5),
                          ),
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                        ),
                        style: TextStyle(fontWeight: FontWeight.w500, fontSize: defaultFontSize),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          setDialogState(() {
                            updateAccountDetailsFill();
                          });
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  child: const Text("Close"),
                  style: TextButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: (isProofUploaded && (type != "Car Rental" || isAccountDetailsFill)) ? () {
                    Navigator.of(context).pop(); // Close the dialog
                    onSubmit(); // Call the provided function
                  } : null,
                  child: const Text("Submit"),
                  style: TextButton.styleFrom(
                    backgroundColor: (isProofUploaded && (type != "Car Rental" || isAccountDetailsFill)) 
                      ? primaryColor 
                      : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }




  // Future<void> showPaymentOption(BuildContext context, String deposit, Function onOptionSelected) async {
  //   String? selectedPaymentOption; // To store the selected payment option

  //   await showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(
  //           'Select Payment Option', 
  //           style: TextStyle(
  //             fontSize: defaultLabelFontSize,
  //             fontWeight: FontWeight.w600,
  //             color: Colors.black,
  //           ),
  //         ),
  //         content: StatefulBuilder(
  //           builder: (BuildContext context, StateSetter setState) {
  //             return Container(
  //               child: Column(
  //                 mainAxisSize: MainAxisSize.min, // To adjust based on content
  //                 children: <Widget>[
  //                   ListTile(
  //                     contentPadding: EdgeInsets.symmetric(horizontal: 0.0), // Remove default padding
  //                     leading: Transform.scale(
  //                       scale: 0.6, // Scale the radio size
  //                       child: Radio<String>(
  //                         value: "Touch'n Go",
  //                         groupValue: selectedPaymentOption,
  //                         activeColor: primaryColor, // Set the selected radio color to blue
  //                         onChanged: (String? value) {
  //                           setState(() {
  //                             selectedPaymentOption = value; // Update selected payment option
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                     title: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
  //                       children: [
  //                         Text(
  //                           "Touch'n Go",
  //                           style: TextStyle(
  //                             fontSize: defaultFontSize,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.black
  //                           ),
  //                         ),
  //                         Image(
  //                           image: AssetImage('images/TNG-eWallet.png'),
  //                           width: 40,
  //                           alignment: Alignment.centerRight,
  //                         ), 
  //                       ],
  //                     ),
  //                   ),

  //                   ListTile(
  //                     contentPadding: EdgeInsets.symmetric(horizontal: 0.0), // Remove default padding
  //                     leading: Transform.scale(
  //                       scale: 0.6, // Scale the radio size
  //                       child: Radio<String>(
  //                         value: 'Credit Card',
  //                         groupValue: selectedPaymentOption,
  //                         activeColor: primaryColor, // Set the selected radio color to blue
  //                         onChanged: (String? value) {
  //                           setState(() {
  //                             selectedPaymentOption = value; // Update selected payment option
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                     title: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
  //                       children: [
  //                         Text(
  //                           'Credit Card',
  //                           style: TextStyle(
  //                             fontSize: defaultFontSize,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.black
  //                           ),
  //                         ),
  //                         Image(
  //                           image: AssetImage('images/credit_card.png'),
  //                           width: 40,
  //                         ), 
  //                       ],
  //                     ),
  //                   ),

  //                   ListTile(
  //                     contentPadding: EdgeInsets.symmetric(horizontal: 0.0), // Remove default padding
  //                     leading: Transform.scale(
  //                       scale: 0.6, // Scale the radio size
  //                       child: Radio<String>(
  //                         value: 'PayPal',
  //                         groupValue: selectedPaymentOption,
  //                         activeColor: primaryColor, // Set the selected radio color to blue
  //                         onChanged: (String? value) {
  //                           setState(() {
  //                             selectedPaymentOption = value; // Update selected payment option
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                     title: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
  //                       children: [
  //                         Text(
  //                           'PayPal',
  //                           style: TextStyle(
  //                             fontSize: defaultFontSize,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.black
  //                           ),
  //                         ),
  //                         Image(
  //                           image: AssetImage('images/paypal.png'),
  //                           width: 50,
  //                           height: 40,
  //                         ), 
  //                       ],
  //                     ),
  //                   ),

  //                   ListTile(
  //                     contentPadding: EdgeInsets.symmetric(horizontal: 0.0), // Remove default padding
  //                     leading: Transform.scale(
  //                       scale: 0.6, // Scale the radio size
  //                       child: Radio<String>(
  //                         value: 'Online Banking',
  //                         groupValue: selectedPaymentOption,
  //                         activeColor: primaryColor, // Set the selected radio color to blue
  //                         onChanged: (String? value) {
  //                           setState(() {
  //                             selectedPaymentOption = value; // Update selected payment option
  //                           });
  //                         },
  //                       ),
  //                     ),
  //                     title: Row(
  //                       mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between text and icon
  //                       children: [
  //                         Text(
  //                           'Online Banking',
  //                           style: TextStyle(
  //                             fontSize: defaultFontSize,
  //                             fontWeight: FontWeight.w500,
  //                             color: Colors.black
  //                           ),
  //                         ),
  //                         Icon(Icons.account_balance, color: primaryColor, size: 20), // Icon for Bank Transfer
  //                       ],
  //                     ),
  //                   ),

  //                   SizedBox(height: 20),
  //                   Text(
  //                     'Total Price: $deposit',
  //                     style: TextStyle(
  //                       fontSize: defaultLabelFontSize,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),

  //                   SizedBox(height: 10),

  //                   Row(
  //                     mainAxisAlignment: MainAxisAlignment.end,
  //                     crossAxisAlignment: CrossAxisAlignment.end,
  //                     children: [
  //                       TextButton(
  //                         child: Text('Cancel'),
  //                         onPressed: () {
  //                           Navigator.of(context).pop(); // Close the dialog
  //                         },
  //                         style: TextButton.styleFrom(
  //                           backgroundColor: primaryColor, // Set the background color
  //                           foregroundColor: Colors.white, // Set the text color
  //                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(8), // Optional: rounded corners
  //                           ),
  //                         ),
  //                       ),
  //                       SizedBox(width: 10),

  //                       TextButton(
  //                         child: Text('Pay'),
  //                         style: TextButton.styleFrom(
  //                           backgroundColor: selectedPaymentOption != null ? primaryColor : Colors.grey.shade300, // Set the background color
  //                           foregroundColor: Colors.white, // Set the text color
  //                           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
  //                           shape: RoundedRectangleBorder(
  //                             borderRadius: BorderRadius.circular(8), // Optional: rounded corners
  //                           ),
  //                         ),
  //                         onPressed: selectedPaymentOption != null
  //                           ? () {
  //                               onOptionSelected(selectedPaymentOption!); // Pass the selected payment option to the callback
  //                               Navigator.of(context).pop(); // Close the dialog
  //                             }
  //                           : null,
  //                       ),
  //                     ],
  //                   )
  //                 ],
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }

  Future<void> generateInvoice(String id, Invoice invoices, String servicesType, String collectionName, String pdfFileName, bool isDeposit, bool isRefund, bool isDepositRefund) async {
    setState(() {
      bool isGeneratingInvoice = true; // Correctly set the loading state variable
    });

    try {
      // Small delay to allow the UI to update
      await Future.delayed(Duration(milliseconds: 100));

      // Generate the PDF file
      final pdfFile = await PdfInvoiceApi.generate(
        invoices, 
        widget.userId, 
        id, 
        servicesType, 
        collectionName, 
        pdfFileName, 
        isDeposit,
        isRefund,
        isDepositRefund
      );

      // Open the generated PDF file
      await PdfInvoiceApi.openFile(pdfFile);

    } catch (e) {
      // Handle errors during invoice generation
      showCustomDialog(
        context: context,
        title: "Invoice Generation Failed",
        content: "Could not generate invoice. Please try again.",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    } finally {
      setState(() {
        bool isGeneratingInvoice = false; // Reset loading state correctly
      });
    }
  }


  void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Please Wait'),
          content: Row(
            children: [
              CircularProgressIndicator(color: primaryColor,), // Loading indicator
              SizedBox(width: 20),
              Expanded(child: Text(message)),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
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
            Navigator.pop(context);
          },
        ),
      ),
      body: widget.tour
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: _tour != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          tourComponent(tour: _tour!),
                          const SizedBox(height: 20),
                          const Text(
                            'Availability',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: defaultLabelFontSize,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 10),
                          if (selectedSlot != null)
                            Text(
                              'Available Slots: $selectedSlot',
                              style: const TextStyle(
                                fontSize: defaultFontSize,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            )
                          else
                            Row(
                              children: [
                                Text(
                                  'Available Slot: ',
                                  style: const TextStyle(
                                    fontSize: defaultFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                Text(
                                  'No Slot available',
                                  style: const TextStyle(
                                    fontSize: defaultFontSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            
                          SizedBox(height: 15),

                          DropdownButtonFormField<String>(
                            value: selectedDateRange,
                            hint: Text('Select date range'),
                            decoration: InputDecoration(
                              labelText: 'Date Range',
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
                            // Filter the available date ranges by checking if the start date is after the current date
                            items: availableDateRanges
                                .where((range) {
                                  // Extract the start date from the date range string
                                  final startDateStr = range.split(' - ')[0]; 
                                  
                                  // Convert the start date string to a DateTime object
                                  final startDate = DateFormat('dd/MM/yyyy').parse(startDateStr);
                                  
                                  // Compare with the current date, only show future date ranges
                                  return startDate.isAfter(DateTime.now());
                                })
                                .map<DropdownMenuItem<String>>((String range) {
                                  return DropdownMenuItem<String>(
                                    value: range,
                                    child: Text(range),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedDateRange = newValue;

                                // Find the corresponding slot for the selected date range
                                var selectedAvailability = availabilityList.firstWhere(
                                  (item) {
                                    return item['dateRange'] == selectedDateRange;
                                  },
                                  orElse: () => {},
                                );

                                if (selectedAvailability.isNotEmpty) {
                                  // Update selectedSlot and price simultaneously
                                  selectedSlot = selectedAvailability['slot'] as int;
                                  price = selectedAvailability['price'] as int;
                                } else {
                                  selectedSlot = 0; // Default value if no availability found
                                  price = 0; // Default price
                                }
                              });
                            },
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: defaultFontSize,
                              color: Colors.black,
                            ),
                          ),


                          SizedBox(height: 15),

                          pax(),

                          SizedBox(height: 15),

                          Container(
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Color.fromARGB(255, 236, 250, 255),
                              border: Border.all(color: primaryColor, width: 2.5),
                              borderRadius: BorderRadius.circular(10)
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Term and Conditions',
                                  style: TextStyle(
                                    fontSize: defaultLabelFontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),
                                SizedBox(height: 10),
                                Column(
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '1. ',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Expanded( // Allow the Text to expand and wrap text
                                          child: Text(
                                            'Deposit with RM 1000.00 is required to make a reservation for the selected tour.',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '2. ',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Expanded( // Allow the Text to expand and wrap text
                                          child: Text(
                                            'Deposit are not refundable when you cancel the bookings.',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '3. ',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Expanded( // Allow the Text to expand and wrap text
                                          child: Text(
                                            'The remaining balance must be paid at least one month prior to the tour date. If the payment is not received by this deadline, your booking will be automatically canceled.',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '4. ',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Expanded( // Allow the Text to expand and wrap text
                                          child: Text(
                                            'The balance can pay through online banking.',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.justify,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if(selectedDateRange != '' && _paxController.text.isNotEmpty && _paxErrorMessage == null)...[
                            Text(
                                'Summary',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: defaultLabelFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),

                              const SizedBox(height: 5),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Deposit',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, // Set fixed width for "RM"
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(1000)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 5),

                              // Remaining Price
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Remaining Price',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, // Set fixed width for "RM"
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(remainingPrice)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),

                              Divider(),

                              // Tour Price Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Price (RM ${NumberFormat('#,##0.00').format(price!)} x ${_paxController.text})',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, // Set fixed width for "RM"
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 70,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(calculatedTotalTourPrice)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 20),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirmation"),
                                          content: Text(
                                            "Please review your booking details and read the terms and conditions carefully before proceeding with payment. A deposit of RM 1,000.00 will be charged when you click the 'Pay' button. The remaining balance must be paid at least one month before the trip date.",
                                            textAlign: TextAlign.justify,
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor: primaryColor, // Set the background color
                                                foregroundColor: Colors.white, // Set the text color
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                ),
                                              ),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close the dialog
                                                
                                                showPaymentOption(context, 'RM 1000.00', () {
                                                  bookTour(); // Call bookTour when payment option is selected
                                                }, "Tour Package");
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor: primaryColor, // Set the background color
                                                foregroundColor: Colors.white, // Set the text color
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                ),
                                              ),
                                              child: const Text("Pay"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: isBookTour
                                    ? SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 3, 
                                        ),
                                      )
                                    : Text(
                                        'Pay Deposit',
                                        style: TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),

                          ]
                        ],
                      )
                    : const Center(child: CircularProgressIndicator(color: primaryColor)), // Show a loader while fetching
              ),
            )
          : widget.carRental
              ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: _carRental != null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CarComponent(carRental: _carRental!),
                            SizedBox(height: 20),
                            _buildLocationSection(),
                            SizedBox(height: 20),
                            Text(
                              'Availability',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: defaultLabelFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Note: Only valid booking date will be enabled in the calendar. The disable date is either car maintenance or has been reserved by other customers.',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: defaultFontSize,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                            const SizedBox(height: 10),
                            _buildDatePickerTextFieldCell(
                              context,
                              _rentStartDateController, 
                              'Start Date', 
                              'Select a date',
                              onDateSelected: (DateTime selectedDate){
                                setState(() {
                                  _selectedStartDate = selectedDate;
                                });

                                DateTime firstEndDate = selectedDate.add(Duration(days:1));
                                _updateReturnDatePicker(firstEndDate);
                              }
                            ),
                            SizedBox(height: 15),
                            _buildDatePickerTextFieldCell(
                              context,
                              _rentEndDateController, 
                              'End Date', 
                              'Select a date',
                              firstDate: _getFirstReturnDate(),
                              isEndDate: true,
                              startDateSelected: _rentStartDateController.text.isNotEmpty,
                              onDateSelected: (DateTime selectedDate){
                                setState(() {
                                  _selectedEndDate = selectedDate;
                                });
                              }
                            ),
                            SizedBox(height: 15),
                            Container(
                              padding: EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 236, 250, 255),
                                border: Border.all(color: primaryColor, width: 2.5),
                                borderRadius: BorderRadius.circular(10)
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Term and Conditions',
                                    style: TextStyle(
                                      fontSize: defaultLabelFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(height: 10),
                                  Column(
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '1. ',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Expanded( // Allow the Text to expand and wrap text
                                            child: Text(
                                              'Deposit with RM 300.00 is required at the time of booking. It will be returned after car is inspected and found to be in the same condition as when rented.',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '2. ',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Expanded( // Allow the Text to expand and wrap text
                                            child: Text(
                                              'The deposit will not be refunded if the car is found to be damaged or broken.',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '3. ',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Expanded( // Allow the Text to expand and wrap text
                                            child: Text(
                                              'The bookings must be made 3 days in advanced.',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '4. ',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Expanded( // Allow the Text to expand and wrap text
                                            child: Text(
                                              'The payment can pay through online banking.',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.black,
                                              ),
                                              textAlign: TextAlign.justify,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            SizedBox(height: 20),

                            if(_selectedEndDate != null && _selectedStartDate != null)...[
                              Text(
                                'Summary',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: defaultLabelFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),

                              const SizedBox(height: 5),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Rent Price (RM ${NumberFormat('#,##0.00').format(_carRental!.price!)} x ${CRDifferenceInDays} day(s))',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, 
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(rentPrice)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),

                              SizedBox(height: 5),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Deposit (Refundable)',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, 
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(carRentalDeposit)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),

                              Divider(),

                              // Car rental Total Price Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Price',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 35, // Set fixed width for "RM"
                                        child: Text(
                                          'RM',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 60,
                                        child: Text(
                                          '${NumberFormat('#,##0.00').format(carRentalTotalPrice)}',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 20,),

                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirmation"),
                                          content: Text(
                                            "Please review your booking details and read the terms and conditions carefully before proceeding with payment.",
                                            textAlign: TextAlign.justify,
                                          ),
                                          actions: <Widget>[
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop(); // Close the dialog
                                              },
                                              style: TextButton.styleFrom(
                                                backgroundColor: primaryColor, // Set the background color
                                                foregroundColor: Colors.white, // Set the text color
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                ),
                                              ),
                                              child: const Text("Cancel"),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                  Navigator.of(context).pop(); // Close the dialog
                                                  showPaymentOption(context, 'RM ${NumberFormat('#,##0.00').format(carRentalTotalPrice)}', () {
                                                    bookCarRental(); 
                                                  }, "Car Rental");
                                                },
                                              style: TextButton.styleFrom(
                                                backgroundColor: primaryColor, // Set the background color
                                                foregroundColor: Colors.white, // Set the text color
                                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                ),
                                              ),
                                              child: const Text("Pay"),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: isBookCar
                                  ? SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3, 
                                          ),
                                        )
                                  : Text(
                                      'Book',
                                      style: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    padding: const EdgeInsets.symmetric(vertical: 15),
                                    textStyle: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ]
                          ]
                        )
                      : Center(child: CircularProgressIndicator(color: primaryColor))
                )
              )
              : widget.localBuddy
                ? SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: _localBuddy != null
                        ? Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              LBComponent(localBuddy: _localBuddy!),
                              SizedBox(height: 20),
                              Text(
                                'Availability',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: defaultLabelFontSize,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Note: Only local buddy working day and valid booking date will be enabled in the calendar.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: defaultFontSize,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              const SizedBox(height: 10),
                              _buildDatePickerLocalBuddyTextFieldCell(
                                _LbStartDateController, 
                                'Start Date', 
                                'Select a date',
                                onDateSelected: (DateTime selectedDate){
                                  setState(() {
                                    _selectedLbStartDate = selectedDate;
                                  });

                                  DateTime firstEndDate = selectedDate.add(Duration(days:0));
                                  _updateLocalBuddyEndDatePicker(firstEndDate);
                                }
                              ),
                              SizedBox(height: 15),
                              _buildDatePickerLocalBuddyTextFieldCell(
                                _LbEndDateController, 
                                'End Date', 
                                'Select a date',
                                firstDate: _getFirstLocalBuddyStartDate(),
                                isEndDate: true,
                                startDateSelected: _LbStartDateController.text.isNotEmpty,
                                onDateSelected: (DateTime selectedDate){
                                  setState(() {
                                    _selectedLbEndDate = selectedDate;
                                  });
                                }
                              ),
                              SizedBox(height: 15),
                              Container(
                                padding: EdgeInsets.all(10.0),
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 236, 250, 255),
                                  border: Border.all(color: primaryColor, width: 2.5),
                                  borderRadius: BorderRadius.circular(10)
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Term and Conditions',
                                      style: TextStyle(
                                        fontSize: defaultLabelFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                    SizedBox(height: 10),
                                    Column(
                                      children: [
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '1. ',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Expanded( // Allow the Text to expand and wrap text
                                              child: Text(
                                                'The bookings must be made 3 days in advanced.',
                                                style: TextStyle(
                                                  fontSize: defaultFontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '2. ',
                                              style: TextStyle(
                                                fontSize: defaultFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                            Expanded( // Allow the Text to expand and wrap text
                                              child: Text(
                                                'The payment can pay through online banking.',
                                                style: TextStyle(
                                                  fontSize: defaultFontSize,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.black,
                                                ),
                                                textAlign: TextAlign.justify,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: 20),

                              if(_selectedLbStartDate != null && _selectedLbEndDate != null)...[
                                Text(
                                  'Summary',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: defaultLabelFontSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.left,
                                ),

                                const SizedBox(height: 5),

                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Price (RM ${NumberFormat('#,##0.00').format(_localBuddy!.price!)} x ${LBDifferenceInDays} day(s))',
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 35, // Set fixed width for "RM"
                                          child: Text(
                                            'RM',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${NumberFormat('#,##0.00').format(LBTotalPrice)}',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                Divider(),

                                // Local Buddy Total Price Row
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Price',
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 35, // Set fixed width for "RM"
                                          child: Text(
                                            'RM',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 60,
                                          child: Text(
                                            '${NumberFormat('#,##0.00').format(LBTotalPrice)}',
                                            style: TextStyle(
                                              fontSize: defaultFontSize,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black,
                                            ),
                                            textAlign: TextAlign.right,
                                          ),
                                        )
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 20,),

                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Confirmation"),
                                            content: Text(
                                              "Please review your booking details and read the terms and conditions carefully before proceeding with payment.",
                                              textAlign: TextAlign.justify,
                                            ),
                                            actions: <Widget>[
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Close the dialog
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(); // Close the dialog
                                                  showPaymentOption(context, 'RM ${NumberFormat('#,##0.00').format(LBTotalPrice)}', () {
                                                    bookLocalBuddy(); 
                                                  }, "Local Buudy");
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor,
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                ),
                                                child: const Text("Pay"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: isBookLocalBuddy
                                      ? SizedBox(
                                          width: 20, 
                                          height: 20, 
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 3, 
                                          ),
                                        )
                                      : Text(
                                          'Book',
                                          style: TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 15),
                                      textStyle: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                )

                              ]
                            ]
                          )
                        : Center(child: CircularProgressIndicator(color: primaryColor))
                  )
                )
                : Container(
                  child: Text(
                    'Something went wrong. Please try again later...', 
                    style: TextStyle(
                      fontSize: defaultLabelFontSize, 
                      fontWeight: FontWeight.w500, 
                      color: Colors.black)
                    )
                  ) 
    );
  }

  Widget tourComponent({
    required UserViewTourList tour,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(width: 1.5, color: const Color(0xFF467BA1)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 105,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(tour.image),
                  fit: BoxFit.cover,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
                border: const Border(
                  right: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tour.tourName,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text(
                          "Agency: ",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tour.agency,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Displaying tour highlights
                    ...tour.tourHighlight.map((highlight) {
                      final no = highlight["no"] ?? 'No Numbering';
                      final description = highlight["description"] ?? 'No Description';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$no. ",
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Expanded(
                              child: Text(
                                description,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                ),
                                textAlign: TextAlign.justify,
                                maxLines: null,
                                overflow: TextOverflow.visible,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget pax() {
    return TextField(
      controller: _paxController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: defaultFontSize,
      ),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Enter number of people',
        labelText: 'Number of people',
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
        errorText: _paxErrorMessage,
      ),
      onChanged: (value) {
        // Validate the input
        int? paxValue = int.tryParse(value);
        if (paxValue == null || paxValue <= 0) {
          setState(() {
            _paxErrorMessage = 'Please enter a valid number of people';
          });
        } else if (paxValue > selectedSlot!) {
          setState(() {
            _paxErrorMessage = 'Number of people cannot exceed available slots ($selectedSlot)';
          });
        } else {
          setState(() {
            _paxErrorMessage = null; // Clear the error message if valid

            // Calculate the remaining price 
            remainingPrice = ((price! * paxValue) - 1000);

            // // Calculate the total price
            calculatedTotalTourPrice = remainingPrice! + 1000;
          });
        }
      },
    );
  }

  Widget CarComponent({required CarList carRental}) {
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 2.5),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wrap this inner Row with Expanded to make sure it takes the available space
          Expanded(
            child: Row(
              children: [
                // Image container with fixed width and height
                Container(
                  width: getScreenWidth(context) * 0.25,
                  height: getScreenHeight(context) * 0.11,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(carRental.carImage!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                // Text widget wrapped in Expanded to take remaining space
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carRental.carModel, 
                        style: TextStyle(
                          color: Colors.black, 
                          fontWeight: FontWeight.bold, 
                          fontSize: defaultLabelFontSize,
                        ),
                        overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Provider: ${carRental.agencyName}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Car Type: ${carRental.carType}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Transmission: ${carRental.transmission}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Fuel: ${carRental.fuel}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Seat: ${carRental.seat}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'RM${(carRental.price ?? 0).toStringAsFixed(0)}/day',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: defaultFontSize
                          ),
                          textAlign: TextAlign.right,
                        )
                      )
                    ],
                  )
                  
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _buildLocationContainer(),
      ],
    );
  }

  Widget _buildLocationContainer() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding( // Adding some padding to avoid text touching the container's border
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          children: [
            Text(
              'Pick Up Location',
              style: TextStyle(
                fontSize: defaultFontSize,
                fontWeight: FontWeight.w600,
                ),
            ),
            SizedBox(height: 5), // Adding some space between the title and the content
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  _carRental?.pickUpLocation ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Drop Off Location',
            style: TextStyle(
            fontSize: defaultFontSize,
            fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5), // Adding some space between the title and the content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  _carRental?.dropOffLocation ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ] ,
        ),
      ),
    );
  }

  // Future<void> _showDatePicker({
  //   required BuildContext context,
  //   required DateTime initialDate,
  //   required DateTime firstDate,
  //   required TextEditingController controller,
  //   DateTime? lastDate,
  //   void Function(DateTime)? onDateSelected,
  //   bool isEndDate = false,
  //   bool startDateSelected = true,
  // }) async {
  //   DateTime? pickedDate = await showDatePicker(
  //     context: context,
  //     initialDate: initialDate,
  //     firstDate: firstDate,
  //     lastDate: lastDate ?? DateTime(2101),
  //     selectableDayPredicate: (DateTime date) {
  //       // Disable maintenance date range
  //       for (var maintenance in _maintenanceDates) {
  //         DateTime startDate = maintenance['startDate']!;
  //         DateTime endDate = maintenance['endDate']!;

  //         // Check if the date falls on or within the maintenance range (inclusive)
  //         if ((date.isAfter(startDate) || date.isAtSameMomentAs(startDate)) &&
  //             (date.isBefore(endDate) || date.isAtSameMomentAs(endDate))) {
  //           return false; // Disable this date
  //         }
  //       }
  //       return true; // Enable other dates
  //     },
  //   );

  //   if (pickedDate != null) {
  //     String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
  //     controller.text = formattedDate;
  //     if (onDateSelected != null) {
  //       onDateSelected(pickedDate);
  //     }
  //   }
  // }

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

                // Calculate rental price when the end date is selected
                if (_selectedStartDate != null) {
                  _calculateRentalPrice();
                }
              } else {
                _selectedStartDate = selectedDate;

                // Clear end date controller and reset end date
                _rentEndDateController.text = '';
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





  // Widget _buildDatePickerTextFieldCell(
  //   TextEditingController controller,
  //   String labelText,
  //   String hintText, {
  //   DateTime? firstDate,
  //   void Function(DateTime)? onDateSelected,
  //   bool isEndDate = false,
  //   bool startDateSelected = true,
  // }) {
  //   return GestureDetector(
  //     onTap: () {},
  //     child: TextField(
  //       controller: controller,
  //       style: TextStyle(
  //         fontWeight: FontWeight.w800,
  //         fontSize: 14,
  //         color: Colors.black,
  //       ),
  //       readOnly: true,
  //       decoration: InputDecoration(
  //         hintText: hintText,
  //         labelText: labelText,
  //         filled: true,
  //         fillColor: Colors.white,
  //         border: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(10),
  //           borderSide: const BorderSide(
  //             color: Color(0xFF467BA1),
  //             width: 2.5,
  //           ),
  //         ),
  //         focusedBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(10),
  //           borderSide: const BorderSide(
  //             color: Color(0xFF467BA1),
  //             width: 2.5,
  //           ),
  //         ),
  //         enabledBorder: OutlineInputBorder(
  //           borderRadius: BorderRadius.circular(10),
  //           borderSide: const BorderSide(
  //             color: Color(0xFF467BA1),
  //             width: 2.5,
  //           ),
  //         ),
  //         floatingLabelBehavior: FloatingLabelBehavior.always,
  //         labelStyle: const TextStyle(
  //           fontSize: 14,
  //           fontWeight: FontWeight.bold,
  //           color: Colors.black87,
  //         ),
  //         suffixIcon: IconButton(
  //           icon: const Icon(
  //             Icons.calendar_today_outlined,
  //             color: Color(0xFF467BA1),
  //             size: 20,
  //           ),
  //           onPressed: () {
  //             DateTime initialDate = controller.text.isNotEmpty
  //                 ? DateFormat('dd/MM/yyyy').parse(controller.text)
  //                 : DateTime.now(); // Use the text if available

  //             // Ensure the initial date for end date is at least the next day
  //             DateTime firstEndDate = isEndDate
  //                 ? _selectedStartDate?.add(Duration(days: 1)) ?? DateTime.now()
  //                 : initialDate;

  //             // Use the next selectable date for the initial end date
  //             initialDate = _findNextSelectableDate(firstEndDate);

  //             print("Initial Date: ${initialDate}");

  //             _showDatePicker(
  //               context: context,
  //               initialDate: initialDate,
  //               firstDate: firstDate ?? DateTime.now(),
  //               controller: controller,
  //               onDateSelected: (DateTime selectedDate) {
  //                 if (isEndDate) {
  //                   _selectedEndDate = selectedDate;

  //                   // Calculate the rental price when the end date is selected
  //                   if (_selectedStartDate != null) {
  //                     _calculateRentalPrice();
  //                   }
  //                 } else {
  //                   _selectedStartDate = selectedDate;

  //                   // Clear the end date controller and reset the end date
  //                   _rentEndDateController.text = '';
  //                   _selectedEndDate = null;
  //                 }

  //                 // Call the onDateSelected callback if provided
  //                 if (onDateSelected != null) {
  //                   onDateSelected(selectedDate);
  //                 }
  //               },
  //               isEndDate: isEndDate,
  //               startDateSelected: _selectedStartDate != null,
  //             );
  //           },
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _calculateRentalPrice() {
  if (_selectedStartDate != null && _selectedEndDate != null) {
    // Calculate the total number of days between start and end dates
    int totalDays = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;

    // Create a list of all dates in the range
    List<DateTime> dateRange = List.generate(
      totalDays,
      (index) => _selectedStartDate!.add(Duration(days: index)),
    );

    // Add valid dates to the bookingDates array, excluding maintenance and car rental booking dates
    List<DateTime> validBookingDates = [];
    for (DateTime date in dateRange) {
      if (!_maintenanceDates.contains(date) && !_carRentalBookingDates.contains(date)) {
        validBookingDates.add(date);
      }
    }

    // Count maintenance and booking dates within the selected range
    int maintenanceAndBookingDays = dateRange.where((date) =>
      _maintenanceDates.contains(date) || _carRentalBookingDates.contains(date)
    ).length;

    // Calculate the effective rental days
    int effectiveRentalDays = totalDays - maintenanceAndBookingDays;

    setState(() {
      CRDifferenceInDays = effectiveRentalDays;
      double pricePerDay = _carRental!.price!.toDouble();
      rentPrice = effectiveRentalDays * pricePerDay;
      carRentalTotalPrice = rentPrice! + carRentalDeposit;
      selectedBookingDates = validBookingDates;

      // Format valid booking dates as "dd/MM/yyyy" and join them into a single string
      final dateFormat = DateFormat('dd/MM/yyyy');
      selectedBookingDateString = selectedBookingDates.map((date) => dateFormat.format(date)).join(', ');
    });

    print("Selected booking dates: $selectedBookingDates");
    print("Selected booking dates string: $selectedBookingDateString");
  } else {
    print('Please select both start and end dates.');
  }
}



  // void _calculateRentalPrice() {
  //   if (_selectedStartDate != null && _selectedEndDate != null) {
  //     // Calculate the total number of days between start and end dates
  //     int totalDays = _selectedEndDate!.difference(_selectedStartDate!).inDays + 1;

  //     // Create a list of all dates in the range
  //     List<DateTime> dateRange = List.generate(totalDays, 
  //       (index) => _selectedStartDate!.add(Duration(days: index)));
      
  //     // Clear the bookingDates array before adding new dates
  //     selectedBookingDates.clear();

  //     // Add valid dates to the bookingDates array, excluding maintenance dates
  //     for (DateTime date in dateRange) {
  //       if (!_maintenanceDates.contains(date)) {
  //         selectedBookingDates.add(date);
  //       }
  //     }

  //     for(var date in selectedBookingDates){
  //       print("Selected booking date: $date");
  //     }

  //     // Count maintenance dates within the selected range
  //     int maintenanceDays = dateRange.where((date) => _maintenanceDates.contains(date)).length;

  //     // Calculate the effective rental days
  //     int effectiveRentalDays = totalDays - maintenanceDays;

  //     setState(() {
  //         CRDifferenceInDays = effectiveRentalDays;
  //         double pricePerDay = _carRental!.price!.toDouble(); 
  //         rentPrice = effectiveRentalDays * pricePerDay;
  //         carRentalTotalPrice = rentPrice! + carRentalDeposit;
  //     });
  //   } else {
  //     print('Please select both start and end dates.');
  //   }
  // }


  void _updateReturnDatePicker(DateTime firstDate) {
    setState(() {
      // Reset the return date controller
      _rentEndDateController.clear();
      _rentEndDateController.text = ""; // Resetting the text field
    });
  }

  DateTime _getFirstReturnDate() {
    // Return the first available return date based on the selected depart date or a default date
    return _selectedStartDate?.add(const Duration(days: 0)) ?? DateTime.now().add(const Duration(days: 0));
  }

  void _showSelectStartDateFirstMessage() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Start Date First"),
        content: const Text("Please select the renatl start date before choosing the rental end date."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Widget LBComponent({required LocalBuddy localBuddy}) {
    return Container(
      padding: EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 2.5),
        borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Wrap this inner Row with Expanded to make sure it takes the available space
          Expanded(
            child: Row(
              children: [
                // Image container with fixed width and height
                Container(
                  width: getScreenWidth(context) * 0.2,
                  height: getScreenHeight(context) * 0.15,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(localBuddy.localBuddyImage),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Text widget wrapped in Expanded to take remaining space
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localBuddy.localBuddyName, 
                        style: TextStyle(
                          color: Colors.black, 
                          fontWeight: FontWeight.bold, 
                          fontSize: defaultLabelFontSize,
                        ),
                        overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Location: ${localBuddy.locationArea}',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: defaultFontSize
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Container(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          'RM${(localBuddy.price ?? 0).toStringAsFixed(0)}/day',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: defaultFontSize
                          ),
                          textAlign: TextAlign.right,
                        )
                      )
                    ],
                  )
                  
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  DateTime _getFirstLocalBuddyStartDate() {
    // Return the first available return date based on the selected depart date or a default date
    return _selectedLbStartDate?.add(const Duration(days: 0)) ?? DateTime.now().add(const Duration(days: 0));
  }

    DateTime _getNextValidDate(List<int> validWeekdays, DateTime firstDate) {
    // Start with firstDate instead of DateTime.now() to ensure initial date is valid
    DateTime currentDate = firstDate;

    // Keep adding days until we find a valid one
    while (!validWeekdays.contains(currentDate.weekday)) {
      currentDate = currentDate.add(Duration(days: 1));
    }

    return currentDate;
  }


  void _updateLocalBuddyEndDatePicker(DateTime firstDate) {
    setState(() {
      // Reset the return date controller
      _LbEndDateController.clear();
      _LbEndDateController.text = ""; // Resetting the text field
    });
  }

  Widget _buildDatePickerLocalBuddyTextFieldCell(
  TextEditingController controller,
  String labeltext,
  String hintText, {
  DateTime? firstDate,
  void Function(DateTime)? onDateSelected,
  bool isEndDate = false,
  bool startDateSelected = true,
}) {
  return GestureDetector(
    onTap: () async {
      if (isEndDate && !startDateSelected) {
        _showSelectStartDateFirstMessage();
        return;
      }

      // Get valid weekdays from availableLocalBuddyDay
      List<int> validWeekdays = _getValidWeekdays(availableLocalBuddyDay);

      // Calculate the initial date as three days from now
      DateTime initialDate = DateTime.now().add(Duration(days: 4));
      DateTime firstAvailableDate = firstDate ?? _getNextValidDate(validWeekdays, initialDate);

      // For the end date picker, set the first available date to the selected start date or the first valid date
      if (isEndDate && _selectedLbStartDate != null) {
        firstAvailableDate = _selectedLbStartDate!;
      } else if (isEndDate && _selectedLbStartDate == null) {
        _showSelectStartDateFirstMessage();
        return;
      }

      // Ensure initialEndDate for end date picker starts from selected start date or is the first valid date
      DateTime initialEndDate = _selectedLbStartDate ?? initialDate; // Use selected start date or next valid date
      if (initialEndDate.isBefore(firstAvailableDate)) {
        initialEndDate = firstAvailableDate; // Adjust if it is before the first available date
      }

      // Show the date picker with valid dates and constraints
      DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: initialEndDate,
        firstDate: firstAvailableDate,
        lastDate: DateTime(2101),
        selectableDayPredicate: (DateTime day) {
          // Disable dates that are not valid weekdays or already booked
          return validWeekdays.contains(day.weekday) &&
              !_localBuddyBookingDates.contains(day) && // Check against booked dates
              day.isAfter(DateTime.now().add(Duration(days: 2))); // Ensure it's more than 2 days away
        },
      );

      // Calculate the number of valid days between start date and end date
      if (pickedDate != null) {
        if (isEndDate && _selectedLbStartDate != null) {
          // Debugging information
          print("Selected Start Date: ${_selectedLbStartDate}");
          print("Picked End Date: $pickedDate");

          // Count the valid days between start date and end date
          int validDaysCount = 0;
          selectedLocalBuddyBookingDates.clear();

          for (DateTime date = _selectedLbStartDate!; date.isBefore(pickedDate) || date.isAtSameMomentAs(pickedDate); date = date.add(Duration(days: 1))) {
            if (validWeekdays.contains(date.weekday) && !_localBuddyBookingDates.contains(date)) {
              validDaysCount++;
              selectedLocalBuddyBookingDates.add(date);
              print("Valid Date: $date");
            }
          }

          // Debugging: print total valid days
          print("Total Valid Days: $validDaysCount");

          setState(() {
            LBDifferenceInDays = validDaysCount;
            double price = _localBuddy!.price!.toDouble(); // Convert to double if it's an int
            LBTotalPrice = (LBDifferenceInDays! * price); // Now this is safe as both are doubles

            final dateFormat = DateFormat('dd/MM/yyyy');
            selectedLocalBuddyBookingDateString = selectedLocalBuddyBookingDates.map((date) => dateFormat.format(date)).join(', ');
          });

          print("Selected booking dates: $selectedLocalBuddyBookingDates");
          print("Selected booking dates string: $selectedLocalBuddyBookingDateString");

          // // Store the difference in days for further calculations
          // LBDifferenceInDays = validDaysCount;

          // // Calculate total price based on valid booking days
          // double price = _localBuddy!.price!.toDouble(); // Convert to double if it's an int
          // LBTotalPrice = (LBDifferenceInDays! * price); // Now this is safe as both are doubles
        }

        // Format the picked date
        controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);

        // If a date is selected, trigger the callback
        if (onDateSelected != null) {
          onDateSelected(pickedDate);
        }
      }
    },
    child: AbsorbPointer(
      child: TextField(
        controller: controller,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: defaultFontSize,
          color: Colors.black,
        ),
        readOnly: true,
        decoration: InputDecoration(
          hintText: hintText,
          labelText: labeltext,
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
            onPressed: () async {
              // Date picker logic handled in onTap
            },
          ),
        ),
      ),
    ),
  );
}

  // Widget _buildDatePickerLocalBuddyTextFieldCell(
  //   TextEditingController controller,
  //   String labeltext,
  //   String hintText, {
  //   DateTime? firstDate,
  //   void Function(DateTime)? onDateSelected,
  //   bool isEndDate = false,
  //   bool startDateSelected = true,
  // }) {
  //   return GestureDetector(
  //     onTap: () async {
  //       if (isEndDate && !startDateSelected) {
  //         // Show a message asking the user to select the start date first
  //         _showSelectStartDateFirstMessage();
  //         return;
  //       }

  //       // Get valid weekdays from availableLocalBuddyDay
  //       List<int> validWeekdays = _getValidWeekdays(availableLocalBuddyDay);

  //       // For the start date picker, find the next valid date
  //       DateTime initialDate = _getNextValidDate(validWeekdays, DateTime.now());
  //       DateTime firstAvailableDate = firstDate ?? initialDate;

  //       // For the end date picker, set the first available date to the selected start date or the first valid date
  //       if (isEndDate && _selectedLbStartDate != null) {
  //         firstAvailableDate = _selectedLbStartDate!;
  //       } else {
  //         // If no start date is selected, show a message and return
  //         if (isEndDate && _selectedLbStartDate == null) {
  //           _showSelectStartDateFirstMessage();
  //           return;
  //         }
  //       }

  //       // Ensure initialDate for end date picker starts from selected start date or is the first valid date
  //       DateTime initialEndDate = _selectedLbStartDate ?? initialDate; // Use selected start date or next valid date
  //       if (initialEndDate.isBefore(firstAvailableDate)) {
  //         initialEndDate = firstAvailableDate; // Adjust if it is before the first available date
  //       }

  //       // Show the date picker with valid dates and constraints
  //       DateTime? pickedDate = await showDatePicker(
  //         context: context,
  //         initialDate: initialEndDate,
  //         firstDate: firstAvailableDate,
  //         lastDate: DateTime(2101),
  //         selectableDayPredicate: (DateTime day) {
  //           return (validWeekdays.contains(day.weekday));
  //         },
  //       );

  //       // Calculate the number of days between start date and end date
  //       if (isEndDate && _selectedLbStartDate != null) {
  //         LBDifferenceInDays = pickedDate!.difference(_selectedLbStartDate!).inDays + 1;

  //         setState(() { 
  //           // Ensure _localBuddy.price is treated as a double
  //           double price = _localBuddy!.price!.toDouble(); // Convert to double if it's an int
  //           LBTotalPrice = (LBDifferenceInDays! * price); // Now this is safe as both are doubles
  //         });

  //       }

  //       if (pickedDate != null) {
  //         // Format the picked date
  //         controller.text = DateFormat('dd/MM/yyyy').format(pickedDate);

  //         // If a date is selected, trigger the callback
  //         if (onDateSelected != null) {
  //           onDateSelected(pickedDate);
  //         }
  //       }
  //     },
  //     child: AbsorbPointer(
  //       child: TextField(
  //         controller: controller,
  //         style: TextStyle(
  //           fontWeight: FontWeight.w800,
  //           fontSize: defaultFontSize,
  //           color: Colors.black,
  //         ),
  //         readOnly: true,
  //         decoration: InputDecoration(
  //           hintText: hintText,
  //           labelText: labeltext,
  //           filled: true,
  //           fillColor: Colors.white,
  //           border: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(10),
  //             borderSide: const BorderSide(
  //               color: Color(0xFF467BA1),
  //               width: 2.5,
  //             ),
  //           ),
  //           focusedBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(10),
  //             borderSide: const BorderSide(
  //               color: Color(0xFF467BA1),
  //               width: 2.5,
  //             ),
  //           ),
  //           enabledBorder: OutlineInputBorder(
  //             borderRadius: BorderRadius.circular(10),
  //             borderSide: const BorderSide(
  //               color: Color(0xFF467BA1),
  //               width: 2.5,
  //             ),
  //           ),
  //           floatingLabelBehavior: FloatingLabelBehavior.always,
  //           labelStyle: const TextStyle(
  //             fontSize: defaultLabelFontSize,
  //             fontWeight: FontWeight.bold,
  //             color: Colors.black87,
  //             shadows: [
  //               Shadow(
  //                 offset: Offset(0.5, 0.5),
  //                 color: Colors.black87,
  //               ),
  //             ],
  //           ),
  //           suffixIcon: IconButton(
  //             icon: const Icon(
  //               Icons.calendar_today_outlined,
  //               color: Color(0xFF467BA1),
  //               size: 20,
  //             ),
  //             onPressed: () async {
  //               // Date picker logic handled in onTap
  //             },
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}


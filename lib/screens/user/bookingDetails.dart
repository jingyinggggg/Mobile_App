import 'dart:io';

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class BookingDetailsScreen extends StatefulWidget {
  final String userID;
  final String? tourID;
  final String? carRentalID;
  final String? localBuddyID;
  final String? tourBookingID;
  final String? carRentalBookingID;
  final String? localBuddyBookingID;

  const BookingDetailsScreen({
    super.key, 
    required this.userID,
    this.tourID,
    this.carRentalID,
    this.localBuddyID,
    this.tourBookingID,
    this.carRentalBookingID,
    this.localBuddyBookingID
  });

  @override
  State<BookingDetailsScreen> createState() => _BookingDetailsScreenState();
}

class _BookingDetailsScreenState extends State<BookingDetailsScreen> {

  bool isFetchingCustomerDetails = false;
  bool isFetchingTourBooking = false;
  bool isFetchingCarBooking = false;
  bool isFetchingLocalBuddyBooking = false;
  bool isFetchingTour = false;
  bool isFetchingCar = false;
  bool isFetchingLocalBuddy = false;
  bool isOpenFile = false;
  bool isOpenFullPayment = false;
  bool isOpenDepositRefund = false;
  bool isOpenRefundInvoice = false;
  Map<String, dynamic>? tourData;
  Map<String, dynamic>? carData;
  Map<String, dynamic>? localBuddyData;
  Map<String, dynamic>? tourBookingData;
  Map<String, dynamic>? carBookingData;
  Map<String, dynamic>? localBuddyBookingData;

  @override
  void initState() {
    super.initState();
    if(widget.tourBookingID != null){
      _fetchTourBookingDetails();
      _fetchTourDetails();
    } else if(widget.carRentalBookingID != null){
      _fetchCarBookingDetails();
      _fetchCarDetails();
    } else if(widget.localBuddyBookingID != null){
      _fetchLocalBuddyBookingDetails();
      _fetchLocalBuddyDetails();
    }
  }

  Future<void>_fetchTourBookingDetails() async {
    setState(() {
      isFetchingTourBooking = true;
    });
    try{
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourBooking').doc(widget.tourBookingID);
      DocumentSnapshot tourSnapshot = await tourRef.get();

      if(tourSnapshot.exists){
        Map<String, dynamic>? data = tourSnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          tourBookingData = data;
        });
      }
    } catch(e){
      print('Error fetch tour booking data: $e');
    } finally{
      setState(() {
        isFetchingTourBooking = false;
      });
    }
  }

  Future<void> _fetchCarBookingDetails() async {
  setState(() {
    isFetchingCarBooking = true;
  });
  try {
    DocumentReference carRef = FirebaseFirestore.instance
        .collection('carRentalBooking')
        .doc(widget.carRentalBookingID);
    DocumentSnapshot carSnapshot = await carRef.get();

    if (carSnapshot.exists) {
      Map<String, dynamic>? data = carSnapshot.data() as Map<String, dynamic>?;
      // Convert booking dates from Timestamp to DateTime
      if (data != null && data['bookingDate'] != null) {
        List<Timestamp> timestamps = List<Timestamp>.from(data['bookingDate']);
        List<DateTime> bookingDates =
            timestamps.map((timestamp) => timestamp.toDate()).toList();

        setState(() {
          carBookingData = data;
          carBookingData!['bookingDate'] = bookingDates; // Update bookingDate with DateTime list
        });

        // Print the car booking data to the console
        print("Car Booking Data: $carBookingData");
      }
    }
  } catch (e) {
    print('Error fetching car booking data: $e');
  } finally {
    setState(() {
      isFetchingCarBooking = false;
    });
  }
}


  Future<void>_fetchLocalBuddyBookingDetails() async {
    setState(() {
      isFetchingLocalBuddy = true;
    });
    try{
      DocumentReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddyBooking').doc(widget.localBuddyBookingID);
      DocumentSnapshot localBuddySnapshot = await localBuddyRef.get();

      if(localBuddySnapshot.exists){
        Map<String, dynamic>? data = localBuddySnapshot.data() as  Map<String, dynamic>?;
        if (data != null && data['bookingDate'] != null) {
          List<Timestamp> timestamps = List<Timestamp>.from(data['bookingDate']);
          List<DateTime> bookingDates = timestamps.map((timestamp) => timestamp.toDate()).toList();

          setState(() {
            localBuddyBookingData = data;
            localBuddyBookingData!['bookingDate'] = bookingDates; // Update bookingDate with DateTime list
          });
        }
        // setState(() {
        //   localBuddyBookingData = data;
        // });
      }
    } catch(e){
      print('Error fetch local buddy booking data: $e');
    } finally{
      setState(() {
        isFetchingLocalBuddy = false;
      });
    }
  }

  Future<void>_fetchTourDetails() async {
    setState(() {
      isFetchingTour = true;
    });
    try{
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot tourSnapshot = await tourRef.get();

      if(tourSnapshot.exists){
        Map<String, dynamic>? data = tourSnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          tourData = data;
        });
      }
    } catch(e){
      print('Error fetch tour data: $e');
    } finally{
      setState(() {
        isFetchingTour = false;
      });
    }
  }

  Future<void>_fetchCarDetails() async {
    setState(() {
      isFetchingCar = true;
    });
    try{
      DocumentReference carRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carRentalID);
      DocumentSnapshot carSnapshot = await carRef.get();

      if(carSnapshot.exists){
        Map<String, dynamic>? data = carSnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          carData = data;
        });
      }
    } catch(e){
      print('Error fetch car data: $e');
    } finally{
      setState(() {
        isFetchingCar = false;
      });
    }
  }

  Future<void>_fetchLocalBuddyDetails() async {
    setState(() {
      isFetchingLocalBuddy = true;
    });
    try{
      DocumentReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyID);
      DocumentSnapshot localBuddySnapshot = await localBuddyRef.get();

      if(localBuddySnapshot.exists){
        Map<String, dynamic>? data = localBuddySnapshot.data() as  Map<String, dynamic>?;

        if(data != null){
          DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(data['userID']);
          DocumentSnapshot userSnapshot = await userRef.get();

           Map<String, dynamic>? userData = userSnapshot.data() as  Map<String, dynamic>?;

           if (userData != null) {
            // Add user name and profile image to local buddy data
            data['localBuddyName'] = userData['name'] ?? 'Unknown Name';
            data['profileImage'] = userData['profileImage'] ?? 'default_image_url';
          }

        }
        setState(() {
          localBuddyData = data;
        });
      }
    } catch(e){
      print('Error fetch local buddy data: $e');
    } finally{
      setState(() {
        isFetchingLocalBuddy = false;
      });
    }
  }

  Future<void> downloadAndOpenPdfFromUrl(String url, String fileName) async {
    try {
      // Get the directory to store the file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$fileName.pdf');
      
      // Download the file from the URL using Dio
      final response = await Dio().download(url, file.path);
      
      // Check if the download was successful
      if (response.statusCode == 200) {
        
        // Open the file
        final result = await OpenFile.open(file.path);
      } else {
        print("Failed to download file: ${response.statusCode}");
      }
    } catch (e) {
      // Handle errors
      print("Error downloading or opening the file: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            width: 45,
            child: IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatDetailsScreen(userId: widget.userID, receiverUserId: widget.localBuddyID != null ? localBuddyData!['userID'] : widget.carRentalID != null ? carData!['agencyID'] : tourData!['agentID']))
                );
              },
              icon: ImageIcon(
                AssetImage('images/chat.png'),
                color: Colors.white,
                size: 21,
              ),
              tooltip: widget.localBuddyID != null ? "Chat with local buddy" : "Chat with agent",
            )
          ),
        ],
      ),
      body: isFetchingCustomerDetails || isFetchingCarBooking || isFetchingTourBooking || isFetchingLocalBuddyBooking
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(15.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.tourBookingID != null
                  ? Column(
                    children: [
                        tourComponent(data: tourBookingData!, tourData: tourData!),
                        if(tourBookingData!['bookingStatus'] == 2)...[
                          SizedBox(height: 10,),
                          Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Cancel Reason: ${tourBookingData!['cancelReason'] ?? "N/A" }",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          )
                        ],
                        SizedBox(height: 10),
                        Container(
                          alignment: Alignment.topCenter,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.black, width: 1.5),
                              bottom: BorderSide(color: Colors.black, width: 1.5),
                            ),
                          ),
                          child: Text(
                            'Invoice Summary',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 100,
                              child: Text(
                                "Deposit Invoice",
                                style: TextStyle(
                                  fontSize: defaultFontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              ":",
                              style: TextStyle(
                                fontSize: defaultFontSize,
                                color: Colors.black,
                                fontWeight: FontWeight.w600
                              ),
                            ),
                            SizedBox(width: 10),
                            if(tourBookingData!['depositInvoice'] != null)
                              isOpenFile
                              ? SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(color: primaryColor),
                                ) 
                              : SizedBox(
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isOpenFile = true; // Update the loading state
                                    });
                                    String url = tourBookingData!['depositInvoice']; 
                                    String fileName = 'deposit_invoice'; 
                                    await downloadAndOpenPdfFromUrl(url, fileName);
                                    setState(() {
                                      isOpenFile = false; // Update the state when done
                                    });
                                  }, 
                                  child:Text(
                                    "View Deposit Invoice",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,  
                                    foregroundColor: primaryColor,  
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: primaryColor, width: 2),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                  ),
                                )
                              )
                            else
                              Text(
                                "N/A",
                                style: TextStyle(
                                  fontSize: defaultFontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Container(
                              width: 100,
                              child: Text(
                                "Full Payment Invoice",
                                style: TextStyle(
                                  fontSize: defaultFontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                            ),
                            SizedBox(width: 5),
                            Text(
                              ":",
                              style: TextStyle(
                                fontSize: defaultFontSize,
                                color: Colors.black,
                                fontWeight: FontWeight.w600
                              ),
                            ),
                            SizedBox(width: 10),
                            if(tourBookingData!['invoice'] != null)
                              isOpenFullPayment
                              ? SizedBox(
                                  width: 20.0,
                                  height: 20.0,
                                  child: CircularProgressIndicator(color: primaryColor),
                                ) 
                              : SizedBox(
                                height: 35,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() {
                                      isOpenFullPayment = true; // Update the loading state
                                    });
                                    String url = tourBookingData!['invoice']; 
                                    String fileName = 'balance_payment'; 
                                    await downloadAndOpenPdfFromUrl(url, fileName);
                                    setState(() {
                                      isOpenFullPayment = false; // Update the state when done
                                    });
                                  }, 
                                  child:Text(
                                    "View Full Payment Invoice",
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,  
                                    foregroundColor: primaryColor,  
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(color: primaryColor, width: 2),
                                      borderRadius: BorderRadius.circular(10)
                                    ),
                                  ),
                                )
                              )
                            else
                              Text(
                                "N/A",
                                style: TextStyle(
                                  fontSize: defaultFontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : widget.carRentalID != null
                    ? Column(
                        children: [
                          carComponent(data: carBookingData!, carData: carData!),
                          if(carBookingData!['bookingStatus'] == 2)...[
                            SizedBox(height: 10,),
                            Container(
                            alignment: Alignment.topLeft,
                            child: Text(
                              "Cancel Reason: ${carBookingData!['cancelReason'] ?? "N/A" }",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black,
                                fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          )
                          ],
                          SizedBox(height: 10),
                          Container(
                            alignment: Alignment.topCenter,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1.5),
                                bottom: BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            child: Text(
                              'Car Details',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                          Container(
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
                                        carData!['pickUpLocation'] ?? 'N/A',
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
                                        carData!['dropOffLocation'] ?? 'N/A',
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
                          ),
                          SizedBox(height: 20),
                          Container(
                            alignment: Alignment.topCenter,
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.black, width: 1.5),
                                bottom: BorderSide(color: Colors.black, width: 1.5),
                              ),
                            ),
                            child: Text(
                              'Invoice Summary',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            children: [
                              Container(
                                width: 100,
                                child: Text(
                                  "Full Payment Invoice",
                                  style: TextStyle(
                                    fontSize: defaultFontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                              ),
                              SizedBox(width: 5),
                              Text(
                                ":",
                                style: TextStyle(
                                  fontSize: defaultFontSize,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w600
                                ),
                              ),
                              SizedBox(width: 10),
                              if(carBookingData!['invoice'] != null)
                                isOpenFile
                                ? SizedBox(
                                    width: 20.0,
                                    height: 20.0,
                                    child: CircularProgressIndicator(color: primaryColor),
                                  ) 
                                : SizedBox(
                                  height: 35,
                                  child: ElevatedButton(
                                    onPressed: () async {
                                      setState(() {
                                        isOpenFile = true; // Update the loading state
                                      });
                                      String url = carBookingData!['invoice']; 
                                      String fileName = 'invoice'; 
                                      await downloadAndOpenPdfFromUrl(url, fileName);
                                      setState(() {
                                        isOpenFile = false; // Update the state when done
                                      });
                                    }, 
                                    child:Text(
                                      "View Invoice",
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,  
                                      foregroundColor: primaryColor,  
                                      shape: RoundedRectangleBorder(
                                        side: BorderSide(color: primaryColor, width: 2),
                                        borderRadius: BorderRadius.circular(10)
                                      ),
                                    ),
                                  )
                                )
                              else
                                Text(
                                  "N/A",
                                  style: TextStyle(
                                    fontSize: defaultFontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                            ],
                          ),
                          SizedBox(height: 20),
                          if(carBookingData!['bookingStatus'] == 1)...[
                            Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        "Deposit Refund Invoice",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      ":",
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    if(carBookingData!['depositRefundInvoice'] != null)
                                      isOpenDepositRefund
                                      ? SizedBox(
                                          width: 20.0,
                                          height: 20.0,
                                          child: CircularProgressIndicator(color: primaryColor),
                                        ) 
                                      : SizedBox(
                                        height: 35,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            setState(() {
                                              isOpenDepositRefund = true; // Update the loading state
                                            });
                                            String url = carBookingData!['depositRefundInvoice']; 
                                            String fileName = 'deposit_refund_invoice'; 
                                            await downloadAndOpenPdfFromUrl(url, fileName);
                                            setState(() {
                                              isOpenDepositRefund = false; // Update the state when done
                                            });
                                          }, 
                                          child:Text(
                                            "View Refund Deposit Invoice",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,  
                                            foregroundColor: primaryColor,  
                                            shape: RoundedRectangleBorder(
                                              side: BorderSide(color: primaryColor, width: 2),
                                              borderRadius: BorderRadius.circular(10)
                                            ),
                                          ),
                                        )
                                      )
                                    else if (carBookingData!['isRefundDeposit'] == 2)
                                      Expanded(
                                        child: Text(
                                          'Your deposit refund request is rejected by travel agent.',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )
                                    else 
                                      Text(
                                        "N/A",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                  ],
                                ),
                                SizedBox(height: 10),
                                if(carBookingData!['isRefundDeposit'] == 2)...[
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        child: Text(
                                          "Reject Reason",
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        ":",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          carBookingData!['rejectDepositRefundReason'],
                                          style: TextStyle(
                                              fontSize: defaultFontSize,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )
                                    ],
                                  ),
                                  SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 100,
                                        child: Text(
                                          "Reject Proof",
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        ":",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                    ],
                                  ),
                                  SizedBox(height: 5),
                                  Container(
                                    width: double.infinity,
                                    height: 200,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
                                    ),
                                    child: Image.network(
                                      carBookingData!['rejectProof'],
                                      fit: BoxFit.contain,
                                    ),
                                  )
                                ]
                                
                              ],
                            )
                          ]
                            
                          else if (carBookingData!['bookingStatus'] == 2)
                          Row(
                              children: [
                                Container(
                                  width: 100,
                                  child: Text(
                                    "Refund Invoice",
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  ":",
                                  style: TextStyle(
                                    fontSize: defaultFontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                SizedBox(width: 10),
                                if(carBookingData!['refundInvoice'] != null)
                                  isOpenRefundInvoice
                                  ? SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(color: primaryColor),
                                    ) 
                                  : SizedBox(
                                    height: 35,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          isOpenRefundInvoice = true; // Update the loading state
                                        });
                                        String url = carBookingData!['refundInvoice']; 
                                        String fileName = 'refund_invoice'; 
                                        await downloadAndOpenPdfFromUrl(url, fileName);
                                        setState(() {
                                          isOpenRefundInvoice = false; // Update the state when done
                                        });
                                      }, 
                                      child:Text(
                                        "View Refund Invoice",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,  
                                        foregroundColor: primaryColor,  
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(color: primaryColor, width: 2),
                                          borderRadius: BorderRadius.circular(10)
                                        ),
                                      ),
                                    )
                                  )
                                else
                                  Text(
                                    "N/A",
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                              ],
                            )
                        ],
                      )
                    : widget.localBuddyID != null && localBuddyBookingData != null && localBuddyData != null
                      ? Column(
                          children: [
                            localBuddyComponent(data: localBuddyBookingData!, localBuddyData: localBuddyData!),
                            if(localBuddyBookingData!['bookingStatus'] == 2)...[
                              SizedBox(height: 10,),
                              Container(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  "Cancel Reason: ${localBuddyBookingData!['cancelReason'] ?? "N/A" }",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              )
                            ],
                            SizedBox(height: 10),
                            Container(
                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.black, width: 1.5),
                                  bottom: BorderSide(color: Colors.black, width: 1.5),
                                ),
                              ),
                              child: Text(
                                'Invoice Summary',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20),
                            Row(
                              children: [
                                Container(
                                  width: 100,
                                  child: Text(
                                    "Full Payment Invoice",
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Text(
                                  ":",
                                  style: TextStyle(
                                    fontSize: defaultFontSize,
                                    color: Colors.black,
                                    fontWeight: FontWeight.w600
                                  ),
                                ),
                                SizedBox(width: 10),
                                if(localBuddyBookingData!['invoice'] != null)
                                  isOpenFile
                                  ? SizedBox(
                                      width: 20.0,
                                      height: 20.0,
                                      child: CircularProgressIndicator(color: primaryColor),
                                    ) 
                                  : SizedBox(
                                    height: 35,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        setState(() {
                                          isOpenFile = true; // Update the loading state
                                        });
                                        String url = localBuddyBookingData!['invoice']; 
                                        String fileName = 'invoice'; 
                                        await downloadAndOpenPdfFromUrl(url, fileName);
                                        setState(() {
                                          isOpenFile = false; // Update the state when done
                                        });
                                      }, 
                                      child:Text(
                                        "View Invoice",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,  
                                        foregroundColor: primaryColor,  
                                        shape: RoundedRectangleBorder(
                                          side: BorderSide(color: primaryColor, width: 2),
                                          borderRadius: BorderRadius.circular(10)
                                        ),
                                      ),
                                    )
                                  )
                                else
                                  Text(
                                    "N/A",
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 20),
                            if(localBuddyBookingData!['bookingStatus'] == 2)
                              Row(
                                children: [
                                  Container(
                                    width: 100,
                                    child: Text(
                                      "Refund Invoice",
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    ":",
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      color: Colors.black,
                                      fontWeight: FontWeight.w600
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  if(localBuddyBookingData!['refundInvoice'] != null)
                                    isOpenRefundInvoice
                                    ? SizedBox(
                                        width: 20.0,
                                        height: 20.0,
                                        child: CircularProgressIndicator(color: primaryColor),
                                      ) 
                                    : SizedBox(
                                      height: 35,
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          setState(() {
                                            isOpenRefundInvoice = true; // Update the loading state
                                          });
                                          String url = localBuddyBookingData!['refundInvoice']; 
                                          String fileName = 'refund_invoice'; 
                                          await downloadAndOpenPdfFromUrl(url, fileName);
                                          setState(() {
                                            isOpenRefundInvoice = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Refund Invoice",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,  
                                          foregroundColor: primaryColor,  
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: primaryColor, width: 2),
                                            borderRadius: BorderRadius.circular(10)
                                          ),
                                        ),
                                      )
                                    )
                                  else
                                    Text(
                                      "N/A",
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600
                                      ),
                                    ),
                                ],
                              )
                          ],
                        )
                      : Container()
                ]
              ),
            ),
          )
    );    
  }

  Widget tourComponent({required Map<String, dynamic> data, required Map<String, dynamic> tourData}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border:Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ID: ${data['bookingID'] ?? "N/A"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: data['bookingStatus'] == 0
                        ? Colors.orange.shade100
                        : data['bookingStatus'] == 1
                            ? Colors.green.shade100
                            : data['bookingStatus'] == 2
                                ? Colors.red.shade100
                                : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    data['bookingStatus'] == 0
                        ? "Upcoming"
                        : data['bookingStatus'] == 1
                            ? "Completed"
                            : data['bookingStatus'] == 2
                                ? "Canceled"
                                : "Unknown",
                    style: TextStyle(
                      color: data['bookingStatus'] == 0
                          ? Colors.orange
                          : data['bookingStatus'] == 1
                              ? Colors.green
                              : data['bookingStatus'] == 2
                                  ? Colors.red
                                  : Colors.grey.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: getScreenWidth(context) * 0.2,
                  height: getScreenHeight(context) * 0.15,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(tourData['tourCover'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded( // Use Expanded to allow the column to take remaining space
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align contents vertically
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(right: 10),
                        child: Text(
                          tourData['tourName'] ?? "N/A",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Booking Date: ${data['travelDate'] ?? "N/A"}",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                      ),
                      SizedBox(height: 5),
                      Row(
                        children: [
                          Text(
                            "Payment: ",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            "${data['fullyPaid'] == 0 ? 'Half Payment' : 'Completed'}",
                            style: TextStyle(
                              color: data['fullyPaid'] == 0 ? Colors.red : const Color.fromARGB(255, 103, 178, 105),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 5),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Unit Price: RM ${(data['totalPrice'] / data['numberOfPeople']).toStringAsFixed(2)}",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(right: 10),
                            child: Text(
                              'Qty: ${(data['numberOfPeople'] ?? "N/A").toString()}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
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
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total Price: RM ${NumberFormat('#,##0.00').format(data['totalPrice'] ?? 0)}", 
                  style: TextStyle(
                    color: Colors.black, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ]
            )
          )
        ],
      ),
    );
  }

  Widget carComponent({required Map<String, dynamic> data, required Map<String, dynamic> carData}) {

    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border:Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ID: ${data['bookingID'] ?? "N/A"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: data['bookingStatus'] == 0
                        ? Colors.orange.shade100
                        : data['bookingStatus'] == 1
                            ? Colors.green.shade100
                            : data['bookingStatus'] == 2
                                ? Colors.red.shade100
                                : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    data['bookingStatus'] == 0
                        ? "Upcoming"
                        : data['bookingStatus'] == 1
                            ? "Completed"
                            : data['bookingStatus'] == 2
                                ? "Canceled"
                                : "Unknown",
                    style: TextStyle(
                      color: data['bookingStatus'] == 0
                          ? Colors.orange
                          : data['bookingStatus'] == 1
                              ? Colors.green
                              : data['bookingStatus'] == 2
                                  ? Colors.red
                                  : Colors.grey.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.0),
                  width: getScreenWidth(context) * 0.25,
                  height: getScreenHeight(context) * 0.15,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(carData['carImage'] ?? ''),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        carData['carModel'] ?? "N/A",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: 240,
                        child: Text(
                          "Booking Date: ${data['bookingDate'].map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ')}",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.visible,
                          maxLines: null,
                        ),
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total Price: RM ${NumberFormat('#,##0.00').format(data['totalPrice'] ?? 0)}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget localBuddyComponent({required Map<String, dynamic> data, required Map<String, dynamic> localBuddyData}) {

    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border:Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "ID: ${data['bookingID'] ?? "N/A"}",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(5.0),
                  decoration: BoxDecoration(
                    color: data['bookingStatus'] == 0
                        ? Colors.orange.shade100
                        : data['bookingStatus'] == 1
                            ? Colors.green.shade100
                            : data['bookingStatus'] == 2
                                ? Colors.red.shade100
                                : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    data['bookingStatus'] == 0
                        ? "Upcoming"
                        : data['bookingStatus'] == 1
                            ? "Completed"
                            : data['bookingStatus'] == 2
                                ? "Canceled"
                                : "Unknown",
                    style: TextStyle(
                      color: data['bookingStatus'] == 0
                          ? Colors.orange
                          : data['bookingStatus'] == 1
                              ? Colors.green
                              : data['bookingStatus'] == 2
                                  ? Colors.red
                                  : Colors.grey.shade900,
                      fontSize: 12,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(10.0),
                  width: getScreenWidth(context) * 0.22,
                  height: getScreenHeight(context) * 0.13,
                  margin: EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(localBuddyData['profileImage'] ?? ''),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 5),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localBuddyData['localBuddyName'] ?? "N/A",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Booking Date: ${data['bookingDate'].map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ')}", // Use the formattedDateRange here
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 5),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            alignment: Alignment.centerRight,
            padding: EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Total Price: RM ${NumberFormat('#,##0.00').format(data['totalPrice'] ?? 0)}",
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
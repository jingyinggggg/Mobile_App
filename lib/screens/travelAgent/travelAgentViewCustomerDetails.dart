import 'dart:io';
import 'dart:typed_data';

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class TravelAgentViewCustomerDetailsScreen extends StatefulWidget {
  final String userId;
  final String customerId;
  final String? tourID;
  final String? carRentalID;
  final String? tourBookingID;
  final String? carRentalBookingID;

  const TravelAgentViewCustomerDetailsScreen({
    super.key, 
    required this.userId,
    required this.customerId,
    this.tourID,
    this.carRentalID,
    this.tourBookingID,
    this.carRentalBookingID,
  });

  @override
  State<TravelAgentViewCustomerDetailsScreen> createState() => _TravelAgentViewCustomerDetailsScreenState();
}

class _TravelAgentViewCustomerDetailsScreenState extends State<TravelAgentViewCustomerDetailsScreen> {

  bool isFetchingCustomerDetails = false;
  bool isFetchingTourBooking = false;
  bool isFetchingCarBooking = false;
  bool isFetchingTour = false;
  bool isFetchingCar = false;
  bool isOpenFile = false;
  bool isOpenInvoice = false;
  bool isSubmittingRefundRequest = false;
  bool isRejectingRefundRequest = false;
  Map<String, dynamic>? custData;
  Map<String, dynamic>? tourData;
  Map<String, dynamic>? carData;
  Map<String, dynamic>? tourBookingData;
  Map<String, dynamic>? carBookingData;

  bool isSelectingImage = false;
  Uint8List? _rejectProof;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    if(widget.tourBookingID != null){
      _fetchTourBookingDetails();
      _fetchTourDetails();
    } else if(widget.carRentalBookingID != null){
      _fetchCarBookingDetails();
      _fetchCarDetails();
    }
  }

  Future<void>_fetchCustomerDetails() async {
    setState(() {
      isFetchingCustomerDetails = true;
    });
    try{
      DocumentReference custRef = FirebaseFirestore.instance.collection('users').doc(widget.customerId);
      DocumentSnapshot custSnapshot = await custRef.get();

      if(custSnapshot.exists){
        Map<String, dynamic>? data = custSnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          custData = data;
        });
      }
    } catch(e){
      print('Error fetch customer data: $e');
    } finally{
      setState(() {
        isFetchingCustomerDetails = false;
      });
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

  Future<void>_fetchCarBookingDetails() async {
    setState(() {
      isFetchingCarBooking = true;
    });
    try{
      DocumentReference carRef = FirebaseFirestore.instance.collection('carRentalBooking').doc(widget.carRentalBookingID);
      DocumentSnapshot carSnapshot = await carRef.get();

      if(carSnapshot.exists){
        Map<String, dynamic>? data = carSnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          carBookingData = data;
        });
        print("Car Booking Data: $carBookingData");
      }
    } catch(e){
      print('Error fetch car booking data: $e');
    } finally{
      setState(() {
        isFetchingCarBooking = false;
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

  Future<String> uploadImageToStorage(String childName, Uint8List file) async{
  
    Reference ref = FirebaseStorage.instance.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadURL = await snapshot.ref.getDownloadURL();
    return downloadURL;
  }

  Future<void> requestRefund(String id) async{
    setState(() {
      isSubmittingRefundRequest = true;
    });
    try{
      await FirebaseFirestore.instance.collection('carRentalBooking').doc(id).update({
        'isCheckCarCondition' : 1
      });

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Travel Agent(${widget.userId}) has submitted the refund request for issue deposit refund. Please issue deposit refund to the customer.",
        'isRead': 0,
        'type': "refund",
        'timestamp': DateTime.now(),
        'receiverID': "A1001"
      });

      showCustomDialog(
        context: context, 
        title: 'Submit Successful', 
        content: 'You have submit the refund request successful. Admin will proceed the request by refunding the deposit to user.',
        onPressed: (){
          setState(() {
            carBookingData!['isCheckCarCondition'] = 1;
          });
          print("Check: ${carBookingData!['isCheckCarCondition']}");
          Navigator.pop(context);
        }
      );
    } catch(e){
      showCustomDialog(
        context: context, 
        title: 'Failed', 
        content: 'Something went wrong. Please try again later...',
        onPressed: (){
          Navigator.pop(context);
        }
      );
    } finally{
      setState(() {
        isSubmittingRefundRequest = false;
      });
    }
  }

  Future<void> rejectRefund(String id, String reason, String receiverID) async {
    setState(() {
      isRejectingRefundRequest = true;
    });
    try{

      String fileName = "rejectProof.jpg";
      String uploadedRejectProof = "";

      if(_rejectProof != null){
        uploadedRejectProof = await uploadImageToStorage("booking/$id/$fileName", _rejectProof!);
        
        await FirebaseFirestore.instance.collection('carRentalBooking').doc(id).update({
          'isCheckCarCondition' : 1,
          'isRefundDeposit': 2,
          'rejectDepositRefundReason': reason,
          'rejectProof': uploadedRejectProof
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Travel Agent(${widget.userId}) has rejected your deposit refund request. Please check the reject reason in the booking details page.",
          'isRead': 0,
          'type': "refund",
          'timestamp': DateTime.now(),
          'receiverID': receiverID
        });
      }

      showCustomDialog(
        context: context, 
        title: "Rejected Successful", 
        content: "You have rejected the deposit refund request successful.", 
        onPressed: (){
          setState(() {
            carBookingData!['isCheckCarCondition'] = 1;
            carBookingData!['isRefundDeposit'] = 2;
          });
          Navigator.pop(context);
        }
      );
    } catch(e){
      showCustomDialog(
        context: context, 
        title: "Failed", 
        content: "Something went wrong. Please try again later...", 
        onPressed: (){
          Navigator.pop(context);
        }
      );
    } finally{
      setState(() {
        isRejectingRefundRequest = false;
      });
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
                  MaterialPageRoute(builder: (context) => ChatDetailsScreen(userId: widget.userId, receiverUserId: custData!['id']))
                );
              },
              icon: ImageIcon(
                AssetImage('images/chat.png'),
                color: Colors.white,
                size: 21,
              ),
              tooltip: "Chat with customer",
            )
          ),
        ],
      ),
      body: isFetchingCustomerDetails || isFetchingCarBooking || isFetchingTourBooking
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : custData == null 
            ? Center(child: Text('No customer details available.'))
            : SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Column(
                    children: [
                      Container(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              alignment: Alignment.topCenter,
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.black, width: 1.5),
                                  bottom: BorderSide(color: Colors.black, width: 1.5),
                                ),
                              ),
                              child: Text(
                                'Customer Info',
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
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: _buildImage(custData?['profileImage'], 75, 110),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Name', custData?['name'], 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('Contact', custData?['contact'], 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('Email', custData?['email'], 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('Address', custData?['address'], 55),
                                    ],
                                  ),
                                ),
                              ],
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
                                'Booking Info',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            SizedBox(height: 20),
                            if(tourBookingData != null && tourData != null) ...[
                              tourComponent(data: tourBookingData!, tourData: tourData!),
                              Text(
                                "Remarks: Half Payment (Pay deposit only), Full payment (Pay deposit and total booking fee)",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                                ),
                                textAlign: TextAlign.justify,
                              ),
                              if(tourBookingData!['bookingStatus'] == 2)...[
                                SizedBox(height: 10,),
                                Text(
                                  "Cancel Reason: ${tourBookingData!['cancelReason'] ?? "N/A" }",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
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
                                  'Payment Info',
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
                                    width: 90,
                                    child: Text(
                                      "Deposit",
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
                                  SizedBox(width: 5),
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
                                          backgroundColor: Color(0xFF749CB9),  
                                          foregroundColor: Colors.white,  
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: primaryColor)
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
                                    width: 90,
                                    child: Text(
                                      "Full Payment",
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
                                  SizedBox(width: 5),
                                  if(tourBookingData!['invoice'] != null)
                                    isOpenInvoice
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
                                            isOpenInvoice = true; // Update the loading state
                                          });
                                          String url = tourBookingData!['invoice']; 
                                          String fileName = 'invoice'; 
                                          await downloadAndOpenPdfFromUrl(url, fileName);
                                          setState(() {
                                            isOpenInvoice = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Deposit Invoice",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF749CB9),  
                                          foregroundColor: Colors.white,  
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: primaryColor)
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
                                ]
                              )
                            ],

                            if(carBookingData != null && carData != null) ...[
                              carComponent(data: carBookingData!, carData: carData!),
                              if(carBookingData!['bookingStatus'] == 2)...[
                                SizedBox(height: 10,),
                                Text(
                                  "Cancel Reason: ${carBookingData!['cancelReason'] ?? "N/A" }",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold
                                  ),
                                  textAlign: TextAlign.justify,
                                ),
                              ],
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
                                  'Payment Info',
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 100,
                                    child: Text(
                                      "Invoice",
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
                                    isOpenInvoice
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
                                            isOpenInvoice = true; // Update the loading state
                                          });
                                          String url = carBookingData!['invoice']; 
                                          String fileName = 'invoice'; 
                                          await downloadAndOpenPdfFromUrl(url, fileName);
                                          setState(() {
                                            isOpenInvoice = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Deposit Invoice",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Color(0xFF749CB9),  
                                          foregroundColor: Colors.white,  
                                          shape: RoundedRectangleBorder(
                                            side: BorderSide(color: primaryColor)
                                          ),
                                        ),
                                      )
                                    )
                                  else
                                    Expanded(
                                      child: Text(
                                        "N/A",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600
                                        ),
                                      ),
                                    )
                                    
                                ],
                              ),
                              SizedBox(height: 10),
                              if(carBookingData!['bookingStatus'] == 1)...[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        "Request Refund",
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
                                    if(carBookingData!['isCheckCarCondition'] == 0)
                                      Expanded(
                                        child: Text(
                                          'Click on the "Submit Refund Request" button to refund the deposit to customer after checking the car condition. Admin will proceed your request.',
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.black,
                                            fontWeight: FontWeight.w500
                                          ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )
                                      
                                    else if(carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 1)
                                      Expanded(
                                        child: Text(
                                          "Deposit has been refunded to customer",
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Color.fromARGB(255, 163, 240, 166),
                                            fontWeight: FontWeight.w500
                                          ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )
                                      
                                    else if (carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 0)
                                      Expanded(
                                        child: Text(
                                          "Request is pending proceed by admin",
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w500
                                          ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )

                                    else if (carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 2)
                                      Expanded(
                                        child: Text(
                                          "Deposit refund has been rejected",
                                          style: TextStyle(
                                            fontSize: defaultFontSize,
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500
                                          ),
                                          textAlign: TextAlign.justify,
                                        )
                                      )
                                      
                                  ],
                                ),
                                SizedBox(height: 20),
                                if (carBookingData!['isCheckCarCondition'] == 0)
                                  Container(
                                    height: 50,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  return AlertDialog(
                                                    title: const Text("Confirmation"),
                                                    content: const Text(
                                                      "Please ensure that the car's condition has been thoroughly checked before submitting the request to the admin for refunding the deposit to the user.",
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
                                                          requestRefund(carBookingData!['bookingID']);
                                                        },
                                                        style: TextButton.styleFrom(
                                                          backgroundColor: primaryColor,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                        ),
                                                        child: const Text("Submit"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: isSubmittingRefundRequest
                                                ? const CircularProgressIndicator(color: Colors.white)
                                                : const Text(
                                                    "Car Check Approve",
                                                    style: TextStyle(
                                                      fontSize: defaultLabelFontSize,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: primaryColor,
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8), // Optional space between buttons
                                        Expanded(
                                          child: TextButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (BuildContext context) {
                                                  final TextEditingController rejectReasonController = TextEditingController();
                                                  String? uploadedProof;
                                                  String? validationError; // To store validation error messages
                                                  bool isRejectLoading = false; // To manage the loading state

                                                  return StatefulBuilder(
                                                    builder: (context, setState) {
                                                      return AlertDialog(
                                                        title: const Text("Confirmation"),
                                                        content: SingleChildScrollView(
                                                          child: Column(
                                                            crossAxisAlignment: CrossAxisAlignment.start,
                                                            children: [
                                                              const Text(
                                                                "Are you sure you want to reject the deposit refund for this booking?",
                                                                textAlign: TextAlign.justify,
                                                              ),
                                                              const SizedBox(height: 20),
                                                              const Text(
                                                                "Reason for Rejection:",
                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                              const SizedBox(height: 10),
                                                              TextField(
                                                                controller: rejectReasonController,
                                                                decoration: const InputDecoration(
                                                                  border: OutlineInputBorder(),
                                                                  hintText: "Enter reason here...",
                                                                ),
                                                                maxLines: 3,
                                                              ),
                                                              const SizedBox(height: 20),
                                                              const Text(
                                                                "Upload Proof:",
                                                                style: TextStyle(fontWeight: FontWeight.bold),
                                                              ),
                                                              const SizedBox(height: 10),
                                                              ElevatedButton(
                                                                onPressed: () async {
                                                                  setState(() {
                                                                    isSelectingImage = true;
                                                                  });

                                                                  Uint8List? img = await ImageUtils.selectImage(context);

                                                                  setState((){
                                                                    _rejectProof = img;
                                                                    uploadedProof = "reject_proof.pdf";
                                                                    validationError = "";
                                                                    isSelectingImage = false;
                                                                  });
                                                                },
                                                                child: const Text("Upload Proof"),
                                                                style: TextButton.styleFrom(
                                                                  backgroundColor: Colors.white,
                                                                  foregroundColor: primaryColor,
                                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                                  shape: RoundedRectangleBorder(
                                                                    borderRadius: BorderRadius.circular(8),
                                                                    side: BorderSide(color: primaryColor, width: 1.5),
                                                                  ),
                                                                ),
                                                              ),
                                                              if (uploadedProof != null) ...[
                                                                const SizedBox(height: 10),
                                                                Text(
                                                                  "Uploaded: $uploadedProof",
                                                                  style: const TextStyle(color: Colors.green),
                                                                ),
                                                              ],
                                                              const SizedBox(height: 10),
                                                              if (validationError != null) ...[
                                                                Text(
                                                                  validationError!,
                                                                  style: const TextStyle(color: Colors.red),
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
                                                            style: TextButton.styleFrom(
                                                              backgroundColor: Colors.grey,
                                                              foregroundColor: Colors.white,
                                                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                                                              shape: RoundedRectangleBorder(
                                                                borderRadius: BorderRadius.circular(8),
                                                              ),
                                                            ),
                                                            child: const Text("Cancel"),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              // Perform validation
                                                              if (rejectReasonController.text.isEmpty) {
                                                                setState(() {
                                                                  validationError = "Please enter a rejection reason.";
                                                                });
                                                                return;
                                                              }

                                                              if (uploadedProof == null) {
                                                                setState(() {
                                                                  validationError = "Please upload proof.";
                                                                });
                                                                return;
                                                              }

                                                              setState(() {
                                                                validationError = null;
                                                                isRejectLoading = true;
                                                              });

                                                              // Simulate async operation
                                                              await Future.delayed(const Duration(seconds: 2));

                                                              // Call reject refund function
                                                              rejectRefund(
                                                                carBookingData!['bookingID'],
                                                                rejectReasonController.text,
                                                                custData!['id'],
                                                              );

                                                              setState(() {
                                                                isRejectLoading = false;
                                                              });

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
                                                            child: isRejectLoading
                                                                ? const SizedBox(
                                                                    height: 18,
                                                                    width: 18,
                                                                    child: CircularProgressIndicator(
                                                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                                      strokeWidth: 2,
                                                                    ),
                                                                  )
                                                                : const Text("Confirm"),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              );
                                            },
                                            child: const Text(
                                              "Car Check Reject",
                                              style: TextStyle(
                                                fontSize: defaultLabelFontSize,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            style: TextButton.styleFrom(
                                              backgroundColor: Colors.red, // Use a different color for reject button
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          ),
                                        ),



                                      ],
                                    ),
                                  )

                              ]
                            ]
                          ]
                        )
                      )
                    ],
                  ),
                ),
              )
      
    );    
  }

  Widget _buildImage(String? imageUrl, double width, double height) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey[300],
        child: Center(child: Icon(Icons.error, color: Colors.red)),
      );
    }

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) {
            return Dialog(
              child: PhotoView(
                imageProvider: CachedNetworkImageProvider(imageUrl),
                minScale: PhotoViewComputedScale.contained,
                maxScale: PhotoViewComputedScale.covered * 2,
                backgroundDecoration: BoxDecoration(
                  color: Colors.black,
                ),
              ),
            );
          },
        );
      },
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        placeholder: (context, url) => Center(
          child: CircularProgressIndicator(),
        ),
        errorWidget: (context, url, error) => Icon(Icons.error),
        fit: BoxFit.cover,
      ),
    );
  }


  Widget _buildDetailRow(String label, String? value, double width) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: width,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          width: 10,
          child: Text(
            ':',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? 'N/A',
            style: TextStyle(
              color: Colors.black,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget tourComponent({required Map<String, dynamic> data, required Map<String, dynamic> tourData}) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
        // borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.5)),
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
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.5))
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
                      Text(
                        tourData['tourName'] ?? "N/A",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
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
                      Padding( // Add Padding here
                        padding: EdgeInsets.only(right: 10.0), // Right padding of 10
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Qty: ${(data['numberOfPeople'] ?? "N/A").toString()}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
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

    List<DateTime> bookingDates = (data['bookingDate'] as List<dynamic>)
      .map((date) => (date as Timestamp).toDate())
      .toList();

    return Container(
      margin: EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade400, width: 1.5),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.5)),
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
              border: Border(bottom: BorderSide(color: Colors.grey.shade400, width: 1.5)),
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
                        width: 240, // Set a desired width
                        child: Text(
                          "Booking Date: ${bookingDates.map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ')}",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                          maxLines: 1, // Optional: Limits to a single line
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


}

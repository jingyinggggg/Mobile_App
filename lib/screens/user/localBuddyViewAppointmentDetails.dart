import 'dart:io';

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/screens/user/localBuddyViewAppointment.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_view/photo_view.dart';

class LocalBuddyViewAppointmentDetailsScreen extends StatefulWidget {
  final String userId;
  final String localBuddyId;
  final String custID;
  final String localBuddyBookingID;
  final List<localBuddyCustomerAppointment> appointments;

  const LocalBuddyViewAppointmentDetailsScreen({
    super.key,
    required this.userId,
    required this.localBuddyId,
    required this.custID,
    required this.localBuddyBookingID,
    required this.appointments
  });

  @override
  State<LocalBuddyViewAppointmentDetailsScreen> createState() => _LocalBuddyViewAppointmentDetailsScreenState();
}

class _LocalBuddyViewAppointmentDetailsScreenState extends State<LocalBuddyViewAppointmentDetailsScreen> {

  Map<String, dynamic>? localBuddyBookingData;
  Map<String, dynamic>? localBuddyData;
  Map<String, dynamic>? custData;
  bool isOpenInvoice = false;
  bool isFetchingLocalBuddy = false;
  bool isFetchingCustomerDetails = false;

  @override
  void initState() {
    super.initState();
    _fetchCustomerDetails();
    _fetchLocalBuddyBookingDetails();
    _fetchLocalBuddyDetails();
  }

  Future<void>_fetchCustomerDetails() async {
    setState(() {
      isFetchingCustomerDetails = true;
    });
    try{
      DocumentReference custRef = FirebaseFirestore.instance.collection('users').doc(widget.custID);
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

  Future<void>_fetchLocalBuddyBookingDetails() async {
    setState(() {
      isFetchingLocalBuddy = true;
    });
    try{
      DocumentReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddyBooking').doc(widget.localBuddyBookingID);
      DocumentSnapshot localBuddySnapshot = await localBuddyRef.get();

      if(localBuddySnapshot.exists){
        Map<String, dynamic>? data = localBuddySnapshot.data() as  Map<String, dynamic>?;
        setState(() {
          localBuddyBookingData = data;
        });
      }
    } catch(e){
      print('Error fetch local buddy booking data: $e');
    } finally{
      setState(() {
        isFetchingLocalBuddy = false;
      });
    }
  }

  Future<void>_fetchLocalBuddyDetails() async {
    setState(() {
      isFetchingLocalBuddy = true;
    });
    try{
      DocumentReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyId);
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
              MaterialPageRoute(builder: (context) => LocalBuddyViewAppointmentScreen(userId: widget.userId, localBuddyId: widget.localBuddyId))
            );
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
      body: isFetchingCustomerDetails || isFetchingLocalBuddy
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
                        if(localBuddyBookingData != null && localBuddyData != null) ...[
                          localBuddyComponent(data: localBuddyBookingData!, localBuddyData: localBuddyData!),
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
                                width: 50,
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
                              SizedBox(width: 5),
                              if(localBuddyBookingData!['invoice'] != null)
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
                                      String url = localBuddyBookingData!['invoice']; 
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
                        ]
                      ],
                    ),
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

  Widget localBuddyComponent({required Map<String, dynamic> data, required Map<String, dynamic> localBuddyData}) {
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
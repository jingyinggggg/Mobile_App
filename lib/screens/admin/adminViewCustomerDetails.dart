import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/customerModel.dart';
import 'package:assignment_tripmate/invoiceModel.dart';
import 'package:assignment_tripmate/pdf_invoice_api.dart';
import 'package:assignment_tripmate/supplierModel.dart';
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
import 'package:http/http.dart' as http;

class AdminViewCustomerDetailsScreen extends StatefulWidget {
  final String userId;
  final String customerId;
  final String? tourID;
  final String? carRentalID;
  final String? localBuddyID;
  final String? tourBookingID;
  final String? carRentalBookingID;
  final String? localBuddyBookingID;

  const AdminViewCustomerDetailsScreen({
    super.key, 
    required this.userId,
    required this.customerId,
    this.tourID,
    this.carRentalID,
    this.localBuddyID,
    this.tourBookingID,
    this.carRentalBookingID,
    this.localBuddyBookingID
  });

  @override
  State<AdminViewCustomerDetailsScreen> createState() => _AdminViewCustomerDetailsScreenState();
}

class _AdminViewCustomerDetailsScreenState extends State<AdminViewCustomerDetailsScreen> {
  bool isFetchingCustomerDetails = false;
  bool isFetchingTourBooking = false;
  bool isFetchingCarBooking = false;
  bool isFetchingLocalBuddyBooking = false;
  bool isFetchingTour = false;
  bool isFetchingCar = false;
  bool isFetchingLocalBuddy = false;
  bool isOpenFile = false;
  bool isOpenInvoice = false;
  bool isOpenRefundInvoice = false;
  bool isOpenDepositRefundInvoice = false;
  bool isOpenProofFile = false;
  bool isRefunding = false;
  bool isGenerating = false;
  Map<String, dynamic>? custData;
  Map<String, dynamic>? companyData;
  Map<String, dynamic>? tourData;
  Map<String, dynamic>? carData;
  Map<String, dynamic>? localBuddyData;
  Map<String, dynamic>? tourBookingData;
  Map<String, dynamic>? carBookingData;
  Map<String, dynamic>? localBuddyBookingData;
  bool isSelectingImage = false;
  Uint8List? _transferProof;
  String? uploadedProof;
  final TextEditingController _proofNameController = TextEditingController();

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
    } else if(widget.localBuddyBookingID != null){
      _fetchLocalBuddyBookingDetails();
      _fetchLocalBuddyDetails();
    }
  }

  String decryptText(String encryptedText) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final parts = encryptedText.split(':'); // Split to get IV and encrypted data

    if (parts.length != 2) {
      throw ArgumentError("Invalid encrypted format"); // Check for expected format
    }

    final iv = encrypt.IV.fromBase64(parts[0]); // Retrieve the original IV
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encryptedData, iv: iv); // Decrypt using original IV
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
      }
    } catch(e){
      print('Error fetch car booking data: $e');
    } finally{
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

  Future<void> _fetchTourDetails() async {
    setState(() {
      isFetchingTour = true; // Set loading state
    });

    try {
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot tourSnapshot = await tourRef.get();

      if (tourSnapshot.exists) {
        Map<String, dynamic>? data = tourSnapshot.data() as Map<String, dynamic>?;

        print('Tour data retrieved: $data'); // Debugging statement for tour data

        if (data != null) {
          DocumentReference companyRef = FirebaseFirestore.instance.collection('travelAgent').doc(data['agentID']);
          DocumentSnapshot companySnapshot = await companyRef.get();

          if (companySnapshot.exists) {
            Map<String, dynamic>? companyData = companySnapshot.data() as Map<String, dynamic>?;

            if (companyData != null) {

              // Store the company data
              setState(() {
                this.companyData = companyData; // Ensure you're using 'this' for clarity
              });
            } 
          } 
        } 

        setState(() {
          this.tourData = data; // Store the tour data
        });
      } else {
        print('Tour document does not exist'); // Debugging for tour document existence
      }
    } catch (e) {
    } finally {
      setState(() {
        isFetchingTour = false; // Reset loading state
      });
    }
  }


  Future<void> _fetchCarDetails() async {
    setState(() {
      isFetchingCar = true; // Set loading state
    });

    try {
      DocumentReference carRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carRentalID);
      DocumentSnapshot carSnapshot = await carRef.get();

      if (carSnapshot.exists) {
        Map<String, dynamic>? data = carSnapshot.data() as Map<String, dynamic>?;

        print('Car data retrieved: $data'); // Debugging statement for car data

        // Check if data is null
        if (data == null) {
          print('Car data is null');
          return; // Exit early if data is null
        }

        // Retrieve the agencyID safely
        String? agencyID = data['agencyID'];
        if (agencyID == null) {
          print('Agency ID is null'); // Log if agencyID is missing
          return; // Exit early if agencyID is null
        }

        DocumentReference companyRef = FirebaseFirestore.instance.collection('travelAgent').doc(agencyID);
        DocumentSnapshot companySnapshot = await companyRef.get();

        if (companySnapshot.exists) {
          Map<String, dynamic>? companyData = companySnapshot.data() as Map<String, dynamic>?;

          print('Company data retrieved: $companyData'); // Debugging statement for company data

          // Check if companyData is null
          if (companyData != null) {
            setState(() {
              this.companyData = companyData; // Ensure you're using 'this' for clarity
            });
          } else {
            print('Company data is null');
          }
        } else {
          print('Company document does not exist');
        }

        setState(() {
          carData = data; // Store the car data
        });
      } else {
        print('Car document does not exist'); // Debugging for car document existence
      }
    } catch (e) {
      print('Error fetching car data: $e'); // Log any errors
    } finally {
      setState(() {
        isFetchingCar = false; // Reset loading state
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

  Future<void> downloadAndOpenImageFromUrl(String url) async {
    // Fetch the image from the URL
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      // If the server returns an OK response, display the image
      final bytes = response.bodyBytes;

      // Display the image in a new screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PhotoView(
            imageProvider: MemoryImage(bytes),
            heroAttributes: const PhotoViewHeroAttributes(tag: "image"),
          ),
        ),
      );
    } else {
      // Handle the error case
      throw Exception('Failed to load image');
    }
  }

  void showPaymentOption(BuildContext context, String amount, Function onSubmit, String bankName, String accountName, String accountNumber) {
    bool isProofUploaded = _proofNameController.text.isNotEmpty;

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
                    Text("Refund $amount to the following account:", textAlign: TextAlign.justify),
                    const SizedBox(height: 8),
                    Text(
                      // "Bank: ",
                      "Bank: ${decryptText(bankName)}\nAccount Name: ${decryptText(accountName)}\nAccount Number: ${decryptText(accountNumber)}",
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
                  onPressed: (isProofUploaded) ? () {
                    Navigator.of(context).pop(); // Close the dialog
                    onSubmit(); // Call the provided function
                  } : null,
                  child: const Text("Submit"),
                  style: TextButton.styleFrom(
                    backgroundColor: (isProofUploaded) 
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

  Future<void> refundToCustomer(String type, String bookingID, int price, String collection, {bool isDepositRefund = false}) async{
    setState(() {
      isRefunding = true;
    });
    try{
      if(type == "Car Rental"){
        if(_transferProof != null){
          uploadedProof = await uploadImageToStorage("invoice/Car Rental/${custData!['id']}/$bookingID/refundTransferProof", _transferProof!);

        }

        await FirebaseFirestore.instance.collection('carRentalBooking').doc(bookingID).update({
          'isRefund': isDepositRefund ? 0 : 1,
          'isRefundDeposit': isDepositRefund ? 1 : 0,
          'refundTransferProof': uploadedProof!
        });
        setState(() {
          carBookingData!['isRefundDeposit'] = isDepositRefund;
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Admin has issued your deposit refund for booking id ($bookingID).",
          'isRead': 0,
          'type': "invoice",
          'timestamp': DateTime.now(),
          'receiverID': custData!['id']
        });
      } else{
        if(_transferProof != null){
          uploadedProof = await uploadImageToStorage("invoice/Local Buddy/${custData!['id']}/$bookingID/refundTransferProof", _transferProof!);

        }
        await FirebaseFirestore.instance.collection('localBuddyBooking').doc(bookingID).update({
          'isRefund': 1,
          'refundTransferProof': uploadedProof
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Admin has issued your refund for booking id ($bookingID).",
          'isRead': 0,
          'type': "invoice",
          'timestamp': DateTime.now(),
          'receiverID': custData!['id']
        });
      }

      // Show success dialog
      showCustomDialog(
        context: context, 
        title: "Refund Successful", 
        content: "The amount is refunded to customer successfully.", 
        onPressed: () async {
          // Close the payment successful dialog
          Navigator.of(context).pop();

          // Use Future.microtask to show the loading dialog after the previous dialog is closed
          Future.microtask(() {
            showLoadingDialog(context, "Generating Invoice...");
          });

          final date = DateTime.now();

          final invoice = Invoice(
            supplier: Supplier(
              name: "Admin",
              address: "admin@tripmate.com",
            ),
            customer: Customer(
              name: custData!['name'],
              address: custData!['address'],
            ),
            info: InvoiceInfo(
              date: date,
              description: "Below is the refund invoice summary:",
              number: '${DateTime.now().year}-Ref${Random().nextInt(9000) + 1000}',
            ),
            // Wrap the single InvoiceItem in a list
            items: [
              InvoiceItem(
                description: isDepositRefund ? "Deposit refund (Booking ID: ${bookingID})" : "Refund (Booking ID: ${bookingID})",
                quantity: 1,
                unitPrice: price,
                total: price.toDouble(),
              ),
            ],
          );

          // Perform some async operation
          await generateInvoice(bookingID, invoice, type, collection, "refund_invoice", false, true, isDepositRefund ? true : false);

          // After the operation is done, hide the loading dialog
          Navigator.of(context).pop(); // This will close the loading dialog

          setState(() {
            isRefunding = false;
          });

          // Navigate back to customer details
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminViewCustomerDetailsScreen(
                userId: widget.userId,
                customerId: widget.customerId,
                tourBookingID: widget.tourBookingID != null ? widget.tourBookingID : null,
                tourID: widget.tourID != null ? widget.tourID : null,
                carRentalBookingID: widget.carRentalBookingID != null ? widget.carRentalBookingID : null,
                carRentalID: widget.carRentalID != null ? widget.carRentalID : null,
                localBuddyBookingID: widget.localBuddyBookingID != null ? widget.localBuddyBookingID : null,
                localBuddyID: widget.localBuddyID != null ? widget.localBuddyID : null,
              ),
            ),
          );

          // // Navigate to the homepage after PDF viewer
          // Future.delayed(Duration(milliseconds: 500), () {
          //   Navigator.pushReplacement(
          //     context,
          //     MaterialPageRoute(
          //       builder: (context) => AdminViewCustomerDetailsScreen(
          //         userId: widget.userId,
          //         customerId: widget.customerId,
          //         tourBookingID: widget.tourBookingID,
          //         tourID: widget.tourID,
          //       ),
          //     ),
          //   );
          // });
        },
        textButton: "View Invoice",
      );
    } catch(e){
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
        isRefunding = false;
      });
    }
  }

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
        custData!['id'], 
        id, 
        servicesType, 
        collectionName, 
        pdfFileName, 
        isDeposit,
        isRefund,
        isDepositRefund,
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

//   void generateTourDepositInvoice() {
//   // Show a confirmation dialog first
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text('Confirm Invoice Generation'),
//         content: Text('Are you sure you want to generate the deposit invoice?'),
//         actions: <Widget>[
//           TextButton(
//             child: Text('Cancel'),
//             onPressed: () {
//               Navigator.of(context).pop(); // Close the dialog
//             },
//           ),
//           TextButton(
//             child: Text('Confirm'),
//             onPressed: () async {
//               // Close the confirmation dialog
//               Navigator.of(context).pop(); // Close confirmation dialog
              
//               // Now proceed with generating the invoice
//               await _generateInvoice(); // Call the method to generate the invoice
//             },
//           ),
//         ],
//       );
//     },
//   );
// }

  Future<void> _generateDepositTourInvoice() async {
    setState(() {
      isGenerating = true; // Set generating state
    });

    try {
      showLoadingDialog(context, "Generating Invoice...");
      final date = DateTime.now();
      final invoice = Invoice(
        supplier: Supplier(
          name: "Admin",
          address: "admin@tripmate.com",
        ),
        customer: Customer(
          name: custData!['name'],
          address: custData!['address'],
        ),
        info: InvoiceInfo(
          date: date,
          description: "You have paid the deposit. Below is the invoice summary:",
          number: '${DateTime.now().year}-${widget.tourBookingID}',
        ),
        items: [
          InvoiceItem(
            description: "Deposit for ${tourData!['tourName']} - (${tourBookingData!['travelDate']})",
            quantity: 1,
            unitPrice: 1000,
            total: 1000,
          ),
        ],
      );

      // Generate the invoice
      await generateInvoice(widget.tourBookingID!, invoice, "Tour Package", "tourBooking", "deposit", true, false, false);

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Admin has generated your invoice for booking id (${widget.tourBookingID}).",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': custData!['id']
      });

      // After the operation is done, hide the loading dialog
      Navigator.of(context).pop(); // Close loading dialog

      // Optionally, refresh the page/state after opening the PDF
      setState(() {
        isGenerating = false; // Reset generating state
      });

      // Navigate back to customer details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminViewCustomerDetailsScreen(
            userId: widget.userId,
            customerId: widget.customerId,
            tourBookingID: widget.tourBookingID,
            tourID: widget.tourID,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        isGenerating = false; // Reset generating state in case of error
      });
      
      // Show failure dialog
      showCustomDialog(
        context: context,
        title: "Failed",
        content: "Something went wrong! Please try again...",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  Future<void> _generateFullPaymentTourInvoice() async {
    setState(() {
      isGenerating = true; // Set generating state
    });

    try {
      showLoadingDialog(context, "Generating Invoice...");
      final date = DateTime.now();
      final invoice = Invoice(
        supplier: Supplier(
          name: "Admin",
          address: "admin@tripmate.com",
        ),
        customer: Customer(
          name: custData!['name'],
          address: custData!['address'],
        ),
        info: InvoiceInfo(
          date: date,
          description: "You have paid the balance tour fee. Below is the invoice summary:",
          number: '${DateTime.now().year}-${widget.tourBookingID}B',
        ),
        items: [
          InvoiceItem(
            description: "Balance Tour Fee (Booking ID: ${widget.tourBookingID})",
            quantity: 1,
            unitPrice: (tourBookingData!['totalPrice'] - 1000).toInt(),
            total: (tourBookingData!['totalPrice'] - 1000),
          ),
        ],
      );

      // Generate the invoice
      await generateInvoice(widget.tourBookingID!, invoice, "Tour Package", "tourBooking", "balance_payment", false, false, false);

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Admin has generated your invoice for booking id (${widget.tourBookingID}).",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': custData!['id']
      });

      // After the operation is done, hide the loading dialog
      Navigator.of(context).pop(); // Close loading dialog

      // Optionally, refresh the page/state after opening the PDF
      setState(() {
        isGenerating = false; // Reset generating state
      });

      // Navigate back to customer details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminViewCustomerDetailsScreen(
            userId: widget.userId,
            customerId: widget.customerId,
            tourBookingID: widget.tourBookingID,
            tourID: widget.tourID,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        isGenerating = false; // Reset generating state in case of error
      });
      
      // Show failure dialog
      showCustomDialog(
        context: context,
        title: "Failed",
        content: "Something went wrong! Please try again...",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  Future<void> _generateCarInvoice() async {
    setState(() {
      isGenerating = true; // Set generating state
    });

    try {
      List<DateTime> bookingDates = (carBookingData!['bookingDate'] as List<dynamic>)
      .map((date) => (date as Timestamp).toDate())
      .toList();

      showLoadingDialog(context, "Generating Invoice...");
      final date = DateTime.now();
      final invoice = Invoice(
        supplier: Supplier(
          name: "Admin",
          address: "admin@tripmate.com",
        ),
        customer: Customer(
          name: custData!['name'],
          address: custData!['address'],
        ),
        info: InvoiceInfo(
          date: date,
          description: "You have paid the bill. Below is the invoice summary:",
          number: '${DateTime.now().year}-${widget.carRentalBookingID}',
        ),
        items: [
          InvoiceItem(
            description: "Deposit (Refundable)",
            quantity: 1,
            unitPrice: 300,
            total: 300,
          ),
          InvoiceItem(
            description: "${carData!['carModel']} - (${bookingDates.map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ')}))",
            // description: "${_carRental!.carModel} (${dateFormat.format(selectedBookingDates)})",
            quantity: carBookingData!['totalDays'],
            unitPrice: ((carBookingData!['totalPrice'] - 300) / carBookingData!['bookingDate'].length).toInt(),
            total: carBookingData!['totalPrice'] - 300,
          ),
        ],
      );

      // Generate the invoice
      await generateInvoice(widget.carRentalBookingID!, invoice, "Car Rental", "carRentalBooking", "invoice", false, false, false);

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Admin has generated your invoice for booking id (${widget.carRentalBookingID}).",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': custData!['id']
      });

      // After the operation is done, hide the loading dialog
      Navigator.of(context).pop(); // Close loading dialog

      // // Open the generated PDF invoice
      // String pdfUrl = "link_to_generated_pdf"; // Update with your PDF URL logic
      // String fileName = "Deposit_Invoice_${widget.tourBookingID}.pdf"; // Set the filename
      // await downloadAndOpenPdfFromUrl(pdfUrl, fileName); // Function to download and open PDF

      // Optionally, refresh the page/state after opening the PDF
      setState(() {
        isGenerating = false; // Reset generating state
      });

      // Navigate back to customer details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminViewCustomerDetailsScreen(
            userId: widget.userId,
            customerId: widget.customerId,
            carRentalBookingID: widget.carRentalBookingID,
            carRentalID: widget.carRentalID,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        isGenerating = false; // Reset generating state in case of error
      });
      
      // Show failure dialog
      showCustomDialog(
        context: context,
        title: "Failed",
        content: "Something went wrong! Please try again...",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  Future<void> _generateLocalBuddyInvoice() async {
    setState(() {
      isGenerating = true; // Set generating state
    });

    try {
      List<DateTime> bookingDates = (localBuddyBookingData!['bookingDate'] as List<dynamic>)
      .map((date) => (date as Timestamp).toDate())
      .toList();

      showLoadingDialog(context, "Generating Invoice...");
      final date = DateTime.now();
      final invoice = Invoice(
        supplier: Supplier(
          name: "Admin",
          address: "admin@tripmate.com",
        ),
        customer: Customer(
          name: custData!['name'],
          address: custData!['address'],
        ),
        info: InvoiceInfo(
          date: date,
          description: "You have paid the bill. Below is the invoice summary:",
          number: '${DateTime.now().year}-${widget.localBuddyBookingID}',
        ),
        items: [
          InvoiceItem(
            description: "Local Buddy: ${localBuddyData!['localBuddyName']} - (${bookingDates.map((date) => DateFormat('dd/MM/yyyy').format(date)).join(', ')})",
            quantity: localBuddyBookingData!['totalDays'],
            unitPrice: ((localBuddyBookingData!['totalPrice']) / localBuddyBookingData!['bookingDate'].length).toInt(),
            total:  localBuddyBookingData!['totalPrice'] ?? 0.0,
          ),
        ],
      );

      // Generate the invoice
      await generateInvoice(widget.localBuddyBookingID!, invoice, "Local Buddy", "localBuddyBooking", "invoice", false, false, false);

      await FirebaseFirestore.instance.collection('notification').doc().set({
        'content': "Admin has generated your invoice for booking id (${widget.localBuddyBookingID}).",
        'isRead': 0,
        'type': "invoice",
        'timestamp': DateTime.now(),
        'receiverID': custData!['id']
      });

      // After the operation is done, hide the loading dialog
      Navigator.of(context).pop(); // Close loading dialog

      // Optionally, refresh the page/state after opening the PDF
      setState(() {
        isGenerating = false; // Reset generating state
      });

      // Navigate back to customer details
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdminViewCustomerDetailsScreen(
            userId: widget.userId,
            customerId: widget.customerId,
            localBuddyBookingID: widget.localBuddyBookingID,
            localBuddyID: widget.localBuddyID,
          ),
        ),
      );

    } catch (e) {
      setState(() {
        isGenerating = false; // Reset generating state in case of error
      });
      
      // Show failure dialog
      showCustomDialog(
        context: context,
        title: "Failed",
        content: "Something went wrong! Please try again...",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }

  void showConfirmationDialog(String type) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Action"),
          content: Text("Are you sure you want to generate the invoice?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Confirm"),
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
              
                if(type == "Tour"){
                  // Now proceed with generating the invoice
                 _generateDepositTourInvoice(); // Call the original function
                } else if (type == 'Car'){
                  _generateCarInvoice();
                } else if (type == 'Full Tour'){
                  _generateFullPaymentTourInvoice();
                } else {
                  _generateLocalBuddyInvoice();
                }
                
              },
            ),
          ],
        );
      },
    );
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
      ),
      body: isFetchingCustomerDetails || isFetchingCarBooking || isFetchingTourBooking || isFetchingLocalBuddyBooking
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
                                      "Transfer Proof",
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
                                  if(tourBookingData!['transferProof'] != null)
                                    isOpenProofFile
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
                                            isOpenProofFile = true; // Update the loading state
                                          });
                                          String url = tourBookingData!['transferProof'];
                                          await downloadAndOpenImageFromUrl(url);
                                          setState(() {
                                            isOpenProofFile = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Transfer Proof Receipt",
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
                                ]
                              )
                            ],

                            if(tourBookingData != null && tourBookingData!['transferProof'] != null && tourBookingData!['depositInvoice'] == null && tourBookingData!['bookingStatus'] == 0)...[
                              SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 50,
                                child: TextButton(
                                  child: Text(
                                    "Generate Deposit Invoice",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: isGenerating ? null : () => showConfirmationDialog("Tour"),// Disable if generating
                                  style: TextButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                              )
                            ],

                            if(tourBookingData != null && tourBookingData!['balanceTransferProof'] != null && tourBookingData!['invoice'] == null)...[
                              SizedBox(height: 20),
                              Container(
                                width: double.infinity,
                                height: 50,
                                child: TextButton(
                                  child: Text(
                                    "Generate Full Payment Invoice",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: isGenerating ? null : () => showConfirmationDialog("Full Tour"),// Disable if generating
                                  style: TextButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
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
                                children: [
                                  Container(
                                    width: 100,
                                    child: Text(
                                      "Transfer Proof",
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
                                  if(carBookingData!['transferProof'] != null)
                                    isOpenProofFile
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
                                            isOpenProofFile = true; // Update the loading state
                                          });
                                          String url = carBookingData!['transferProof'];
                                          await downloadAndOpenImageFromUrl(url);
                                          setState(() {
                                            isOpenProofFile = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Transfer Proof Receipt",
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

                              if(carBookingData != null && carBookingData!['transferProof'] != null && carBookingData!['invoice'] == null && carBookingData!['bookingStatus'] == 0)...[
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  child: TextButton(
                                    child: Text(
                                      "Generate Invoice",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: isGenerating ? null : () => showConfirmationDialog("Car"), // Disable if generating
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                )
                              ],
                              SizedBox(height: 20),
                              if (carBookingData!['refundInvoice'] != null)
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        "Refund",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      ":",
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    if (carBookingData!['refundInvoice'] != null)
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
                                                  String fileName = 'invoice';
                                                  await downloadAndOpenPdfFromUrl(url, fileName);
                                                  setState(() {
                                                    isOpenRefundInvoice = false; // Update the state when done
                                                  });
                                                },
                                                child: Text(
                                                  "View Refund Invoice",
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: primaryColor,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(color: primaryColor, width: 2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            )
                                    else
                                      Text(
                                        "N/A",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              if (carBookingData!['depositRefundInvoice'] != null || carBookingData!['isRefundDeposit'] == 1)
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        "Deposit Refund",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      ":",
                                      style: TextStyle(
                                        fontSize: defaultFontSize,
                                        color: Colors.black,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(width: 5),
                                    if (carBookingData!['depositRefundInvoice'] != null)
                                      isOpenDepositRefundInvoice
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
                                                    isOpenDepositRefundInvoice = true; // Update the loading state
                                                  });
                                                  String url = carBookingData!['depositRefundInvoice'];
                                                  String fileName = 'deposit_refund_invoice';
                                                  await downloadAndOpenPdfFromUrl(url, fileName);
                                                  setState(() {
                                                    isOpenDepositRefundInvoice = false; // Update the state when done
                                                  });
                                                },
                                                child: Text(
                                                  "View Deposit Refund Invoice",
                                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.white,
                                                  foregroundColor: primaryColor,
                                                  shape: RoundedRectangleBorder(
                                                    side: BorderSide(color: primaryColor, width: 2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                ),
                                              ),
                                            )
                                    else
                                      Text(
                                        "N/A",
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                  ],
                                ),
                              if (carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 0)
                                Container(
                                  constraints: BoxConstraints(maxHeight: 60), // or any appropriate height
                                  child: Text(
                                    '*** Remarks: Travel agent has checked the car condition and submitted a request for deposit refund to customer. You can click on the "Issue Deposit Refund" button to refund the deposit to the customer. ***',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                )
                              else if (carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 2)
                                Container(
                                  constraints: BoxConstraints(maxHeight: 60), // or any appropriate height
                                  child: Text(
                                    '*** Remarks: Travel agent has rejected the deposit refund because the car did not pass the condition check.***',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                )
                              else
                                Container(),

                              SizedBox(height: 10),
                              carBookingData!['bookingStatus'] == 2 && carBookingData!['isRefund'] == 0
                              ? Container(
                                width: double.infinity,
                                height: 50,
                                  child: TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Confirmation"),
                                            content: Text(
                                              "Amount of RM${NumberFormat('#,##0.00').format((carBookingData!['totalPrice']) ?? 0)} will be refunded to customer. Are you sure you want issue the refund?",
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
                                                  showPaymentOption(
                                                    context, 
                                                    "RM ${(carBookingData!['totalPrice']).toInt()}", 
                                                    (){
                                                      refundToCustomer('Car Rental', carBookingData!['bookingID'], (carBookingData!['totalPrice']).toInt(), 'carRentalBooking');
                                                    }, 
                                                    carBookingData!['bankName'], 
                                                    carBookingData!['accountName'], 
                                                    carBookingData!['accountNumber']
                                                  );
                                                  // refundToCustomer('Car Rental', carBookingData!['bookingID'], (carBookingData!['totalPrice'] - 100).toInt(), 'carRentalBooking');
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor, // Set the background color
                                                  foregroundColor: Colors.white, // Set the text color
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                  ),
                                                ),
                                                child: const Text("Refund"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }, 
                                    child: isRefunding
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          "Issue Refund",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10), // Set the button radius to 0
                                      ),
                                    ),
                                  )
                                )
                              : carBookingData!['isCheckCarCondition'] == 1 && carBookingData!['isRefundDeposit'] == 0
                                ? Container(
                                    width: double.infinity,
                                    height: 50,
                                      child: TextButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text("Confirmation"),
                                                content: Text(
                                                  'This booking is completed and the car has been check by travel agent. So, the deposit with amount of RM300.00 can be refunded to customer. Click on the "Confirm" button to proceed the refund.',
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
                                                      showPaymentOption(
                                                        context, 
                                                        "RM 300", 
                                                        (){
                                                          refundToCustomer('Car Rental', carBookingData!['bookingID'], 300, 'carRentalBooking', isDepositRefund: true);
                                                        }, 
                                                        carBookingData!['bankName'], 
                                                        carBookingData!['accountName'], 
                                                        carBookingData!['accountNumber']
                                                      );
                                                    },
                                                    style: TextButton.styleFrom(
                                                      backgroundColor: primaryColor, // Set the background color
                                                      foregroundColor: Colors.white, // Set the text color
                                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                      ),
                                                    ),
                                                    child: const Text("Refund"),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        }, 
                                        child: isRefunding
                                          ? CircularProgressIndicator(color: Colors.white)
                                          : Text(
                                              "Issue Deposit Refund",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                        style: TextButton.styleFrom(
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10), // Set the button radius to 0
                                          ),
                                        ),
                                      )
                                    )
                                : Container()
                              
                            ],

                            if(localBuddyBookingData != null && localBuddyData != null) ...[
                              localBuddyComponent(data: localBuddyBookingData!, localBuddyData: localBuddyData!),
                              if(localBuddyBookingData!['bookingStatus'] == 2)...[
                                SizedBox(height: 10,),
                                Text(
                                  "Cancel Reason: ${localBuddyBookingData!['cancelReason'] ?? "N/A" }",
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
                                    width: 100,
                                    child: Text(
                                      "Transfer Proof",
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
                                  if(localBuddyBookingData!['transferProof'] != null)
                                    isOpenProofFile
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
                                            isOpenProofFile = true; // Update the loading state
                                          });
                                          String url = localBuddyBookingData!['transferProof'];
                                          await downloadAndOpenImageFromUrl(url);
                                          setState(() {
                                            isOpenProofFile = false; // Update the state when done
                                          });
                                        }, 
                                        child:Text(
                                          "View Transfer Proof Receipt",
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
                              if(localBuddyBookingData != null && localBuddyBookingData!['transferProof'] != null && localBuddyBookingData!['invoice'] == null && localBuddyBookingData!['bookingStatus'] == 0)...[
                                SizedBox(height: 20),
                                Container(
                                  width: double.infinity,
                                  height: 50,
                                  child: TextButton(
                                    child: Text(
                                      "Generate Invoice",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: isGenerating ? null : () => showConfirmationDialog("Local Buddy"), // Disable if generating
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  )
                                )
                              ],
                              if(localBuddyBookingData!['refundInvoice'] != null)
                                Row(
                                  children: [
                                    Container(
                                      width: 100,
                                      child: Text(
                                        "Refund",
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
                                            String fileName = 'invoice'; 
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
                                ),
                              SizedBox(height: 20),
                              localBuddyBookingData!['bookingStatus'] == 2 && localBuddyBookingData!['isRefund'] == 0
                              ? Container(
                                width: double.infinity,
                                height: 50,
                                  child: TextButton(
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text("Confirmation"),
                                            content: Text(
                                              "Amount of RM${NumberFormat('#,##0.00').format((localBuddyBookingData!['totalPrice']) ?? 0)} will be refunded to customer. Are you sure you want issue the refund?",
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
                                                  showPaymentOption(
                                                    context, 
                                                    "RM ${(localBuddyBookingData!['totalPrice']).toInt()}", 
                                                    (){
                                                      refundToCustomer('Local Buddy', localBuddyBookingData!['bookingID'], (localBuddyBookingData!['totalPrice']).toInt(), 'localBuddyBooking');
                                                    }, 
                                                    localBuddyBookingData!['bankName'], 
                                                    localBuddyBookingData!['accountName'], 
                                                    localBuddyBookingData!['accountNumber']
                                                  );
                                                  // refundToCustomer('Local Buddy', localBuddyBookingData!['bookingID'], (localBuddyBookingData!['totalPrice']).toInt(), 'localBuddyBooking');
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: primaryColor, // Set the background color
                                                  foregroundColor: Colors.white, // Set the text color
                                                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20), // Optional padding
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(8), // Optional: rounded corners
                                                  ),
                                                ),
                                                child: const Text("Refund"),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    }, 
                                    child: isRefunding
                                      ? CircularProgressIndicator(color: Colors.white)
                                      : Text(
                                          "Issue Refund",
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    style: TextButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10), // Set the button radius to 0
                                      ),
                                    ),
                                  )
                                )
                              : Container()
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

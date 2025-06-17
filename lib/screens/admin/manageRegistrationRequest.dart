import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/registrationRequest.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';

class AdminManageRegistrationRequestScreen extends StatefulWidget {
  final String userId;
  final String TAId;

  const AdminManageRegistrationRequestScreen({super.key, required this.userId, required this.TAId});

  @override
  State<AdminManageRegistrationRequestScreen> createState() => _AdminManageRegistrationRequestScreenState();
}

class _AdminManageRegistrationRequestScreenState extends State<AdminManageRegistrationRequestScreen>{
  Map<String, dynamic>? travelAgentData;
  bool isLoading = false;
  bool isApproveLoading = false;
  bool isRejectLoading = false;
  TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTAData();
  }

  Future<void> _fetchTAData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference TARef = FirebaseFirestore.instance.collection('travelAgent').doc(widget.TAId);
      DocumentSnapshot docSnapshot = await TARef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          travelAgentData = data ?? {};
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No travel agent details found with the given id.')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching tour data: $e')),
      );
    }
  }

  Future<void> _approveRequest() async {
    try {
      setState(() {
        isApproveLoading = true;
      });

      await FirebaseFirestore.instance.collection('travelAgent').doc(widget.TAId).update({
        'accountApproved': 1,
      });

      _showDialog(
        title: 'Success',
        content: 'You have approved the registration request successfully.',
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrationRequestScreen(userId: widget.userId)),
          );
        },
      );

      setState(() {
        isApproveLoading = false; // Stop loading
      });
    } catch (e) {
      _showDialog(
        title: 'Error',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() {
        isApproveLoading = false; // Stop loading
      });
    }
  }

  Future<void> _rejectRequest(String reason) async {
    try {
      setState(() {
        isRejectLoading = true;
      });

      await FirebaseFirestore.instance.collection('travelAgent').doc(widget.TAId).update({
        'accountApproved': 2,
        'rejectReason': reason,
      });

      _showDialog(
        title: 'Rejected',
        content: 'You have rejected the registration request.',
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => RegistrationRequestScreen(userId: widget.userId)),
          );
        },
      );
    } catch (e) {
      _showDialog(
        title: 'Error',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() {
        isRejectLoading = false; // Stop loading
      });
    }
  }

  void _showRejectDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reject Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Please provide a reason for rejection:'),
              TextField(
                controller: _rejectReasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (_rejectReasonController.text.trim().isEmpty) {
                  // Show error dialog if reason is empty
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('Reject reason cannot be empty.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // Close the error dialog
                            },
                            child: Text('OK'),
                            style: TextButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  Navigator.of(context).pop(); // Close the dialog
                  _rejectRequest(_rejectReasonController.text); // Perform reject request
                }
              },
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDialog({
    required String title,
    required String content,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: onPressed,
              child: const Text('OK'),
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
        title: Text("Registration Request"),
        centerTitle: true,
        backgroundColor: const Color(0xFF749CB9),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Inika',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationRequestScreen(userId: widget.userId),
              ),
            );
          },
        ),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : travelAgentData == null
              ? Center(child: Text('No travel agent details available.'))
              : SingleChildScrollView( 
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
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
                                'Personal Info',
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
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black, width: 1.5),
                                  ),
                                  child: _buildImage(travelAgentData?['profileImage'], 75, 110),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildDetailRow('Name', travelAgentData?['name'], 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('DOB', _formatDate(travelAgentData?['dob']), 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('Gender', travelAgentData?['gender'], 55),
                                      SizedBox(height: 10),
                                      _buildDetailRow('Email', travelAgentData?['email'], 55),
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
                                'Company Info',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                            SizedBox(height:20),

                            _buildDetailRow('Company Name', travelAgentData?['companyName'], 125),
                            SizedBox(height: 10),
                            _buildDetailRow('Company Contact', travelAgentData?['companyContact'], 125),
                            SizedBox(height: 10),
                            _buildDetailRow('Company Address', travelAgentData?['companyAddress'], 125),
                            SizedBox(height: 10),
                            _buildDetailRow('Employee Card', '', 125),
                            SizedBox(height: 10),

                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.black, width: 1.5),
                              ),
                              child: _buildImage(travelAgentData?['employeeCardPath'], double.infinity, 220),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: isApproveLoading
                                ? null // Disable the button if it's loading
                                : () {
                                    _approveRequest();
                                  },
                            child: isApproveLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.green,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Approve',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(color: Colors.green, width: 2),
                              ),
                              minimumSize: Size(100, 40)
                            ),
                          ),
                          SizedBox(width: 20),
                          ElevatedButton(
                            onPressed: isRejectLoading
                                ? null
                                : () {
                                    _showRejectDialog();
                                  },
                            child: isRejectLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.red,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Reject',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                                side: BorderSide(color: Colors.red, width: 2),
                              ),
                              minimumSize: Size(100, 40),
                            ),
                          )
                        ]
                      )
                    ],
                  ),
                ),
              ),
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
              fontWeight: FontWeight.w600,
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  String _formatDate(dynamic date) {
    if (date is Timestamp) {
      DateTime dt = date.toDate();
      return DateFormat('dd-MM-yyyy').format(dt);
    }
    return date?.toString() ?? 'N/A';
  }

}
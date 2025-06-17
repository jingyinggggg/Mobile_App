import "dart:typed_data";

import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/adminManageWithdrawalRequestMainpage.dart";
import "package:assignment_tripmate/utils.dart";
import "package:firebase_storage/firebase_storage.dart";
import "package:flutter/material.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import 'package:encrypt/encrypt.dart' as encrypt;

class AdminRevenueDetailsScreen extends StatefulWidget {
  final String userId;
  final String withdrawalID;
  final String withdrawalUserID;

  const AdminRevenueDetailsScreen({
    super.key,
    required this.userId,
    required this.withdrawalID,
    required this.withdrawalUserID
  });

  @override
  State<AdminRevenueDetailsScreen> createState() => _AdminRevenueDetailsScreenState();
}

class _AdminRevenueDetailsScreenState extends State<AdminRevenueDetailsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, dynamic> withdrawalData = {};
  Map<String, dynamic> withdrawalUserData = {};
  bool isLoading = false;
  bool isFetching = false;
  bool isApproving = false;

  bool isSelectingImage = false;
  Uint8List? _transferProof;
  String? uploadedProof;
  final TextEditingController _proofNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchRevenueDocuments();
    _fetchWithdrawalUserDetails();
  }

  String decryptText(String encryptedText) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final parts = encryptedText.split(':');

    if (parts.length != 2) {
      print("Invalid encrypted text format: $encryptedText"); // Debugging line
      return "Decryption Error"; // Or return a default value to indicate an error
    }

    final iv = encrypt.IV.fromBase64(parts[0]);
    final encryptedData = encrypt.Encrypted.fromBase64(parts[1]);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    return encrypter.decrypt(encryptedData, iv: iv);
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

  Future<void> _fetchRevenueDocuments() async {
    setState(() {
      isLoading = true;
    });
    try {
      // Query the revenue collection
      var querySnapshot = await _firestore.collection('revenue').get();

      // Loop through each revenue document
      for (var doc in querySnapshot.docs) {
        // Query the 'withdrawal' subcollection for documents where withdrawalID matches
        var withdrawalSnapshot = await doc.reference
            .collection('withdrawal')
            .where('withdrawalID', isEqualTo: widget.withdrawalID)
            .get();

        // If a document with the specified withdrawalID exists, store its data
        if (withdrawalSnapshot.docs.isNotEmpty) {
          // Since we are looking for a single withdrawal document, take the first one
          withdrawalData = withdrawalSnapshot.docs.first.data();
          break; // Exit the loop if we found the document
        }
      }

      // Update the state to reflect the fetched data
      setState(() {
        isLoading = false; // Set loading to false after data is fetched
      });
    } catch (e) {
      print("Error fetching withdrawal data: $e");
    }
  }

  Future<void> _fetchWithdrawalUserDetails() async {
    setState(() {
      isFetching = true;
    });
    try {
      if (widget.withdrawalUserID.startsWith("TA")) {
        // Fetch from travelAgent collection
        DocumentReference reference = _firestore.collection('travelAgent').doc(widget.withdrawalUserID);
        DocumentSnapshot snapshot = await reference.get();

        if (snapshot.exists) {
          withdrawalUserData = snapshot.data() as Map<String, dynamic>;
        }
      } else {
        // Fetch from localBuddy collection
        DocumentReference reference = _firestore.collection('localBuddy').doc(widget.withdrawalUserID);
        DocumentSnapshot snapshot = await reference.get();

        if (snapshot.exists) {
          withdrawalUserData = snapshot.data() as Map<String, dynamic>;

          // Check for userID in localBuddy data and fetch additional user details
          String? userId = withdrawalUserData['userID'];
          if (userId != null) {
            DocumentReference userRef = _firestore.collection('users').doc(userId);
            DocumentSnapshot userSnapshot = await userRef.get();

            if (userSnapshot.exists) {
              // Merge the user details into withdrawalUserData
              Map<String, dynamic> userData = userSnapshot.data() as Map<String, dynamic>;
              withdrawalUserData['name'] = userData['name'];
              withdrawalUserData.addAll(userData); // Combine other user data if needed
            }
          }
        }
      }
    } catch (e) {
      print("Error fetching withdrawal user data: $e");
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  Future<void> approveRequest() async {
    // Check if transfer proof is null and show error dialog if needed
    if (_transferProof == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Error"),
            content: const Text("Please upload a transfer proof before approving the request."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
      return; // Exit the method if there is no transfer proof
    }

    setState(() {
      isApproving = true;
    });

    try {
      // Upload the image and get the download URL
      uploadedProof = await uploadImageToStorage(
        "withdrawal/${widget.withdrawalUserID}/transferProof(${widget.withdrawalID})",
        _transferProof!,
      );

      // Query the revenue collection to find the document with the field `id` matching `withdrawalUserID`
      QuerySnapshot revenueSnapshot = await _firestore
          .collection('revenue')
          .where('id', isEqualTo: widget.withdrawalUserID)
          .get();

      // Check if a matching document was found
      if (revenueSnapshot.docs.isNotEmpty) {
        // Retrieve the first matching document reference
        DocumentReference revenueDocRef = revenueSnapshot.docs.first.reference;

        // Navigate to the `withdrawal` subcollection and update the document where `withdrawalID` matches
        await revenueDocRef
            .collection('withdrawal')
            .doc(widget.withdrawalID)
            .update({
          'status': 'done',
          'transferProof': uploadedProof, // Add the proof URL if uploaded
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Admin has approved your withdrawal request for id (${widget.withdrawalID}).",
          'isRead': 0,
          'type': "withdraw",
          'timestamp': DateTime.now(),
          'receiverID': widget.withdrawalUserID
        });

        showCustomDialog(
          context: context, 
          title: "Success", 
          content: "You hace issued the withdrawal transaction successfully.", 
          onPressed: (){
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AdminRevenueMainpageScreen(userId: widget.userId))
            );
          }
        );
      } else {
        // If no document with the given `id` was found
        print("No revenue document found with id: ${widget.withdrawalUserID}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matching revenue record found.')),
        );
      }
    } catch (e) {
      print("Error approving request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to approve request.')),
      );
    } finally {
      setState(() {
        isApproving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Withdrawal Request"),
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
              MaterialPageRoute(builder: (context) => AdminRevenueMainpageScreen(userId: widget.userId))
            );
          },
        ),
      ),
      body: isLoading || isFetching
        ? Center(child: CircularProgressIndicator(color: primaryColor))
        : withdrawalData.isEmpty
          ? Center(child: Text('No withdrawal data available.', style: TextStyle(fontSize: 16, color: Colors.grey)))
          : SingleChildScrollView(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  color: Color.fromARGB(255, 219, 239, 255),
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          title: "User", 
                          value: withdrawalUserData['name'] ?? "N/A", 
                          icon: Icons.person
                        ),
                        Divider(color: Colors.grey[300]),
                        _buildInfoRow(
                          title: "Total Amount", 
                          value: "RM ${withdrawalData['amount'].toStringAsFixed(2)}", 
                          icon: Icons.attach_money
                        ),
                        Divider(color: Colors.grey[300]),
                        _buildInfoRow(
                          title: "Bank Name", 
                          value: decryptText(withdrawalUserData['bankName'] ?? "N/A"), 
                          icon: Icons.account_balance
                        ),
                        Divider(color: Colors.grey[300]),
                        _buildInfoRow(
                          title: "Account Name", 
                          value: decryptText(withdrawalUserData['accountName'] ?? "N/A"), 
                          icon: Icons.person_outline
                        ),
                        Divider(color: Colors.grey[300]),
                        _buildInfoRow(
                          title: "Account Number", 
                          value: decryptText(withdrawalUserData['accountNumber'] ?? "N/A"), 
                          icon: Icons.credit_card
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Please transfer the withdrawal amount to the provided account and upload the proof:",
                          style: TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: ElevatedButton.icon(
                            onPressed: selectImage,
                            icon: const Icon(Icons.upload_file),
                            label: const Text("Upload Transfer Proof"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: primaryColor, width: 2)
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                _proofNameController.text.isNotEmpty 
                                  ? "Proof: ${_proofNameController.text}"
                                  : "No proof uploaded",
                                style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 14, color: Colors.black54),
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
                ),
                SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (){
                      approveRequest();
                    }, 
                    child: isApproving
                    ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                    : Text(
                        "Approve Request",
                        style: TextStyle(
                          fontSize: defaultLabelFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)
                      ),
                    ),
                  ),
                )
                
              ],
            ),
          ),
    );
  }

  Widget _buildInfoRow({required String title, required String value, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[700], size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            "$title: $value",
            style: TextStyle(fontSize: defaultFontSize, color: Colors.black, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }


}

import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/user/homepage.dart";
import "package:assignment_tripmate/screens/user/localBuddyRevenueDetails.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:fl_chart/fl_chart.dart";
import "package:flutter/material.dart";
import "package:intl/intl.dart";
import 'package:encrypt/encrypt.dart' as encrypt;

class LocalBuddyRevenueScreen extends StatefulWidget {
  final String userId;
  final String localBuddyID;

  const LocalBuddyRevenueScreen({
    super.key,
    required this.userId,
    required this.localBuddyID,
  });

  @override
  State<LocalBuddyRevenueScreen> createState() => _LocalBuddyRevenueScreenState();
}

class _LocalBuddyRevenueScreenState extends State<LocalBuddyRevenueScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, double> localBuddyRevenueByMonth = {};
  List<double> waitingWithdraw = [];
  List<double> doneWithdraw = [];
  double totalWaitingWithdraw = 0.0;
  int selectedYear = DateTime.now().year;
  bool isAmountVisible = true; 
  bool isLoading = false; // Track loading state
  bool isSubmitting = false;
  List<Map<String, dynamic>> withdrawalHistory = [];
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeMonthlyData();
    _fetchRevenue(); // Fetch data on initialization
    _fetchWithdrawalHistory();
  }

  void _initializeMonthlyData() {
    localBuddyRevenueByMonth = {
      for (var i = 1; i <= 12; i++) DateFormat('MMM').format(DateTime(0, i)): 0.0
    };
  }

  String encryptText(String text) {
    final key = encrypt.Key.fromUtf8('16CharactersLong');
    final iv = encrypt.IV.fromSecureRandom(16); // Generate a random IV for each encryption
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final encrypted = encrypter.encrypt(text, iv: iv);
    // Combine IV and encrypted text with a delimiter
    return "${iv.base64}:${encrypted.base64}";
  }

  Future<void> _fetchRevenue() async {
    setState(() {
      isLoading = true; // Set loading to true when starting to fetch data
    });

    try {
      // Query to find the specific revenue document where id matches localBuddyID
      QuerySnapshot revenueSnapshot = await _firestore
          .collection('revenue')
          .where('id', isEqualTo: widget.localBuddyID) // Use where to match id field
          .get();

      // Debug: Check if revenue documents were found
      if (revenueSnapshot.docs.isNotEmpty) {
        DocumentSnapshot revenueDoc = revenueSnapshot.docs.first;
        print('Revenue document found: ${revenueDoc.id}');
        
        waitingWithdraw.clear();
        doneWithdraw.clear();
        totalWaitingWithdraw = 0.0;

        // Fetch all documents in the profit subcollection
        QuerySnapshot profitSnapshot = await _firestore
            .collection('revenue')
            .doc(revenueDoc.id) // Use the found document ID here
            .collection('profit') // Access the profit subcollection
            .get();

        for (var profitDoc in profitSnapshot.docs) {
          double profitAmount = profitDoc['profit'] ?? 0.0; // Adjust based on your field
          Timestamp profitDate = profitDoc['timestamp']; // Adjust based on your field
          int isWithdraw = profitDoc['isWithdraw'] ?? 0; // 0 for waiting, 1 for done

          if (isWithdraw == 0) {
            waitingWithdraw.add(profitAmount);
            totalWaitingWithdraw += profitAmount;
            String monthKey = DateFormat('MMM').format(profitDate.toDate());
            localBuddyRevenueByMonth[monthKey] = (localBuddyRevenueByMonth[monthKey] ?? 0) + profitAmount;
          } else {
            doneWithdraw.add(profitAmount);
            String monthKey = DateFormat('MMM').format(profitDate.toDate());
            localBuddyRevenueByMonth[monthKey] = (localBuddyRevenueByMonth[monthKey] ?? 0) + profitAmount;
          }

          print('Profit Document ID: ${profitDoc.id}, Amount: $profitAmount, Is Withdraw: $isWithdraw');
        }
      } else {
        print('No revenue document found for localBuddyID: ${widget.localBuddyID}');
      }
    } catch (e) {
      print('Error fetching revenue: $e');
    } finally {
      setState(() {
        isLoading = false; 
      });
    }
  }

  Future<void> _updateBankDetails() async{
    try{
      // Encrypt bank details
      final encryptedBankName = encryptText(_bankNameController.text);
      final encryptedAccountName = encryptText(_accountNameController.text);
      final encryptedAccountNumber = encryptText(_accountNumberController.text);

      await FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyID).update({
        'bankName': encryptedBankName,
        'accountName': encryptedAccountName,
        'accountNumber': encryptedAccountNumber
      });

      await _submitWithdrawRequest();

    }catch(e){

    }
  }

  Future<void> _fetchWithdrawalHistory() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('revenue')
          .where('id', isEqualTo: widget.localBuddyID)
          .get();

      if (snapshot.docs.isNotEmpty) {
        DocumentSnapshot revenueDoc = snapshot.docs.first;

        // Clear the list before adding new data
        withdrawalHistory.clear();

        QuerySnapshot withdrawalSnapshot = await FirebaseFirestore.instance
          .collection('revenue')
          .doc(revenueDoc.id)
          .collection('withdrawal')
          .orderBy('timestamp', descending: true) // Sort by timestamp in descending order
          .get();

        setState(() {
          withdrawalHistory = withdrawalSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      } else {
        print("No revenue document found for the user.");
      }
    } catch (e) {
      print("Error fetching withdrawal history: $e");
    }
  }

  

  Future<void> _handleWithdraw() async {
    String? userBankAccount = await _checkBankAccount();

    if (userBankAccount == null) {
      // Show bank details input dialog
      await _showBankDetailsInputDialog();
    } else {
      // Show confirmation dialog
      bool? confirm = await _showConfirmationDialog();
      if (confirm == true) {
        // Proceed with withdrawal action
        await _submitWithdrawRequest();
      }
    }
  }

  Future<String?> _checkBankAccount() async {
    var snapshot = await FirebaseFirestore.instance
        .collection('localBuddy')
        .doc(widget.localBuddyID)
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      return snapshot.data()!['bankName']; // Adjust field name based on your database
    }
    return null; // No bank account found
  }

  Future<void> _showBankDetailsInputDialog() async{
    await showDialog(
      context: context, 
      builder: (BuildContext context){
        return AlertDialog(
          title: Text('Bank Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Please enter your bank details before submit withdrawal request:",
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
                  ),
              ],
            ),
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
              onPressed: () async {
                if (_bankNameController.text.trim().isEmpty && _accountNameController.text.trim().isEmpty && _accountNumberController.text.trim().isEmpty) {
                  // Show error dialog if reason is empty
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('Please make sure you have filled in all required field.'),
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
                  Navigator.pop(context);
                  await _updateBankDetails();
                }
              },
              child: isSubmitting
              ? SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(color: Colors.white,),
              )
              : Text('Submit'),
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
      }
    );
  }

  Future<bool?> _showConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Withdrawal'),
          content: Text('Are you sure you want to proceed with the withdrawal?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirm'),
              style: TextButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitWithdrawRequest() async {
    setState(() {
      isSubmitting = true;
    });

    // Generate a unique withdrawal ID
    String withdrawalID = DateTime.now().millisecondsSinceEpoch.toString();

    try {
      // Query to find the specific revenue document where `id` matches `widget.userId`
      QuerySnapshot revenueSnapshot = await FirebaseFirestore.instance
          .collection('revenue')
          .where('id', isEqualTo: widget.localBuddyID)
          .get();

      if (revenueSnapshot.docs.isNotEmpty) {
        // Get the document reference of the matched revenue document
        DocumentReference revenueDocRef = revenueSnapshot.docs.first.reference;

        // Fetch the profit subcollection to update documents with `isWithdraw = 0`
        QuerySnapshot profitSnapshot = await revenueDocRef
            .collection('profit')
            .where('isWithdraw', isEqualTo: 0)
            .get();

        // Batch to update all waiting withdraw documents
        WriteBatch batch = FirebaseFirestore.instance.batch();

        for (var profitDoc in profitSnapshot.docs) {
          DocumentReference profitRef = profitDoc.reference;

          // Update each document with `isWithdraw = 1` and set the `withdrawalID`
          batch.update(profitRef, {
            'isWithdraw': 1,
            'withdrawalID': withdrawalID,
          });
        }

        // Commit the batch to update all waiting withdraw documents at once
        await batch.commit();

        // Add a new document in the `withdrawal` subcollection with withdrawal details
        await revenueDocRef.collection('withdrawal').doc(withdrawalID).set({
          'withdrawalID': withdrawalID,
          'amount': totalWaitingWithdraw,
          'status': 'pending', // Set as 'pending' initially
          'timestamp': Timestamp.now(),
        });

        await FirebaseFirestore.instance.collection('notification').doc().set({
          'content': "Local Buddy (${widget.localBuddyID}) has submitted a withdrawal request. Please issue the withdrawal transaction.",
          'isRead': 0,
          'type': "withdraw",
          'timestamp': DateTime.now(),
          'receiverID': "A1001"
        });

        print('Withdrawal request submitted successfully with ID: $withdrawalID');

        showCustomDialog(
          context: context, 
          title: "Success", 
          content: "You have submitted the withdrawal request successfully. Please wait for admin to issue your withdrawal request.", 
          onPressed: (){
            Navigator.pop(context);
            _fetchWithdrawalHistory();
          }
        );
        
        // Clear `waitingWithdraw` list and reset the total waiting amount after successful submission
        setState(() {
          waitingWithdraw.clear();
          totalWaitingWithdraw = 0.0;
        });
      } else {
        print('No revenue document found for userId: ${widget.userId}');
      }

    } catch (e) {
      print('Error submitting withdrawal request: $e');
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  List<FlSpot> _getDataPoints() {
    List<String> months = localBuddyRevenueByMonth.keys.toList();
    return months.asMap().entries.map((entry) {
      int index = entry.key;
      String month = entry.value;
      return FlSpot(index.toDouble(), localBuddyRevenueByMonth[month]?.toDouble() ?? 0);
    }).toList();
  }

  // Determine the y-axis intervals and max value based on total revenue
  double _getMaxYValue() {
    double maxValue = totalWaitingWithdraw > 0 ? totalWaitingWithdraw : 1; // Fallback for maxValue
    if (maxValue <= 1000) return 1000; 
    if (maxValue <= 2000) return 2000; 
    if (maxValue <= 3000) return 3000; 
    if (maxValue <= 4000) return 4000; 
    if (maxValue <= 5000) return 5000; 
    if (maxValue <= 6000) return 6000; 
    if (maxValue <= 7000) return 7000; 
    if (maxValue <= 8000) return 8000; 
    if (maxValue <= 9000) return 9000; 
    if (maxValue <= 10000) return 10000; 
    return (maxValue / 1000).ceil() * 1000; // Round up to nearest thousand
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Revenue"),
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
              MaterialPageRoute(builder: (context) => UserHomepageScreen(userId: widget.userId, currentPageIndex: 4,))
            );
          },
        ),
      ),
      body: isLoading // Show loading indicator or content based on loading state
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Revenue to Withdraw",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    isAmountVisible
                                        ? "RM ${totalWaitingWithdraw.toStringAsFixed(2)}"
                                        : "RM ****",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isAmountVisible ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.black,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        isAmountVisible = !isAmountVisible; // Toggle visibility state
                                      });
                                    },
                                  ),
                                ],
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Handle withdraw action
                                  if(waitingWithdraw.isEmpty){
                                    showCustomDialog(
                                      context: context, 
                                      title: "Error", 
                                      content: "No revenue pending to withdraw currently.", 
                                      onPressed: (){
                                        Navigator.pop(context);
                                      }
                                    );
                                  } else{
                                    _handleWithdraw();
                                  }
                                },
                                child: isSubmitting
                                ? SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(color: Colors.white,),
                                  )
                                : Text(
                                    "Withdraw", 
                                    style:TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      fontSize: defaultFontSize
                                    )
                                  ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  minimumSize: Size(40, 35),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 4,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Monthly Revenue Trend",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: 20),
                          SizedBox(
                            height: 300,
                            child: LineChart(
                              LineChartData(
                                gridData: FlGridData(show: false),
                                titlesData: FlTitlesData(
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 30,
                                      interval: _getMaxYValue() / 5, // Adjust interval based on max y value
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 38,
                                      getTitlesWidget: (value, meta) {
                                        int index = value.toInt();
                                        return Text(
                                          localBuddyRevenueByMonth.keys.elementAt(index),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                ),

                                borderData: FlBorderData(show: true, border: Border.all(color: const Color(0xff37434d), width: 1)),
                                minX: 0,
                                maxX: localBuddyRevenueByMonth.length.toDouble() - 1,
                                minY: 0,
                                maxY: _getMaxYValue(),
                                lineBarsData: [
                                  LineChartBarData(
                                    spots: _getDataPoints(),
                                    isCurved: false,
                                    color: Colors.blue,
                                    dotData: FlDotData(show: true),
                                    belowBarData: BarAreaData(show: false),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Withdrawal History",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        // Check if withdrawal history data is available
                        withdrawalHistory.isNotEmpty
                            ? ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: withdrawalHistory.length,
                                itemBuilder: (context, index) {
                                  var historyItem = withdrawalHistory[index];
                                  return Card(
                                    elevation: 4,
                                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    child: ListTile(
                                      tileColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8.0),
                                      ),
                                      title: Text(
                                        'RM ${historyItem['amount'].toStringAsFixed(2)}',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                      subtitle: Text(
                                        'Date: ${DateFormat('yyyy-MM-dd').format(historyItem['timestamp'].toDate())}\nID: ${historyItem['withdrawalID']}',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                      trailing: Icon(
                                        historyItem['status'] == "pending" ? Icons.pending_actions : Icons.check_circle,
                                        color: historyItem['status'] == "pending" ? Colors.orange : Colors.green,
                                      ),
                                      onTap: (){
                                        Navigator.push(
                                          context, 
                                          MaterialPageRoute(builder: (context) => LocalBuddyRevenueDetailsScreen(userId: widget.userId, withdrawalID: historyItem['withdrawalID'], localBuddyID: widget.localBuddyID))
                                        );
                                      },
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Text(
                                  "No withdrawal history available",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                      ]
                    )
                  )
                ],
              ),
            ),
    );
  }
}

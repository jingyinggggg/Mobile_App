import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentAddTourPackage.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentEditTourPackage.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewCity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class TravelAgentViewTourListScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;

  const TravelAgentViewTourListScreen({super.key, required this.userId, required this.countryName, required this.cityName});

  @override
  State<StatefulWidget> createState() => _TravelAgentViewTourListScreenState();
}

class _TravelAgentViewTourListScreenState extends State<TravelAgentViewTourListScreen> {
  bool isLoading = true; 
  bool isButtonLoading = false;
  String? companyId;
  TextEditingController _searchController = TextEditingController(); // Add this

  @override
  void initState() {
    super.initState();
    fetchCompanyID();
  }

  Future<void> fetchCompanyID() async {
    try {
      DocumentReference companyIDRef = FirebaseFirestore.instance.collection('travelAgent').doc(widget.userId);
      DocumentSnapshot documentSnapshot = await companyIDRef.get();

      if (documentSnapshot.exists) {
        setState(() {
          companyId = documentSnapshot.get("companyID").toString();
        });
        print('Company ID: $companyId');
      } else {
        print('No such document exists.');
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching company ID: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _publishTour(bool isPublished, String tourID) async{
    setState(() {
      isButtonLoading = true; // Start loading
    });

    try{
      int setPublishStatus;

      if(isPublished){
        setPublishStatus = 0;
      } else{
        setPublishStatus = 1;
      }

      await FirebaseFirestore.instance.collection('tourPackage').doc(tourID).update({
        'isPublish': setPublishStatus,
      });

      showCustomDialog(
        context: context, 
        title: 'Success', 
        content: setPublishStatus == 1 ? 'Tour package published successfully!' : 'You have set the tour package unavailable for users.', 
        onPressed: () {
          Navigator.of(context).pop();
        },
      );

    } catch(e){
        showCustomDialog(
        context: context, 
        title: 'Failed', 
        content: 'An error occurred: $e', 
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() {
        isButtonLoading = false; // Stop loading
      });
    }
  }

  void _showConfirmationDialog(bool isPublished, String tourID) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(isPublished ? 'Unpublish Tour Package' : 'Publish Tour Package'),
          content: Html(
            data: isPublished
                ? '<p style="text-align:justify;">Are you sure you want to unpublish this tour package? It will no longer be visible to users.</p>'
                : '<p style="text-align:justify;">Are you sure you want to publish this tour package? It will be visible to users.</p>',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.black)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                _publishTour(isPublished, tourID); // Proceed with the action
              },
              child: const Text('Yes'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.grey.shade100, // Change to match your app's theme if necessary
              ),
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
        title: const Text("Group Tour"),
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
              MaterialPageRoute(builder: (context) => TravelAgentViewCityScreen(userId: widget.userId, countryName: widget.countryName,))
            );
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white, size: 30,),
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => TravelAgentAddTourPackageScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName,))
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
            child: Container(
              height: 60,
              child: TextField(
                controller: _searchController, // Bind search controller
                onChanged: (value) {
                  setState(() {}); // Trigger the UI update on text change
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.blueGrey, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Color(0xFF467BA1), width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.red, width: 2),
                  ),
                  hintText: "Search tour package ...",
                  hintStyle: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _buildTourList(), // Use a single list view to display all packages
          )
        ],
      ),
    );
  }

  // Helper function to build the tour list
  Widget _buildTourList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('tourPackage')
          .where('countryName', isEqualTo: widget.countryName)
          .where('cityName', isEqualTo: widget.cityName)
          .where('companyID', isEqualTo: companyId)
          .snapshots(), // Fetch all tour packages regardless of publish status
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.only(left: 20, right: 20),
              child: Text(
                "No tour package available.",
                style: TextStyle(
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        // Filter the tours based on search query
        var tourData = snapshot.data!.docs.map((doc) => doc.data()).where((tour) {
          String tourName = tour['tourName']?.toLowerCase() ?? '';
          return tourName.contains(_searchController.text.toLowerCase());
        }).toList();

        return Container(
          padding: EdgeInsets.only(top: 10, bottom: 15),
          child: ListView.builder(
            itemCount: tourData.length,
            itemBuilder: (context, index) {
              var tour = tourData[index];
              bool isPublished = tour['isPublish'] == 1;
              return ListTile(
                title: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Conditionally show the image
                    if (tour['tourCover'] != null)
                      Container(
                        width: 70,
                        height: 90,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(tour['tourCover']),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    // If imageUrl is null, show a placeholder
                    if (tour['tourCover'] == null)
                      Container(
                        width: 70,
                        height: 90,
                        margin: EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[200], // Placeholder color
                        ),
                        child: Icon(
                          Icons.image,
                          color: Colors.grey[600],
                        ),
                      ),

                    // Tour Name
                    Expanded(
                      child: Text(
                        tour['tourName'] ?? 'No Tour Name',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                    ),

                    SizedBox(width: 5),

                    Row(
                      children: [
                        Container(
                          width: 25,
                          child: IconButton(
                            icon: isPublished ? Icon(Icons.check_circle_rounded) : Icon(Icons.not_interested_rounded),
                            color: isPublished ? Colors.green : Colors.grey.shade500,
                            tooltip: isPublished ? 'Published' : 'Unpublish',
                            onPressed: () {
                              _showConfirmationDialog(isPublished, tour['tourID']);
                            },
                          ),
                        ),
                        SizedBox(width: 10),
                        Container(
                          width: 25,
                          child: IconButton(
                            onPressed: (){
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => TravelAgentEditTourPackageScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName, tourID: tour['tourID'] ?? ''))
                              );
                            }, 
                            icon: Icon(Icons.edit),
                            color: Colors.grey.shade500,
                            tooltip: 'Edit',
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }



  // @override
  // Widget build(BuildContext content) {
  //   return DefaultTabController(
  //     length: 2,
  //     child: Scaffold(
  //       backgroundColor: Colors.white,
  //       resizeToAvoidBottomInset: true,
  //       appBar: AppBar(
  //         title: const Text("Group Tour"),
  //         centerTitle: true,
  //         backgroundColor: const Color(0xFF749CB9),
  //         titleTextStyle: const TextStyle(
  //           color: Colors.white,
  //           fontFamily: 'Inika',
  //           fontWeight: FontWeight.bold,
  //           fontSize: 20,
  //         ),
  //         leading: IconButton(
  //           icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
  //           onPressed: () {
  //             Navigator.push(
  //               context, 
  //               MaterialPageRoute(builder: (context) => TravelAgentViewCityScreen(userId: widget.userId, countryName: widget.countryName,))
  //             );
  //           },
  //         ),
  //         actions: <Widget>[
  //           IconButton(
  //             icon: const Icon(Icons.add, color: Colors.white, size: 30,),
  //             onPressed: () {
  //               Navigator.push(
  //                 context, 
  //                 MaterialPageRoute(builder: (context) => TravelAgentAddTourPackageScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName,))
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //       body: Column(
  //         children: [
  //           Padding(
  //             padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
  //             child: Container(
  //               height: 60,
  //               child: TextField(
  //                 controller: _searchController, // Bind search controller
  //                 onChanged: (value) {
  //                   setState(() {}); // Trigger the UI update on text change
  //                 },
  //                 decoration: InputDecoration(
  //                   filled: true,
  //                   fillColor: Colors.white,
  //                   contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
  //                   prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
  //                   border: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                     borderSide: BorderSide(color: Colors.blueGrey, width: 2),
  //                   ),
  //                   enabledBorder: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                     borderSide: BorderSide(color: Colors.blueGrey, width: 2),
  //                   ),
  //                   focusedBorder: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                     borderSide: BorderSide(color: Color(0xFF467BA1), width: 2),
  //                   ),
  //                   errorBorder: OutlineInputBorder(
  //                     borderRadius: BorderRadius.circular(10),
  //                     borderSide: BorderSide(color: Colors.red, width: 2),
  //                   ),
  //                   hintText: "Search tour package ...",
  //                   hintStyle: TextStyle(
  //                     fontSize: 16,
  //                     color: Colors.grey.shade500,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //               ),
  //             ),
  //           ),

  //           const TabBar(
  //             labelColor: Color(0xFF467BA1),
  //             unselectedLabelColor: Colors.grey,
  //             indicatorColor: Color(0xFF467BA1),
  //             tabs: [
  //               Tab(text: "Unpublished"),
  //               Tab(text: "Published")
  //             ],
  //           ),

  //           Expanded(
  //             child: TabBarView(
  //               children: [
  //                 // Unpublished Tab
  //                 _buildTourList(isPublished: false),

  //                 // Published Tab
  //                 _buildTourList(isPublished: true),
  //               ],
  //             ),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // // Helper function to build the tour list
  // Widget _buildTourList({required bool isPublished}) {
  //   return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
  //     stream: FirebaseFirestore.instance
  //         .collection('tourPackage')
  //         .where('countryName', isEqualTo: widget.countryName)
  //         .where('cityName', isEqualTo: widget.cityName)
  //         .where('companyID', isEqualTo: companyId)
  //         .where('isPublish', isEqualTo: isPublished ? 1 : 0)
  //         .snapshots(),
  //     builder: (context, snapshot) {
  //       if (snapshot.connectionState == ConnectionState.waiting) {
  //         return const Center(child: CircularProgressIndicator());
  //       }

  //       if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
  //         return const Center(
  //           child: Padding(
  //             padding: EdgeInsets.only(left: 20, right: 20),
  //             child: Text(
  //               "No tour package available.",
  //               style: TextStyle(
  //                 fontSize: 16,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ),
  //         );
  //       }

  //       // Filter the tours based on search query
  //       var tourData = snapshot.data!.docs.map((doc) => doc.data()).where((tour) {
  //         String tourName = tour['tourName']?.toLowerCase() ?? '';
  //         return tourName.contains(_searchController.text.toLowerCase());
  //       }).toList();

  //       return Container(
  //         padding: EdgeInsets.only(top: 15, bottom: 15),
  //         child: ListView.builder(
  //           itemCount: tourData.length,
  //           itemBuilder: (context, index) {
  //             var tour = tourData[index];
  //             return ListTile(
  //               title: Row(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //                 children: [
  //                   // Conditionally show the image
  //                   if (tour['tourCover'] != null)
  //                     Container(
  //                       width: 70,
  //                       height: 90,
  //                       margin: EdgeInsets.only(right: 10),
  //                       decoration: BoxDecoration(
  //                         image: DecorationImage(
  //                           image: NetworkImage(tour['tourCover']),
  //                           fit: BoxFit.cover,
  //                         ),
  //                       ),
  //                     ),
                    
  //                   // If imageUrl is null, show a placeholder
  //                   if (tour['tourCover'] == null)
  //                     Container(
  //                       width: 70,
  //                       height: 90,
  //                       margin: EdgeInsets.only(right: 10),
  //                       decoration: BoxDecoration(
  //                         borderRadius: BorderRadius.circular(8),
  //                         color: Colors.grey[200], // Placeholder color
  //                       ),
  //                       child: Icon(
  //                         Icons.image,
  //                         color: Colors.grey[600],
  //                       ),
  //                     ),

  //                   // Tour Name
  //                   Expanded(
  //                     child: Text(
  //                       tour['tourName'] ?? 'No Tour Name',
  //                       style: TextStyle(
  //                         fontSize: 15,
  //                         fontWeight: FontWeight.bold,
  //                       ),
  //                       textAlign: TextAlign.justify,
  //                     ),
  //                   ),

  //                   Row(
  //                     children: [
  //                       Container(
  //                         width: 30,
  //                         child: IconButton(
  //                           icon: isPublished ? Icon(Icons.check_circle_rounded) : Icon(Icons.not_interested_rounded),
  //                           color: isPublished ? Colors.green : Colors.grey.shade500,
  //                           tooltip: isPublished ? 'Unpublish' : 'Publish',
  //                           onPressed: () {
  //                             _showConfirmationDialog(isPublished, tour['tourID']);
  //                           },
  //                         ),
  //                       ),
  //                       SizedBox(width: 5),
  //                       Container(
  //                         width: 30,
  //                         child: IconButton(
  //                           onPressed: (){
  //                             Navigator.push(
  //                               context, 
  //                               MaterialPageRoute(builder: (context) => TravelAgentEditTourPackageScreen(userId: widget.userId, countryName: tour['countryName'] ?? '', cityName: tour['cityname'] ?? '', tourID: tour['tourID'] ?? ''))
  //                             );
  //                           }, 
  //                           icon: Icon(Icons.edit),
  //                           color: Colors.grey.shade500,
  //                           tooltip: 'Edit',
  //                         ),
  //                       )
  //                     ],
  //                   ),
  //                 ],
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  // }
}

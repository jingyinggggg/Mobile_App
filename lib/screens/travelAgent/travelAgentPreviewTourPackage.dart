import 'package:assignment_tripmate/screens/travelAgent/travelAgentEditTourPackage.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewTourList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TravelAgentPreviewTourPackageScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;
  final String tourID;
  final int status;

  const TravelAgentPreviewTourPackageScreen({
    super.key,
    required this.userId,
    required this.countryName,
    required this.cityName,
    required this.tourID,
    required this.status,
  });

  @override
  State<StatefulWidget> createState() => _TravelAgentPreviewTourPackageScreenState();
}

class _TravelAgentPreviewTourPackageScreenState extends State<TravelAgentPreviewTourPackageScreen> {
  Map<String, dynamic>? tourData;
  bool isLoading = false;
  bool isButtonLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTourData();
  }

  Future<void> _fetchTourData() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference tourRef = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot docSnapshot = await tourRef.get();

      if (docSnapshot.exists) {
        Map<String, dynamic>? data = docSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          tourData = data ?? {}; // Ensure tourData is never null
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No tour found with the given tourID.')),
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

  Future<void> _publishTour() async{
    setState(() {
      isButtonLoading = true; // Start loading
    });

    try{
      int setPublishStatus;

      if(widget.status == 0){
        setPublishStatus = 1;
      } else{
        setPublishStatus = 0;
      }

      await FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID).update({
        'isPublish': setPublishStatus,
      });

      _showDialog(
        title: 'Success',
        content: setPublishStatus == 1 ? 'Tour package published successfully!' : 'You have set the tour package unavailable for users.',
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context, 
            MaterialPageRoute(builder: (context) => TravelAgentViewTourListScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName))
          );
        },
      );

    } catch(e){
      _showDialog(
        title: 'Error',
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
              MaterialPageRoute(
                builder: (context) => TravelAgentViewTourListScreen(
                  userId: widget.userId,
                  countryName: widget.countryName,
                  cityName: widget.cityName,
                ),
              ),
            );
          },
        ),
        actions: <Widget>[
          if (widget.status == 0) 
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: Colors.white,
                size: 25,
              ),
              onPressed: () {
                final tourID = tourData?['tourID'];

                if (tourID != null){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => TravelAgentEditTourPackageScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName, tourID: tourID))
                  );                  
                } else {
                  // Handle the case where receiverUserId is null
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tour ID is not available')),
                  );
                }
              },
            ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator()) // Show a loading indicator while data is being fetched
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (tourData?['tourCover'] != null) ...[
                    Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            image: DecorationImage(
                              image: NetworkImage(tourData!['tourCover']),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: Align(
                            alignment: Alignment.center,
                            child: Container(
                              width: double.infinity,
                              height: 50,
                              color: Colors.white.withOpacity(0.7),
                              child: Center(
                                child: Text(
                                  tourData!['tourName'] ?? 'No Name',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0.5, 0.5),
                                        color: Colors.black87,
                                      ),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  ] else ...[
                    Container(
                      width: double.infinity,
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey,
                      ),
                      child: const Center(
                        child: Text(
                          'No Image Available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          alignment: Alignment.center,
                          child: Text(
                            "*** You are viewing from user perspective currently. ***",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.red
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Agency Info",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const ImageIcon(
                                    AssetImage("images/download-pdf.png"),
                                    size: 23,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    // Add PDF download functionality here if needed
                                  },
                                ),
                                SizedBox(width: 10),
                                Icon(
                                  Icons.favorite_border,
                                  size: 23,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ],
                        ),

                        Text(
                          "Agency: ${tourData?['agency'] ?? 'No Agency Info'}",
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.black
                          ),
                        ),

                        SizedBox(height: 20),

                        Text(
                          "Tour Highlights",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tourData?['tourHighlight']?.length ?? 0,
                          itemBuilder: (context, index) {
                            var tourHighlight = tourData!['tourHighlight'][index];
                            return tourHighlightComponent(
                              tourHighlight['no'] ?? 'No Numbering',
                              tourHighlight['description'] ?? 'No Description',
                            );
                          },
                        ),

                        SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Itinerary",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {},
                              child: Row(
                                children: [
                                  const Text(
                                    "Enquiry",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  const ImageIcon(
                                    AssetImage("images/communication.png"),
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF467BA1),
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(0),
                                ),
                              ),
                            )
                          ],
                        ),

                        SizedBox(height: 10),

                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tourData?['itinerary']?.length ?? 0,
                          itemBuilder: (context, index) {
                            var itinerary = tourData!['itinerary'][index];
                            return itineraryComponent(
                              itinerary['day'] ?? 'No Day',
                              itinerary['title'] ?? 'No Title',
                              itinerary['description'] ?? 'No Description',
                              itinerary['overnight'] ?? 'No Remarks',
                            );
                          },
                        ),

                        SizedBox(height: 20),

                        Text(
                          "Availability",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 10),

                        availabilityComponent(tourData!),

                        SizedBox(height:30),

                        Container(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: (){_publishTour();},
                            child: isLoading
                                ? const CircularProgressIndicator()
                                : Text(
                                    widget.status == 0 ? 'Publish' : 'Unpublish',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF467BA1),
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ) 

                        // ElevatedButton(
                        //   onPressed: _publishTour,
                        //   child: isButtonLoading 
                        //   ? CircularProgressIndicator() 
                        //   : Text(
                        //     widget.status == 0 ? 'Publish' : 'Unpublish',
                        //     style: TextStyle(
                        //       color: Colors.white,
                        //     ),
                        //   ),
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: const Color(0xFF467BA1),
                        //     padding: const EdgeInsets.symmetric(vertical: 15),
                        //     textStyle: const TextStyle(
                        //       fontSize: 20,
                        //       fontWeight: FontWeight.bold,
                        //     ),
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8),
                        //     ),
                        //   ),
                        // ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }


  Widget tourHighlightComponent(String numbering, String description) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Align items to the top
        children: [
          Text(
            numbering + '.',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
          ),
          SizedBox(width: 10),
          // Use Expanded to make sure the description text wraps properly
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 15,
                color: Colors.black,
              ),
              textAlign: TextAlign.justify,
              maxLines: null, // Allow multi-line text
              overflow: TextOverflow.visible, // Show entire text
            ),
          ),
        ],
      ),
    );
  }

  Widget itineraryComponent(String day, String title, String description, String overnightCity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: IntrinsicHeight( // Ensure both sides of the Row stretch to the tallest child
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch both columns to match heights
          children: [
            Column(
              children: [
                Container(
                  width: 60,
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFF467BA1),
                    border: Border(
                      left: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      top: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      bottom: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                      right: BorderSide.none,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    "DAY",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded( // Use Expanded here to stretch the Day number container
                  child: Container(
                    alignment: Alignment.center,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        left: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        top: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        bottom: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                        right: BorderSide.none,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF467BA1),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '*** $overnightCity',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

Widget availabilityComponent(Map<String, dynamic> data) {
  if (data.isEmpty || data['availability'] == null || data['availability'].isEmpty || data['flight_info'] == null || data['flight_info'].isEmpty) {
    return Center(
      child: Text('No availability data found'),
    );
  } else {
    List<dynamic> availabilityList = data['availability'];
    List<dynamic> flightInfoList = data['flight_info'];

    // Ensure both lists are of equal length
    int length = availabilityList.length < flightInfoList.length ? availabilityList.length : flightInfoList.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF467BA1), width: 1.0),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(1.2),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.2),
            },
            border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
            children: [
              // Header row
              TableRow(
                children: [
                  _buildTableHeaderCell("Date"),
                  _buildTableHeaderCell("Flight"),
                  _buildTableHeaderCell("Price"),
                ],
              ),
              // Data rows
              for (int i = 0; i < length; i++)
                TableRow(
                  children: [
                    _buildTextFieldCell(availabilityList[i]['dateRange'] ?? 'No Date'),
                    _buildTextFieldCell(flightInfoList[i]['flightName'] ?? 'No Flight'),
                    _buildTextFieldCell('RM ' + (availabilityList[i]['price']?.toString() ?? '0') + '.00'),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}



  Widget _buildTextFieldCell(String text) {
    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFF467BA1), width: 1.0),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: 10, bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
            fontWeight: FontWeight.w600
          ),
          maxLines: null, // Allows multiline input
          textAlign: TextAlign.center,
        ),
      )

    );
  }  

  Widget _buildTableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: const Color(0xFF467BA1).withOpacity(0.6),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
      ),
    );
  }  

}

import 'dart:io';

import 'package:assignment_tripmate/screens/admin/adminViewTourList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class AdminTourPackageDetailsScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;
  final String tourID;
  final String countryId;

  const AdminTourPackageDetailsScreen({
    super.key,
    required this.userId,
    required this.countryName,
    required this.cityName,
    required this.tourID, 
    required this.countryId,
  });

  @override
  State<StatefulWidget> createState() => _AdminTourPackageDetailsScreenState();
}

class _AdminTourPackageDetailsScreenState extends State<AdminTourPackageDetailsScreen> {
  Map<String, dynamic>? tourData;
  bool isLoading = false;
  bool isOpenFile = false;

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

  Future openFile({required String url, String? fileName}) async {
    setState(() {
      isOpenFile = true;
    });
    final file = await downloadFile(url, fileName!);

    if(file == null) return;
    print('Path: ${file.path}');
    OpenFile.open(file.path);

    setState(() {
      isOpenFile = false;
    });
  }

  // Download file into private foler not visible to user
  Future<File?> downloadFile(String url, String name) async {
    final appStorage = await getApplicationDocumentsDirectory();
    final file = File('${appStorage.path}/$name');

    try{
      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          receiveTimeout: Duration(seconds: 10),
        )
      );

      final raf = file.openSync(mode: FileMode.write);
      raf.writeFromSync(response.data);
      await raf.close();

      return file;
    } catch(e){
      return null;
    }
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
                builder: (context) => AdminViewTourListScreen(
                  userId: widget.userId,
                  countryName: widget.countryName,
                  cityName: widget.cityName,
                  countryId: widget.countryId,
                ),
              ),
            );
          },
        ),
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
                              height: 60,
                              color: Colors.white.withOpacity(0.7),
                              child: Center(
                                child: Text(
                                  tourData!['tourName'] ?? 'No Name',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
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
                                  icon: isOpenFile
                                      ? SizedBox(
                                          width: 20.0, // Set the desired width
                                          height: 20.0, // Set the desired height
                                          child: CircularProgressIndicator(
                                            color: Color(0xFF467BA1), // Set the color
                                          ),
                                        ) // Show loading indicator when loading
                                      : const ImageIcon(
                                          AssetImage("images/download-pdf.png"),
                                          size: 23,
                                          color: Colors.black,
                                        ),
                                  onPressed: isOpenFile
                                      ? null // Disable button when loading
                                      : () {
                                          openFile(
                                            url: tourData?['brochure'],
                                            fileName: '${tourData?['tourName']}.pdf',
                                          );
                                        },
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

  Widget itineraryComponent(String day, String title, String description) {
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

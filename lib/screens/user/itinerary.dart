import 'package:assignment_tripmate/screens/user/itineraryAI.dart';
import 'package:assignment_tripmate/screens/user/viewAIItinerary.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ItineraryScreen extends StatefulWidget {
  final String userId;
  const ItineraryScreen({super.key, required this.userId});

  @override
  State<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends State<ItineraryScreen> {
  bool isFetchingItinerary = false;
  List<Map<String, dynamic>> _itineraryList = [];
  List<Map<String, dynamic>> _foundeditineraryList = [];

  @override
  void initState() {
    super.initState();
    _fetchItinerary();
  }

  Future<void> _fetchItinerary() async {
    setState(() {
      isFetchingItinerary = true;
    });
    try {
      CollectionReference itineraryRef = FirebaseFirestore.instance.collection('itineraries');
      QuerySnapshot querySnapshot = await itineraryRef.where('userId', isEqualTo: widget.userId).get();

      _itineraryList = querySnapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() {
        _foundeditineraryList = _itineraryList;
      });
    } catch (e) {
      print('Error fetching itineraries: $e');
    } finally {
      setState(() {
        isFetchingItinerary = false;
      });
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundeditineraryList = _itineraryList
          .where((itinerary) =>
              itinerary['title'].toUpperCase().contains(search.toUpperCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _itineraryList.isEmpty
              ? Container(
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: AssetImage("images/itineraryPic.png"),
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.width * 0.5,
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 380,
                        child: Text(
                          "You do not create any itinerary yet. Start to create your itinerary now using the build with AI function.",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        width: 150,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => AIItineraryScreen(userId: widget.userId)),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF467BA1),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            "Build with AI",
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
                      child: Container(
                        height: 60,
                        child: TextField(
                          onChanged: onSearch, // Connect the search function
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
                            hintText: "Search itinerary...",
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 10.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => AIItineraryScreen(userId: widget.userId)),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF467BA1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(color: Color(0xFF467BA1), width: 2),
                              ),
                            ),
                            child: Text(
                              "Build with AI",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _foundeditineraryList.length,
                        itemBuilder: (context, index) {
                          return itineraryComponent(data: _foundeditineraryList[index], index: index);
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget itineraryComponent({required Map<String, dynamic> data, required int index}) {
    return Container(
      padding: EdgeInsets.all(15),
      height: 70,
      margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3), // changes position of shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${index + 1}. ${data['title']}', // Correctly formatting the title with the index
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black, // Primary color
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ViewAIItineraryScreen(userId: widget.userId, itineraryID: data['itineraryID'],fromAppLink: "false",))
              );
            },
            icon: Icon(Icons.remove_red_eye),
            iconSize: 24,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }
}

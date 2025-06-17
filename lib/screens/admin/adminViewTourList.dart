import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewTourDetails.dart';
import 'package:assignment_tripmate/screens/admin/manageCityList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminViewTourListScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;
  final String countryId;

  const AdminViewTourListScreen({super.key, required this.userId, required this.countryName, required this.cityName, required this.countryId});

  @override
  State<AdminViewTourListScreen> createState() => _AdminViewTourListScreenState();
}

class _AdminViewTourListScreenState extends State<AdminViewTourListScreen> {
  List<TourPackage> _tourList = [];
  List<TourPackage> _foundedTour = [];
  bool hasCity = false;
  bool isLoading = true;  // Add a loading indicator flag

  @override
  void initState() {
    super.initState();
    fetchTourList();
  }

  Future<void> fetchTourList() async {
    try {
      // Reference to the cities collection in Firestore
      CollectionReference tourRef = FirebaseFirestore.instance.collection('tourPackage');

      // Fetch the documents from the cities collection
      QuerySnapshot querySnapshot = await tourRef.where('countryName', isEqualTo: widget.countryName).where('cityName', isEqualTo: widget.cityName).get();

      // Convert each document into a City object and add to _cityList
      _tourList = querySnapshot.docs.map((doc) {
        return TourPackage(
          doc['tourName'],
          doc['tourID'],
          doc['tourCover'],
          doc['agency'],
        );
      }).toList();

      setState(() {
        _foundedTour = _tourList;
        hasCity = _foundedTour.isNotEmpty;
        isLoading = false;  // Stop loading when the data is fetched
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching tour list: $e');
      setState(() {
        isLoading = false;  // Stop loading in case of an error
      });
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundedTour = _tourList.where((tourPackage) => tourPackage.tourName.toUpperCase().contains(search.toUpperCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Tour List"),
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
              MaterialPageRoute(builder: (context) => AdminManageCityListScreen(userId: widget.userId, countryName: widget.countryName, countryId: widget.countryId,))
            );
          },
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 20, right: 10),
                child: Container(
                  height: 60,
                  child: TextField(
                    onChanged: (value) => onSearch(value),
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
                      hintText: "Search tour list...",
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while fetching data
          : hasCity
          ? Container(
              padding: EdgeInsets.only(right: 10, left: 15, top: 100),
              child: ListView.builder(
                itemCount: _foundedTour.length,
                itemBuilder: (context, index) {
                  return tourComponent(tourPackage: _foundedTour[index]);
                }
              ),
            )
          : Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  "No tour package available for the selected cities or country.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ]
      ),
    );
  }

  Widget tourComponent({required TourPackage tourPackage}) {
  return Container(
    width: getScreenWidth(context),
    margin: EdgeInsets.only(bottom: 20),
    child: Row(
      children: [
        Container(
          width: getScreenWidth(context) * 0.15,
          height: getScreenHeight(context) * 0.1,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0),
            image: DecorationImage(
              image: NetworkImage(tourPackage.image),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Aligns text to occupy full width
                children: [
                  Expanded(
                    child: Text(
                      tourPackage.tourName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10), // Adds spacing between name and agency
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Agency: ${tourPackage.agency}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // Handle edit button action
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AdminTourPackageDetailsScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName, tourID: tourPackage.tourID, countryId: widget.countryId,))
            );
          },
          icon: const Icon(Icons.remove_red_eye),
          iconSize: 20,
          color: Colors.grey.shade600,
        ),
      ],
    ),
  );
}

}

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewCarRentalDetails.dart';
import 'package:assignment_tripmate/screens/admin/homepage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageCarListScreen extends StatefulWidget{
  final String userId;

  const AdminManageCarListScreen({super.key, required this.userId});

  @override
  State<AdminManageCarListScreen> createState() => _AdminManageCarListScreenState();
}

class _AdminManageCarListScreenState extends State<AdminManageCarListScreen> {
  List<CarList> _carList = [];
  List<CarList> _foundedCar = [];
  bool isLoading = false;  // Add a loading indicator flag

  @override
  void initState() {
    super.initState();
    fetchCarList();
  }

  Future<void> fetchCarList() async {
    try {
      setState(() {
        isLoading = true;
      });
      CollectionReference carRef = FirebaseFirestore.instance.collection('car_rental');
      QuerySnapshot querySnapshot = await carRef.get();

      _carList = querySnapshot.docs.map((doc) {
        return CarList(
          doc['carID'],
          doc['carModel'],
          carImage: doc['carImage'],
          agencyName: doc['agencyName']
        );
      }).toList();

      setState(() {
        _foundedCar = _carList;
        isLoading = false;  // Stop loading when the data is fetched
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching car list: $e');
      setState(() {
        isLoading = false;  // Stop loading in case of an error
      });
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundedCar = _carList.where((carBrand) => carBrand.carModel.toUpperCase().contains(search.toUpperCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Car List"),
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
              MaterialPageRoute(builder: (context) => AdminHomepageScreen(userId: widget.userId))
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
                      hintText: "Search car ...",
                      hintStyle: TextStyle(
                        fontSize: defaultFontSize,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Display the content based on the loading state and list data
          Positioned.fill(
            child: isLoading
                ? Center(child: CircularProgressIndicator()) // Show loading indicator
                : _carList.isEmpty
                    ? Center(
                        child: Text(
                          "No car available in the system.",
                          style: TextStyle(
                            fontSize: defaultFontSize,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ) // Show message if list is empty
                    : Container(
                        padding: EdgeInsets.only(right: 10, left: 10, top:80),
                        child: ListView.builder(
                          itemCount: _foundedCar.length,
                          itemBuilder: (context, index) {
                            return carComponent(carList: _foundedCar[index]);
                          }
                        ),
                      ),
          ),
        ],
      ),
    );
  }

Widget carComponent({required CarList carList}) {
  return Container(
    // padding: EdgeInsets.only(bottom: 15, top: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Row(
            children: [
              // Image container with fixed width and height
              Container(
                width: getScreenWidth(context) * 0.25,
                height: getScreenHeight(context) * 0.11,
                margin: EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  // border: Border.all(color: primaryColor, width: 1.5),
                  image: DecorationImage(
                    image: NetworkImage(carList.carImage ?? ''),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Text widget wrapped in Expanded to take remaining space
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      carList.carModel, 
                      style: TextStyle(
                        color: Colors.black, 
                        fontWeight: FontWeight.bold, 
                        fontSize: defaultLabelFontSize,
                      ),
                      overflow: TextOverflow.ellipsis, // Ensures text doesn't overflow
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Provider: ${carList.agencyName}',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                        fontSize: defaultFontSize
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  ],
                )
                
              ),
              IconButton(
                onPressed: () {
                  // Handle edit action
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => AdminViewCarRentalDetailsScreen(userId: widget.userId, carId: carList.carID,)),
                  );
                },
                icon: Icon(Icons.remove_red_eye),
                iconSize: 20,
                color: Colors.grey.shade600,
                tooltip: "View",
              ),
            ],
          ),
        ),
      ],
    ),
  );
}



}


import "package:assignment_tripmate/screens/user/viewCountry.dart";
import "package:assignment_tripmate/screens/user/viewTourList.dart";
import "package:assignment_tripmate/utils.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class ViewCityScreen extends StatefulWidget {
  final String userId;
  final String countryName;

  const ViewCityScreen({super.key, required this.userId, required this.countryName});

  @override
  State<ViewCityScreen> createState() => _ViewCityScreenState();
}

class _ViewCityScreenState extends State<ViewCityScreen> {
  List<City> _cityList = [];
  List<City> _foundedCity = [];
  bool hasCity = false;
  bool isLoading = true;  // Add a loading indicator flag

  @override
  void initState(){
    super.initState();
    fetchCityList();
    setState(() {
      _foundedCity = _cityList;
    });
  }

  Future<void> fetchCityList() async {
    try {
      // Reference to the cities collection in Firestore
      CollectionReference citiesRef = FirebaseFirestore.instance.collection('countries').doc(widget.countryName).collection("cities");

      // Fetch the documents from the cities collection
      QuerySnapshot querySnapshot = await citiesRef.get();

      // Convert each document into a City object and add to _cityList
      _cityList = querySnapshot.docs.map((doc) {
        return City(
          doc['city_name'],
          doc['cityID'],
          doc['cityImage'],
        );
      }).toList();

      setState(() {
        _foundedCity = _cityList;
        hasCity = _foundedCity.isNotEmpty;
        isLoading = false;  // Stop loading when the data is fetched
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching city list: $e');
      setState(() {
        isLoading = false;  // Stop loading in case of an error
      });
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundedCity = _cityList.where((city) => city.cityName.toUpperCase().contains(search.toUpperCase())).toList();
    });
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
              MaterialPageRoute(builder: (context) => ViewCountryScreen(userId: widget.userId))
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
                      // fillColor: Color.fromARGB(255, 218, 232, 243),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Set the border color to black
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.blueGrey, width: 2), // Black border when not focused
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xFF467BA1), width: 2), // Black border when focused
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.red, width: 2), // Red border for error state
                      ),
                      hintText: "Search city...",
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
              padding: EdgeInsets.only(right: 10, left: 10, top: 85),
              child: ListView.builder(
                itemCount: _foundedCity.length,
                itemBuilder: (context, index) {
                  return buildCityButton(city: _foundedCity[index]);
                }
              ),
            )
          : Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  "No cities available for the selected country.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ]
      )

    );
  }

  Widget buildCityButton({required City city}) {
    return Container(
      width: double.infinity,
      height: 180,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 00),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(city.image),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => ViewTourListScreen(userId: widget.userId, countryName: widget.countryName, cityName: city.cityName,)),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white.withOpacity(0.6), // Semi-transparent overlay
                shadowColor: Colors.transparent, // No shadow
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(0),
                ),
                elevation: 10,
              ),
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                child: Text(
                  city.cityName, 
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
        ],
      ),
    );
  }
}
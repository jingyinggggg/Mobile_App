import "package:assignment_tripmate/screens/user/homepage.dart";
import "package:assignment_tripmate/screens/user/viewCity.dart";
import "package:assignment_tripmate/utils.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class ViewCountryScreen extends StatefulWidget {
  final String userId;

  const ViewCountryScreen({super.key, required this.userId});

  @override
  State<ViewCountryScreen> createState() => _ViewCountryScreenState();
}

class _ViewCountryScreenState extends State<ViewCountryScreen> {
  List<Country> _countryList = [];
  List<Country> _foundedCountry = [];

  @override
  void initState(){
    super.initState();
    fetchCountryList();
    setState(() {
      _foundedCountry = _countryList;
    });
  }

  Future<void> fetchCountryList() async {
    try {
      // Reference to the countries collection in Firestore
      CollectionReference countriesRef = FirebaseFirestore.instance.collection('countries');

      // Fetch the documents from the countries collection
      QuerySnapshot querySnapshot = await countriesRef.get();

      // Convert each document into a Country object and add to _countryList
      _countryList = querySnapshot.docs.map((doc) {
        return Country(
          doc['name'],
          doc['countryID'],
          doc['countryImage'],
        );
      }).toList();

      // Update _foundedCountry
      setState(() {
        _foundedCountry = _countryList;
      });
    } catch (e) {
      // Handle any errors
      print('Error fetching country list: $e');
    }
  }

  void onSearch(String search) {
    setState(() {
      _foundedCountry = _countryList
          .where((country) =>
              country.countryName.toUpperCase().contains(search.toUpperCase()))
          .toList();
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
              MaterialPageRoute(builder: (context) => UserHomepageScreen(userId: widget.userId))
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
                      hintText: "Search country...",
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
          Container(
            padding: const EdgeInsets.only(right: 10, left: 10, top: 100, bottom: 30),
            child: GridView.builder(
              itemCount: _foundedCountry.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // Number of columns in the grid
                crossAxisSpacing: 20.0, 
                mainAxisSpacing: 20.0,  
                childAspectRatio: 1.0,  // Aspect ratio of each item (width/height)
              ),
              itemBuilder: (context, index) {
                return buildCountryButton(country: _foundedCountry[index]);
              },
            ),
          )

        ]
      )

    );
  }

  Widget buildCountryButton({required Country country}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        image: DecorationImage(
          image: NetworkImage(country.image),
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
                  MaterialPageRoute(builder: (context) => ViewCityScreen(userId: widget.userId, countryName: country.countryName)),
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
                  country.countryName, 
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
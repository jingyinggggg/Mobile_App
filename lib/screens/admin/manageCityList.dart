import 'package:assignment_tripmate/screens/admin/addCity.dart';
import 'package:assignment_tripmate/screens/admin/adminViewTourList.dart';
import 'package:assignment_tripmate/screens/admin/editCity.dart';
import 'package:assignment_tripmate/screens/admin/manageCountryList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageCityListScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String countryId;

  const AdminManageCityListScreen({super.key, required this.userId, required this.countryName, required this.countryId});

  @override
  State<AdminManageCityListScreen> createState() => _AdminManageCityListScreenState();
}

class _AdminManageCityListScreenState extends State<AdminManageCityListScreen> {
  List<City> _cityList = [];
  List<City> _foundedCity = [];
  bool hasCity = false;
  bool isLoading = true;  // Add a loading indicator flag

  @override
  void initState() {
    super.initState();
    fetchCityList();
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

  void _confirmDeleteCity(City city) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete City'),
          content: Text('Are you sure you want to delete "${city.cityName}"?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCity(city.cityID);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCity(String cityId) async {
    try {
      // First, find the country document that matches the provided country ID
      QuerySnapshot countrySnapshot = await FirebaseFirestore.instance
          .collection('countries')
          .where('countryID', isEqualTo: widget.countryId) // Assuming widget.countryId is the ID you're looking for
          .get();

      // Check if any country documents were found
      if (countrySnapshot.docs.isNotEmpty) {
        // Get the document reference of the first matching country
        DocumentReference countryRef = countrySnapshot.docs.first.reference;

        // Reference to the country's cities collection
        CollectionReference citiesRef = countryRef.collection('cities');

        // Query to find the city document with the provided city ID
        QuerySnapshot citySnapshot = await citiesRef.where('cityID', isEqualTo: cityId).get();

        // Debug: Log the number of documents found
        print('Number of cities found: ${citySnapshot.docs.length}');

        // Check if any city documents were found
        if (citySnapshot.docs.isNotEmpty) {
          // Get the document reference of the first matching city
          DocumentReference cityRef = citySnapshot.docs.first.reference;

          // Debug: Log the document ID being deleted
          print('Deleting city document with ID: ${cityRef.id}');

          // Delete the city document from Firestore
          await cityRef.delete();

          setState(() {
            // Remove the city from the list
            _cityList.removeWhere((city) => city.cityID == cityId); 
            _foundedCity.removeWhere((city) => city.cityID == cityId); // Adjust if needed
            hasCity = _foundedCity.isNotEmpty;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('City with ID $cityId has been deleted.')),
          );
        } else {
          // Handle case where no city was found
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No city found with ID $cityId.')),
          );
        }
      } else {
        // Handle case where no country was found
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No country found with ID ${widget.countryId}.')),
        );
      }
    } catch (e) {
      // Debug: Log the error for more information
      print('Error deleting city: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete city with ID $cityId.')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("City List"),
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
              MaterialPageRoute(builder: (context) => AdminManageCountryListScreen(userId: widget.userId))
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
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => AdminAddCityScreen(userId: widget.userId, country: widget.countryName, countryId: widget.countryId,))
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
                        "Add City",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          isLoading
          ? Center(child: CircularProgressIndicator())  // Show loading indicator while fetching data
          : hasCity
          ? Container(
              padding: EdgeInsets.only(right: 10, left: 15, top: 140),
              child: ListView.builder(
                itemCount: _foundedCity.length,
                itemBuilder: (context, index) {
                  return cityComponent(city: _foundedCity[index]);
                }
              ),
            )
          : Container(
              alignment: Alignment.center,
              child: Center(
                child: Text(
                  "No cities available for the selected country.",
                  style: TextStyle(
                    fontSize: 14,
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

  Widget cityComponent({required City city}) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      padding: EdgeInsets.only(bottom: 15, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: screenWidth * 0.25,
                height: screenHeight * 0.1,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(0),
                  image: DecorationImage(
                    image: NetworkImage(city.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Text(
                city.cityName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: null,
                overflow: TextOverflow.visible,
              ),
            ],
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                child: IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminViewTourListScreen(
                          userId: widget.userId,
                          countryName: widget.countryName,
                          cityName: city.cityName,
                          countryId: widget.countryId,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.remove_red_eye),
                  iconSize: 20,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                width: 30,
                child: IconButton(
                onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdminEditCityScreen(
                          userId: widget.userId,
                          country: widget.countryName,
                          cityName: city.cityName,
                          countryId: widget.countryId,
                          cityId: city.cityID,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.edit_document),
                  iconSize: 20,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                width: 30,
                child: IconButton(
                  onPressed: () => _confirmDeleteCity(city),
                  icon: Icon(Icons.delete, color: Colors.grey.shade600),
                  iconSize: 20,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

import 'package:assignment_tripmate/screens/admin/addCountry.dart';
import 'package:assignment_tripmate/screens/admin/editCountry.dart';
import 'package:assignment_tripmate/screens/admin/homepage.dart';
import 'package:assignment_tripmate/screens/admin/manageCityList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageCountryListScreen extends StatefulWidget {
  final String userId;

  const AdminManageCountryListScreen({super.key, required this.userId});

  @override
  State<AdminManageCountryListScreen> createState() => _AdminManageCountryListScreenState();
}

class _AdminManageCountryListScreenState extends State<AdminManageCountryListScreen> {
  List<Country> _countryList = [];
  List<Country> _foundedCountry = [];

  @override
  void initState() {
    super.initState();
    fetchCountryList();
    setState(() {
      _foundedCountry = _countryList;
    });
  }

  Future<void> fetchCountryList() async {
    try {
      CollectionReference countriesRef = FirebaseFirestore.instance.collection('countries');
      QuerySnapshot querySnapshot = await countriesRef.get();
      _countryList = querySnapshot.docs.map((doc) {
        return Country(
          doc['name'],
          doc['countryID'],
          doc['countryImage'],
        );
      }).toList();

      setState(() {
        _foundedCountry = _countryList;
      });
    } catch (e) {
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

  // Method to show confirmation dialog before deletion
  Future<void> confirmDeleteCountry(String countryID) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this country?"),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                deleteCountry(countryID); // Call delete method
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Method to delete a country
  Future<void> deleteCountry(String countryID) async {
    try {
      // Query to find the document with the matching countryID field
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('countries')
          .where('countryID', isEqualTo: countryID)
          .limit(1) // Limit to one result as we expect unique countryIDs
          .get();

      if (snapshot.docs.isNotEmpty) {
        // Get the document ID of the matching document
        String docId = snapshot.docs.first.id;

        // Delete the document by its document ID
        await FirebaseFirestore.instance.collection('countries').doc(docId).delete();

        setState(() {
          _countryList.removeWhere((country) => country.countryID == countryID);
          _foundedCountry = _countryList;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Country deleted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Country not found')),
        );
      }
    } catch (e) {
      print('Error deleting country: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete country')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Country List"),
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
              Padding(
                padding: const EdgeInsets.only(right: 10.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => AdminAddCountryScreen(userId: widget.userId))
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
                        "Add Country",
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
          Container(
            padding: EdgeInsets.only(right: 10, left: 15, top:140),
            child: ListView.builder(
              itemCount: _foundedCountry.length,
              itemBuilder: (context, index) {
                return countryComponent(country: _foundedCountry[index]);
              }
            ),
          ),
        ]
      )
    );
  }

  Widget countryComponent({required Country country}) {
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
                    image: NetworkImage(country.image),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 20),
              Text(
                country.countryName,
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
                      MaterialPageRoute(builder: (context) => AdminManageCityListScreen(userId: widget.userId, countryName: country.countryName, countryId: country.countryID,))
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
                      MaterialPageRoute(builder: (context) => AdminEditCountryScreen(userId: widget.userId, countryName: country.countryName, countryId: country.countryID))
                    );
                  }, 
                  icon: Icon(Icons.edit),
                  iconSize: 20,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                width: 30,
                child: IconButton(
                  onPressed: () {
                    confirmDeleteCountry(country.countryID);
                  }, 
                  icon: Icon(Icons.delete),
                  iconSize: 20,
                  color: Colors.grey.shade600,
                ),
              )
            ],
          ),
        ],
      ),
    );
  }
}

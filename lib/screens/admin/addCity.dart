import 'dart:typed_data';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/admin/manageCityList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAddCityScreen extends StatefulWidget {
  final String userId;
  final String country;
  final String countryId;

  const AdminAddCityScreen({super.key, required this.userId, required this.country, required this.countryId});

  @override
  State<AdminAddCityScreen> createState() => _AdminAddCityScreenState();
}

class _AdminAddCityScreenState extends State<AdminAddCityScreen> {
  bool _isLoading = false;
  Uint8List? _image;
  String? previewCityName = "";

  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController(); // Controller for the image file name

  @override
  void dispose() {
    _cityNameController.dispose();
    _imageNameController.dispose();
    super.dispose();
  }

  void selectImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _image = img;
        _imageNameController.text = 'Image Selected'; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Add City"),
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
              MaterialPageRoute(builder: (context) => AdminManageCityListScreen(userId: widget.userId, countryName: widget.country, countryId: widget.countryId,))
            );
          },
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                cityName(),
                const SizedBox(height: 20),
                cityImage(),
                const SizedBox(height: 20),
                const Text(
                  "Preview:",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 10),
                previewWidget(), // Add this line to show the preview
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _addCity();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF467BA1),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      minimumSize: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height * 0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Add',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget cityName() {
    return TextField(
      controller: _cityNameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      onChanged: (value) {
        setState(() {
          _cityNameController.text = value.toUpperCase(); // Convert input to uppercase
          _cityNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _cityNameController.text.length), // Keep the cursor at the end
          );
          previewCityName = _cityNameController.text;
        });
      },
      decoration: InputDecoration(
        hintText: 'Enter City Name',
        labelText: 'City Name',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          shadows: [
            Shadow(
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
      ),
    );
  }

  Widget cityImage() {
    return TextField(
      controller: _imageNameController,
      readOnly: true,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black54
      ),
      decoration: InputDecoration(
        hintText: 'Upload an image...',
        labelText: 'City Image',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF467BA1),
            width: 2.5,
          ),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        labelStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
          shadows: [
            Shadow(
              offset: Offset(0.5, 0.5),
              color: Colors.black87,
            ),
          ],
        ),
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.image,
            color: Color(0xFF467BA1),
            size: 25,
          ),
          onPressed: () {
            selectImage();
          }
        ),
      ),
    );
  }

  Widget previewWidget() {
    if (_image == null || _cityNameController.text.isEmpty) {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                'Insert name and image to preview',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: MemoryImage(_image!),
            fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Centered overlay container
            Align(
              alignment: Alignment.center,
              child: Container(
                width: double.infinity,  // Adjust width as needed
                height: 50, // Adjust height as needed
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.5), // Semi-transparent overlay
                ),
                child: Center(
                  child: Text(
                    _cityNameController.text, 
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 18,
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

  Future<void> _addCity() async {
    if (_cityNameController.text.isEmpty || _image == null) {
      _showDialog(
        title: 'Failed',
        content: 'Please make sure you have inserted the city name and uploaded an image!',
        onPressed: () {
          Navigator.of(context).pop(); // Close the dialog
        },
      );
      return; // Exit the method early
    }

    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      // Get the list of existing city IDs
      final citiesSnapshot = await FirebaseFirestore.instance
          .collection('countries')
          .doc(widget.country)
          .collection('cities')
          .get();

      List<String> existingCityIDs = citiesSnapshot.docs
        .map((doc) => doc.data()['cityID'] as String) // Extract cityID field
        .toList();

      // Debug: Log the existing city IDs
      print('Existing City IDs: $existingCityIDs');

      // Generate new city ID using the existing IDs
      final newCityID = _generateNewCityID(existingCityIDs);

      // Debug: Log the newly generated city ID
      print('Generated New City ID: $newCityID');

      // Save the city data
      String resp = await StoreData().saveCityData(
        country: widget.country,
        city: _cityNameController.text,
        cityID: newCityID, // Use the generated ID
        file: _image!,
        type: 0,
      );

      // Show success dialog
      _showDialog(
        title: 'Successful',
        content: 'The city has been added successfully.',
        onPressed: () {
          Navigator.of(context).pop(); // Close the success dialog
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminManageCityListScreen(userId: widget.userId, countryName: widget.country, countryId: widget.countryId,)),
          );
        },
      );
    } catch (e) {
      // Handle errors
      _showDialog(
        title: 'Failed',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop(); // Close the error dialog
        },
      );
    } finally {
      setState(() {
        _isLoading = false; // Stop loading
      });
    }
  }

  String _generateNewCityID(List<String> existingIDs) {
    // Extract numeric parts from existing IDs and convert to integers
    List<int> numericIDs = existingIDs
        .map((id) {
          // Ensure the ID is in the expected format "CTJAPANxxxx"
          final match = RegExp(r'CTJAPAN(\d{4})').firstMatch(id);
          return match != null ? int.parse(match.group(1)!) : 0; // Convert "CTJAPANxxxx" to xxxx
        })
        .toList();

    // Find the highest ID
    int maxID = numericIDs.isNotEmpty ? numericIDs.reduce((a, b) => a > b ? a : b) : 0;

    // Generate new ID
    return 'CTJAPAN${(maxID + 1).toString().padLeft(4, '0')}'; // Ensure it has leading zeros
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
}

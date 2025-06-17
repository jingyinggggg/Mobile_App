import 'dart:typed_data';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/admin/manageCountryList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminAddCountryScreen extends StatefulWidget {
  final String userId;

  const AdminAddCountryScreen({super.key, required this.userId});

  @override
  State<AdminAddCountryScreen> createState() => _AdminAddCountryScreenState();
}

class _AdminAddCountryScreenState extends State<AdminAddCountryScreen> {
  bool _isLoading = false;
  Uint8List? _image;
  String? previewCountryName = "";

  final TextEditingController _countryNameController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController(); // Controller for the image file name

  @override
  void dispose() {
    _countryNameController.dispose();
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
        title: const Text("Add Country"),
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
            Navigator.pop(context);
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
                countryName(),
                const SizedBox(height: 20),
                countryImage(),
                const SizedBox(height: 20),
                const Text(
                  "Preview:",
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
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
                      _addCountry();
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

  Widget countryName() {
    return TextField(
      controller: _countryNameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      onChanged: (value) {
        setState(() {
          _countryNameController.text = value.toUpperCase(); // Convert input to uppercase
          _countryNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _countryNameController.text.length), // Keep the cursor at the end
          );
          previewCountryName = _countryNameController.text;
        });
      },
      decoration: InputDecoration(
        hintText: 'Enter Country Name',
        labelText: 'Country Name',
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

  Widget countryImage() {
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
        labelText: 'Country Image',
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
    if (_image == null || _countryNameController.text.isEmpty) {
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
                    previewCountryName!, 
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

    Future<void> _addCountry() async {
    if (_countryNameController.text.isEmpty || _image == null) {
      _showDialog(
        title: 'Failed',
        content: 'Please make sure you have inserted the country name and uploaded an image!',
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
      // Get all existing countries
      final countriesSnapshot = await FirebaseFirestore.instance.collection('countries').get();

      // List to hold country IDs
      // List<String> countryIDs = [];

      List<String> existingCountryIDs = countriesSnapshot.docs
        .map((doc) => doc.data()['countryID'] as String) // Extract cityID field
        .toList();

      // Generate new country ID
      String newCountryID = _generateNewCountryID(existingCountryIDs);

      // Save the country data
      String resp = await StoreData().saveCountryData(
        country: _countryNameController.text,
        countryID: newCountryID, // Use the generated ID
        file: _image!,
        type: 0
      );

      // Show success dialog
      _showDialog(
        title: 'Successful',
        content: 'The country has been added successfully.',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => AdminManageCountryListScreen(userId: widget.userId)),
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

  String _generateNewCountryID(List<String> existingIDs) {
    // Extract numeric parts from existing IDs and convert to integers
    List<int> numericIDs = existingIDs
        .map((id) {
          final match = RegExp(r'C(\d{4})').firstMatch(id);
          return match != null ? int.parse(match.group(1)!) : 0; // Convert "CTJAPANxxxx" to xxxx
        })
        .toList();

    // Find the highest ID
    int maxID = numericIDs.isNotEmpty ? numericIDs.reduce((a, b) => a > b ? a : b) : 0;

    // Generate new ID
    return 'C${(maxID + 1).toString().padLeft(4, '0')}'; // Ensure it has leading zeros
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

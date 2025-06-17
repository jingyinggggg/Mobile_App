import 'dart:typed_data';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/admin/manageCountryList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminEditCountryScreen extends StatefulWidget {
  final String countryId;
  final String countryName;
  final String userId;

  const AdminEditCountryScreen({
    super.key,
    required this.countryId,
    required this.countryName,
    required this.userId,
  });

  @override
  State<AdminEditCountryScreen> createState() => _AdminEditCountryScreenState();
}

class _AdminEditCountryScreenState extends State<AdminEditCountryScreen> {
  bool _isLoading = false;
  Uint8List? _image;
  String? previewCountryName = "";
  String? existingImageUrl;

  final TextEditingController _countryNameController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _countryNameController.text = widget.countryName;
    previewCountryName = widget.countryName;
    fetchCountryImage();
  }

  @override
  void dispose() {
    _countryNameController.dispose();
    _imageNameController.dispose();
    super.dispose();
  }

  void fetchCountryImage() async {
    // Retrieve existing image URL from Firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('countries')
        .doc(widget.countryName)
        .get();
    setState(() {
      existingImageUrl = doc['countryImage'];
    });
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
        title: const Text("Edit Country"),
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
                previewWidget(),
                const SizedBox(height: 30),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(),
                  )
                else
                  ElevatedButton(
                    onPressed: () {
                      _updateCountry();
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
                      'Update',
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
          previewCountryName = value.toUpperCase();
          _countryNameController.text = previewCountryName!;
          _countryNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _countryNameController.text.length),
          );
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
        color: Colors.black54,
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
        suffixIcon: IconButton(
          icon: const Icon(
            Icons.image,
            color: Color(0xFF467BA1),
            size: 25,
          ),
          onPressed: () {
            selectImage();
          },
        ),
      ),
    );
  }

  Widget previewWidget() {
    if (_image == null && existingImageUrl == null) {
      return placeholderPreview();
    } else {
      return Container(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.3,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            image: _image != null ? MemoryImage(_image!) : NetworkImage(existingImageUrl!) as ImageProvider,
            fit: BoxFit.cover,
          ),
        ),
        child: overlayText(),
      );
    }
  }

  Widget placeholderPreview() {
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
              style: TextStyle(color: Colors.black87, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget overlayText() {
    return Stack(
      children: [
        Align(
          alignment: Alignment.center,
          child: Container(
            width: double.infinity,
            height: 50,
            color: Colors.white.withOpacity(0.5),
            child: Center(
              child: Text(
                previewCountryName!,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateCountry() async {
    if (_countryNameController.text.isEmpty) {
      _showDialog(
        title: 'Failed',
        content: 'Please insert the country name and upload an image!',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      Uint8List? imageToUpload;

      // Check if a new image was selected
      if (_image != null) {
        imageToUpload = _image; // Use the selected image
      } else if (existingImageUrl != null) {
        // Fetch the existing image from the URL
        imageToUpload = await _fetchImageFromUrl(existingImageUrl!);
      }

      // Update country data
      await StoreData().saveCountryData(
        countryID: widget.countryId,
        country: _countryNameController.text,
        file: imageToUpload!, // Pass the image to upload (new or existing)
        type: 1,
      );

      _showDialog(
        title: 'Successful',
        content: 'The country has been updated successfully.',
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminManageCountryListScreen(userId: widget.userId),
            ),
          );
        },
      );
    } catch (e) {
      _showDialog(
        title: 'Failed',
        content: 'An error occurred: $e',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to fetch image from URL and convert to Uint8List
  Future<Uint8List?> _fetchImageFromUrl(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        return response.bodyBytes; // Return the bytes of the image
      }
    } catch (e) {
      print('Error fetching image from URL: $e');
    }
    return null; // Return null if there's an error
  }


  void _showDialog({
    required String title,
    required String content,
    VoidCallback? onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: onPressed ?? () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

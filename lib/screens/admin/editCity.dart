import 'dart:typed_data';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/admin/manageCityList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminEditCityScreen extends StatefulWidget {
  final String userId;
  final String country;
  final String cityId;
  final String cityName;
  final String countryId;

  const AdminEditCityScreen({super.key, required this.userId, required this.country, required this.cityId, required this.countryId, required this.cityName});

  @override
  State<AdminEditCityScreen> createState() => _AdminEditCityScreenState();
}

class _AdminEditCityScreenState extends State<AdminEditCityScreen> {
  bool _isLoading = false;
  Uint8List? _image;
  String? previewCityName = "";
  String? existingImageUrl;

  final TextEditingController _cityNameController = TextEditingController();
  final TextEditingController _imageNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityNameController.text = widget.cityName;
    previewCityName = widget.cityName;
    fetchCityImage();
  }

  @override
  void dispose() {
    _cityNameController.dispose();
    _imageNameController.dispose();
    super.dispose();
  }

  void fetchCityImage() async {
    // Retrieve existing image URL from Firestore
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('countries')
        .doc(widget.country)
        .collection('cities')
        .doc(widget.cityName)
        .get();
    setState(() {
      existingImageUrl = doc['cityImage'];
    });
  }

  void selectImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _image = img;
        _imageNameController.text = 'New Image Selected';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Edit City"),
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
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
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
                  previewWidget(),
                  const SizedBox(height: 30),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        _updateCity();
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
                        'Save Changes',
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
          previewCityName = value.toUpperCase();
          _cityNameController.text = previewCityName!;
          _cityNameController.selection = TextSelection.fromPosition(
            TextPosition(offset: _cityNameController.text.length),
          );
        });
      },
      decoration: InputDecoration(
        hintText: 'Edit City Name',
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
        floatingLabelBehavior: FloatingLabelBehavior.always,
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
        hintText: 'Upload a new image...',
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
                previewCityName!,
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

  Future<void> _updateCity() async {
    if (_cityNameController.text.isEmpty) {
      _showDialog(
        title: 'Failed',
        content: 'Please make sure you have inserted the city name!',
        onPressed: () {
          Navigator.of(context).pop();
        },
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

      await StoreData().saveCityData(
        country: widget.country,
        city: _cityNameController.text,
        cityID: widget.cityId,
        file: imageToUpload!,
        type: 1, // Use type 1 if no new image selected
      );

      _showDialog(
        title: 'Success',
        content: 'City updated successfully!',
        onPressed: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminManageCityListScreen(userId: widget.userId, countryName: widget.country, countryId: widget.countryId,),
            ),
          );
        },
      );
    } catch (e) {
      _showDialog(
        title: 'Failed',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  void _showDialog({required String title, required String content, required VoidCallback onPressed}) {
    showDialog(
      context: context,
      builder: (context) {
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

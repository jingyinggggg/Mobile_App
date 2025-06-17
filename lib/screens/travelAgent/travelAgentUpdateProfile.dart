import 'dart:typed_data';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentHomepage.dart';
import 'package:http/http.dart' as http;
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TravelAgentUpdateProfileScreen extends StatefulWidget {
  final String userId;

  const TravelAgentUpdateProfileScreen({super.key, required this.userId});

  @override
  State<TravelAgentUpdateProfileScreen> createState() => _TravelAgentUpdateProfileScreenState();
}

class _TravelAgentUpdateProfileScreenState extends State<TravelAgentUpdateProfileScreen> {
  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _companyNameController = TextEditingController();
  TextEditingController _companyContactController = TextEditingController();
  TextEditingController _companyAddressController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  String? existingProfielURL;
  Uint8List? _image;
  bool isUpdating = false;
  bool _isDataInitialized = false;
  
  Uint8List? _employeeCardImage;
  String? existingImagePath;
  int? accountStatus;

  @override
  void initState() {
    super.initState();
    _fetchTravelAgentData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _companyContactController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  void selectImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _image = img;
      });
    }
  }

  Future<void> _selectEmployeeCardImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _employeeCardImage = img;
        existingImagePath = null;
      });
    }
  }

  Future<void> _fetchTravelAgentData() async{
    setState(() {
      _isDataInitialized = true;
    });
    try{
      DocumentReference TARef = FirebaseFirestore.instance.collection('travelAgent').doc(widget.userId);
      DocumentSnapshot TASnapshot = await TARef.get();

      if(TASnapshot.exists){
        Map<String, dynamic>? data = TASnapshot.data() as Map<String, dynamic>?;

        setState(() {
          _isDataInitialized = false;

          _nameController.text = data?['name'] ?? '';
          _usernameController.text = data?['username'] ?? '';
          _emailController.text = data?['email'] ?? '';
          _selectedDate = data?['dob'].toDate() ?? '';
          _selectedGender = data?['gender'] ?? '';
          _companyNameController.text = data?['companyName'] ?? '';
          _companyContactController.text = data?['companyContact'] ?? '';
          _companyAddressController.text = data?['companyAddress'] ?? '';
          existingProfielURL = data?['profileImage'] ?? null;
          existingImagePath = data?['employeeCardPath'] ?? null;
          accountStatus = data?['accountApproved'] ?? null;
        });
      } else{
        setState(() {
          _isDataInitialized = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current travel agent does not exists in the system')),
          );
        });
      }
    } catch(e){
        setState(() {
          _isDataInitialized = false;
        });
        print("Error fetch travel agent details: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Update Profile"),
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
              if (!_isDataInitialized)
                Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("images/account_background.png"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: double.infinity,
                  width: double.infinity,
                  color: const Color(0xFFEDF2F6).withOpacity(0.6),
                ),
                SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 20, left: 10, right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 30),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                _image != null
                                    ? CircleAvatar(
                                        radius: 64,
                                        backgroundImage: MemoryImage(_image!),
                                      )
                                    : existingProfielURL != null
                                        ? CircleAvatar(
                                            radius: 64,
                                            backgroundImage: NetworkImage(existingProfielURL!),
                                          )
                                        : const CircleAvatar(
                                            radius: 64,
                                            backgroundImage: AssetImage("images/profile.png"),
                                            backgroundColor: Colors.white,
                                          ),
                                Positioned(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.add_a_photo,
                                      color: Colors.black,
                                    ),
                                    onPressed: selectImage,
                                  ),
                                  bottom: -13,
                                  left: 80,
                                ),
                              ],
                            ),
                            const SizedBox(height: 40),
                            username(),
                            const SizedBox(height: 20),
                            name(),
                            const SizedBox(height: 20),
                            email(),
                            const SizedBox(height: 20),
                            dob(),
                            const SizedBox(height: 20),
                            gender(),
                            const SizedBox(height: 20),
                            companyName(),
                            const SizedBox(height: 20),
                            companyContact(),
                            const SizedBox(height: 20),
                            companyAddress(),
                            const SizedBox(height: 10),
                            employeeCardImage(),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity, // This makes the button take up the full width
                              child: ElevatedButton(
                                onPressed: isUpdating ? null : _updateProfile,
                                child: const Text(
                                  'Update',
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF467BA1),
                                  padding: const EdgeInsets.symmetric(vertical: 15), // You can remove horizontal padding to avoid shrinking
                                  textStyle: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUpdating) // Display the loading indicator if isUpdating is true
                  Center(
                    child: Container(
                      // color: Colors.black.withOpacity(0.5), // Optional: semi-transparent background
                      child: const CircularProgressIndicator(),
                    ),
                  ),
              if(_isDataInitialized)
                Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          )
      );
    }

  Widget name() {
    return TextField(
      controller: _nameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black
      ),
      decoration: InputDecoration(
        hintText: 'Please update your name...',
        labelText: 'Name',
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

  Widget username() {
    return TextField(
      controller: _usernameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      maxLength: 12,
      decoration: InputDecoration(
        hintText: 'Please update your username...',
        labelText: 'Username',
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

  Widget email() {
    return TextField(
      controller: _emailController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Please update your email...',
        labelText: 'Email',
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

  Widget companyName() {
    return TextField(
      controller: _companyNameController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Please update company name...',
        labelText: 'Company Name',
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

  Widget companyContact() {
    return TextField(
      controller: _companyContactController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: 'Please update company contact...',
        labelText: 'Company Contact',
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

  Widget companyAddress() {
    return TextField(
      controller: _companyAddressController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: 'Please update company address...',
        labelText: 'Company Address',
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
      keyboardType: TextInputType.multiline,
      maxLines: null, 
    );
  }

  Widget gender() {
    return TextFormField(
      readOnly: true,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: 14,
        color: Colors.black54
      ),
      decoration: InputDecoration(
        labelText: 'Gender',
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
      controller: TextEditingController(
        text: _selectedGender ?? 'Not Specified',
      ),
    );
  }

  Widget dob() {
    return Padding(
      padding: const EdgeInsets.only(top: 0), // Adjust padding as needed
      child: TextFormField(
        readOnly: true,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: Colors.black54
        ),
        decoration: InputDecoration(
          hintText: 'Date of Birth',
          labelText: 'Date of Birth',
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
        controller: TextEditingController(
          text: _selectedDate != null
              ? DateFormat('dd/MM/yyyy').format(_selectedDate!)
              : 'Select Date of Birth',
        ),
      ),
    );
  }

  
  Widget employeeCardImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Employee Card",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () async {
                // Select a new image
                await _selectEmployeeCardImage();
              },
              icon: const Icon(
                Icons.edit,
                size: 25,
                color: Color(0xFF467BA1),
              ),
            ),
          ],
        ),
        _employeeCardImage != null // If a new image is selected from memory
          ? Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF467BA1), width: 3),
              ),
              child: Image.memory(
                _employeeCardImage!,
                fit: BoxFit.cover,
              ),
            )
          : (existingImagePath != null && existingImagePath!.isNotEmpty)
            ? Container( // If there's a network image to display
                width: double.infinity,
                height: 200,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF467BA1), width: 3),
                ),
                child: Image.network(
                  existingImagePath!,
                  fit: BoxFit.cover,
                ),
              )
            : Container( // Placeholder if no image is available
                width: double.infinity,
                height: 200,
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
                        'Insert employee card to preview',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
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

  Future<void> _updateProfile() async {
    if (_usernameController.text.isEmpty) {
      showSnackBar("Username cannot be empty", context);
      return;
    }
    if (_nameController.text.isEmpty) {
      showSnackBar("Name cannot be empty", context);
      return;
    }

    setState(() {
      isUpdating = true; // Start loading
    });

    try {
      // Fetch the current user's data from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('travelAgent')
          .doc(widget.userId) // Assuming `widget.userId` is the current user's ID
          .get();

      // Get the profile image URL from the fetched user data
      String? existingProfileURL = userDoc['profileImage'] ?? '';
      String? existingEmployeeCardURL = userDoc['employeeCardPath'] ?? '';

      Uint8List? profileImageToUpload;
      Uint8List? employeeCardToUpload;

      // Check if a new image is selected (_image is not null)
      if (_image != null) {
        profileImageToUpload = _image!;
      } else if (existingProfileURL != null && existingProfileURL.isNotEmpty) {
        // If no new image is selected, use the existing profile image URL
        profileImageToUpload = await _getImageFromURL(existingProfileURL);
      }

      if(_employeeCardImage != null){
        employeeCardToUpload = _employeeCardImage!;
      } else if (existingEmployeeCardURL != null && existingEmployeeCardURL.isNotEmpty){
        employeeCardToUpload = await _getImageFromURL(existingEmployeeCardURL);
      }

      if (_nameController.text.isNotEmpty && 
          _usernameController.text.isNotEmpty && 
          _emailController.text.isNotEmpty &&
          _companyNameController.text.isNotEmpty && 
          _companyContactController.text.isNotEmpty && 
          _companyAddressController.text.isNotEmpty) {
        
        // Update the profile data in Firestore
        String resp = await StoreData().updateTravelAgentProfile(
          userId: widget.userId, 
          name: _nameController.text, 
          username: _usernameController.text, 
          email: _emailController.text, 
          companyName: _companyNameController.text,
          companyContact: _companyContactController.text, 
          companyAddress: _companyAddressController.text, 
          file: profileImageToUpload, // Use the selected or existing image
          employeeCard: employeeCardToUpload,
          accountStatus: accountStatus == 2 || accountStatus == 0 ? 0 : 1
        );

        if(accountStatus == 2){
          // Show success dialog
          _showDialog(
            title: 'Update Successful',
            content: 'Your details have been updated successfully.',
            onPressed: () {
              Navigator.of(context).pop(); // Close the success dialog
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => TravelAgentHomepageScreen(userId: widget.userId))
              );
            },
          );
        } else{
          // Show success dialog
          _showDialog(
            title: 'Update Successful',
            content: 'Your details have been updated successfully.',
            onPressed: () {
              Navigator.of(context).pop(); // Close the success dialog
              Navigator.of(context).pop();
            },
          );
        }

        
      }
    } catch (e) {
      // Handle errors
      _showDialog(
        title: 'Update Failed',
        content: 'An error occurred: $e',
        onPressed: () {
          Navigator.of(context).pop(); // Close the error dialog
        },
      );
    } finally {
      setState(() {
        isUpdating = false; // Stop loading
      });
    }
  }

  // Helper function to download the existing image from a URL and convert it to Uint8List
  Future<Uint8List> _getImageFromURL(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

}
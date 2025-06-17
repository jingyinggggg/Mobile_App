import 'dart:convert';

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/manageUserList.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AdminManageUserDetailsScreen extends StatefulWidget {
  final String userId;
  final String userListID;
  final String type;
  final String? localBuddyId;
  final String? localBuddyname;

  const AdminManageUserDetailsScreen({
    super.key,
    required this.userId,
    required this.userListID,
    required this.type,
    this.localBuddyId,
    this.localBuddyname
  });

  @override
  State<StatefulWidget> createState() => _AdminManageUserDetailsScreenState();
}

class _AdminManageUserDetailsScreenState extends State<AdminManageUserDetailsScreen> {
  bool isFetching = false;
  bool isUpdating = false;
  Map<String, dynamic> userData = {};
  List<String> genderType = ['Male', 'Female'];

  // User
  late TextEditingController nameController;
  late TextEditingController usernameController;
  late TextEditingController contactController;
  late TextEditingController emailController;
  late TextEditingController addressController;
  DateTime? _selectedDate;
  String? _selectedGender;

  // TA
  late TextEditingController companyNameController;
  late TextEditingController companyAddressController;
  late TextEditingController companyContactController;

  // LB
  late TextEditingController occupationController;
  late TextEditingController buddyLocationController;
  late TextEditingController languageSpokenController;
  late TextEditingController priceController;
  late TextEditingController bioController;
  List<String> selectedDays = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchUserDetails();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    contactController.dispose();
    emailController.dispose();
    addressController.dispose();
    companyNameController.dispose();
    companyAddressController.dispose();
    companyContactController.dispose();
    occupationController.dispose();
    buddyLocationController.dispose();
    languageSpokenController.dispose();
    priceController.dispose();
    bioController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    nameController = TextEditingController();
    usernameController = TextEditingController();
    contactController = TextEditingController();
    emailController = TextEditingController();
    addressController = TextEditingController();
    companyNameController = TextEditingController();
    companyAddressController = TextEditingController();
    companyContactController = TextEditingController();
    occupationController = TextEditingController();
    buddyLocationController = TextEditingController();
    languageSpokenController = TextEditingController();
    priceController = TextEditingController();
    bioController = TextEditingController();
  }

  Future<void> _fetchUserDetails() async {
    setState(() {
      isFetching = true;
    });
    try {
      DocumentReference reference;
      if (widget.type == "user") {
        reference = FirebaseFirestore.instance.collection('users').doc(widget.userListID);
      } else if (widget.type == "ta") {
        reference = FirebaseFirestore.instance.collection('travelAgent').doc(widget.userListID);
      } else {
        reference = FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyId!);
      }

      DocumentSnapshot snapshot = await reference.get();
      if (snapshot.exists) {
        userData = snapshot.data() as Map<String, dynamic>;

        // Print the userData to inspect the fetched data
        if (widget.type == "lb") {
          print("Fetched Local Buddy Data: $userData");
        }

        setState(() {
          if (widget.type == "lb") {
            occupationController.text = userData['occupation'] ?? '';
            buddyLocationController.text = userData['location'] ?? '';
            languageSpokenController.text = userData['languageSpoken'] ?? '';
            priceController.text = (userData['price'] ?? '0').toString();
            bioController.text = userData['bio'] ?? '';

            if (userData['availability'] is List) {
              selectedDays = (userData['availability'] as List<dynamic>)
                  .map((item) => item['day']?.toString() ?? '') // Handle potential null values here
                  .toList();
            } else {
              selectedDays = []; // Default to an empty list if not available or not a List
            }
          } else {
            nameController.text = userData['name'] ?? '';
            usernameController.text = userData['username'] ?? '';
            emailController.text = userData['email'] ?? '';
            _selectedGender = userData['gender'] ?? '';

            // Check if 'dob' is non-null before calling .toDate()
            _selectedDate = userData['dob'] != null ? userData['dob'].toDate() : null;

            if (widget.type == "user") {
              addressController.text = userData['address'] ?? '';
              contactController.text = userData['contact'] ?? '';
            } else if (widget.type == "ta") {
              companyNameController.text = userData['companyName'] ?? '';
              companyAddressController.text = userData['companyAddress'] ?? '';
              companyContactController.text = userData['companyContact'] ?? '';
            }
          }
        });
      } else {
        print("No data found for the specified document.");
      }
    } catch (e) {
      print('Error fetching user details: $e');
    } finally {
      setState(() {
        isFetching = false;
      });
    }
  }

  void toggleDaySelection(String day) {
    setState(() {
      if (selectedDays.contains(day)) {
        selectedDays.remove(day); // Unselect the day
      } else {
        selectedDays.add(day); // Select the day
      }
    });
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2006, 12, 31),
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(2006, 12, 31),
      builder: (BuildContext context, Widget? child) {
        return ScrollConfiguration(
          behavior: ScrollBehavior(),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  Future<void>_updateData() async{
    setState(() {
      isUpdating = true;
    });
    try{
      if(widget.type == "lb"){

        if(occupationController.text.isNotEmpty && buddyLocationController.text.isNotEmpty && languageSpokenController.text.isNotEmpty && priceController.text.isNotEmpty && bioController.text.isNotEmpty && selectedDays.isNotEmpty){
          List<Map<String, dynamic>> availability = selectedDays.map((day) {
            return {
              'day': day,
            };
          }).toList();

          var locationData = await _getLocationAreaAndCountry(buddyLocationController.text);
          String? country = locationData['country'];
          String? area = locationData['area'];

          String locationArea = '$area, $country';

          await FirebaseFirestore.instance.collection('localBuddy').doc(widget.localBuddyId).update({
            'occupaction': occupationController.text,
            'location': buddyLocationController.text,
            'locationArea': locationArea,
            'languageSpoken': languageSpokenController.text,
            'price': int.tryParse(priceController.text) ?? 0,
            'bio': bioController.text,
            'availability': availability
          });

          showCustomDialog(
            context: context, 
            title: "Success", 
            content: "Local buddy data has been updated successfully.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        } else{
          showCustomDialog(
            context: context, 
            title: "Failed", 
            content: "Please make sure you have fill in all details.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        }
      } else if (widget.type == "user"){
        if(nameController.text.isNotEmpty && usernameController.text.isNotEmpty && contactController.text.isNotEmpty && emailController.text.isNotEmpty && _selectedDate != null && _selectedGender != null && addressController.text.isNotEmpty){
          await FirebaseFirestore.instance.collection('users').doc(widget.userListID).update({
            'name': nameController.text,
            'username': usernameController.text,
            'contact': contactController.text,
            'email': emailController.text,
            'gender': _selectedGender,
            'dob': _selectedDate,
            'address': addressController.text
          });

          showCustomDialog(
            context: context, 
            title: "Success", 
            content: "User data has been updated successfully.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        } else{
          showCustomDialog(
            context: context, 
            title: "Failed", 
            content: "Please make sure you have fill in all details.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        }
      } else{
        if(nameController.text.isNotEmpty && usernameController.text.isNotEmpty && companyContactController.text.isNotEmpty && emailController.text.isNotEmpty && _selectedDate != null && _selectedGender != null && companyNameController.text.isNotEmpty && companyAddressController.text.isNotEmpty){
          await FirebaseFirestore.instance.collection('travelAgent').doc(widget.userListID).update({
            'name': nameController.text,
            'username': usernameController.text,
            'companyContact': companyContactController.text,
            'email': emailController.text,
            'gender': _selectedGender,
            'dob': _selectedDate,
            'companyName': companyNameController.text,
            'companyAddress': companyAddressController.text
          });

          showCustomDialog(
            context: context, 
            title: "Success", 
            content: "Travel agent data has been updated successfully.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        } else{
          showCustomDialog(
            context: context, 
            title: "Failed", 
            content: "Please make sure you have fill in all details.", 
            onPressed: (){
              Navigator.pop(context);
            }
          );
        }
      }
    }catch(e){

    }finally{
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<Map<String, String>> _getLocationAreaAndCountry(String address) async {
    final String apiKeys = apiKey;
    final String url = 'https://maps.googleapis.com/maps/api/geocode/json?address=$address&key=$apiKeys';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body); 

      if (data['results'].isNotEmpty) {
        final addressComponents = data['results'][0]['address_components'];

        String country = '';
        String area = '';

        for (var component in addressComponents) {
          List<String> types = List<String>.from(component['types']);
          if (types.contains('country')) {
            country = component['long_name'];
          } else if (types.contains('administrative_area_level_1') || types.contains('locality')) {
            area = component['long_name'];
          }
        }

        return {'country': country, 'area': area};
      } else {
        return {'country': '', 'area': ''};
      }
    } else {
      print('Error fetching location data: ${response.statusCode}');
      return {'country': '', 'area': ''};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("User"),
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
              MaterialPageRoute(builder: (context) => AdminManageUserListScreen(userId: widget.userId))
            );
          },
        ),
      ),
      body: isFetching
          ? Center(child: CircularProgressIndicator(color: primaryColor,))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.type == "lb" ? "User details: \nName: ${widget.localBuddyname!}" : "User details:",
                      style: TextStyle(
                        fontSize: defaultLabelFontSize,
                        color: Colors.black,
                        fontWeight: FontWeight.w600
                      ),
                      textAlign: TextAlign.left,
                    ),
                    SizedBox(height: 10),
                    if(widget.type == "user" || widget.type == "ta")...[
                      buildTextField(nameController, "Name", "Please enter name..."),
                      SizedBox(height: 10),
                      buildTextField(usernameController, "Username", "Please enter username..."),
                      SizedBox(height: 10),
                      buildTextField(emailController, "Email", "Please enter email..."),
                      SizedBox(height: 10),
                      buildDropDownList(
                        genderType, 
                        "Please select a gender", 
                        "Gender", 
                        _selectedGender, 
                        (newValue){
                          setState(() {
                            _selectedGender = newValue;
                          });
                        }
                      ),
                      SizedBox(height: 10),
                      dob(),
                      SizedBox(height: 10),
                      if(widget.type == "user")...[
                        buildTextField(contactController, "Contact", "Please enter contect...", isInt: true),
                        SizedBox(height: 10),
                        buildTextField(addressController, "Address", "Please enter address...")
                      ]
                      else if(widget.type == "ta")...[
                        buildTextField(companyContactController, "Company Contact", "Please enter company contact...", isInt: true),
                        SizedBox(height: 10),
                        buildTextField(companyNameController, "Company Name", "Please enter company name..."),
                        SizedBox(height: 10),
                        buildTextField(companyAddressController, "Company Address", "Please enter address...")
                      ],
                    ]
                    else...[
                      buildTextField(occupationController, "Occupation", "Please enter occupation..."),
                      SizedBox(height: 10),
                      buildTextField(buddyLocationController, "Buddy Location", "Please enter buddy location..."),
                      SizedBox(height: 10),
                      buildTextField(languageSpokenController, "Language Spoken", "Please enter language spoken..."),
                      SizedBox(height: 10),
                      // Availability Section
                      Text(
                        'Availability',
                        style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Container(
                        width: double.infinity, // Set the width to take up all available space
                        child: Table(
                          border: TableBorder.all(color: primaryColor, width: 2.5, borderRadius: BorderRadius.circular(10)),
                          columnWidths: {
                            0: FlexColumnWidth(), // Make column take proportional width
                          },
                          children: [
                            TableRow(
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.6),
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Text(
                                    'Day',
                                    style: TextStyle(
                                      fontSize: defaultFontSize,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            // Iterate over all days of the week
                            for (var day in ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'])
                              TableRow(
                                children: [
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: selectedDays.contains(day), // Check if the day is selected
                                        onChanged: (value) {
                                          toggleDaySelection(day); // Handle checkbox toggle
                                        },
                                        activeColor: primaryColor, // Change checkbox color
                                      ),
                                      Text(
                                        day,
                                        style: TextStyle(
                                          fontSize: defaultFontSize,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: 10),
                      buildTextField(priceController, "Price in RM (per day)", "Please enter price...", isInt: true),
                      SizedBox(height: 10),
                      buildTextField(bioController, "Bio", "Please enter bio..."),
                    ],
                    SizedBox(height: 10),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity, // This makes the button take up the full width
                      child: ElevatedButton(
                        onPressed: (){
                          _updateData();
                        },
                        child: isUpdating
                        ? Container(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white,)
                          ) 
                        : Text(
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
              )
              
            ),
    );
  }

  Widget buildTextField(TextEditingController controller, String labelText, String hintText, {bool isInt = false}) {
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: defaultFontSize,
        color: Colors.black
      ),
      maxLines: null,
      textAlign: TextAlign.justify,
      keyboardType: isInt ? TextInputType.number : TextInputType.multiline,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
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
          fontSize: defaultLabelFontSize,
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

  Widget buildDropDownList(
      List<String> listname, String hintText, String label, String? selectedValue, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: selectedValue,
      hint: Text(hintText),
      decoration: InputDecoration(
        labelText: label,
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
          fontSize: defaultLabelFontSize,
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
      items: listname.map<DropdownMenuItem<String>>((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: onChanged, // Use the passed in function
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: defaultFontSize,
        color: Colors.black,
      ),
    );
  }

  Widget dob() {
    return GestureDetector(
      onTap: () {}, // Prevents the TextField from being editable by touch.
      child: TextField(
        controller: TextEditingController(
          text: _selectedDate == null
              ? ''
              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
        ),
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: _selectedDate == null ? Colors.grey.shade600 : Colors.black,
        ),
        readOnly: true,
        decoration: InputDecoration(
          hintText: 'Select your date of birth',
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
          suffixIcon: IconButton(
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: Color(0xFF467BA1),
              size: 20,
            ),
            onPressed: () => _selectDate(context),
          ),
        ),
      ),
    );
  }
}

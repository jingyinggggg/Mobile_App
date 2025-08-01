import 'dart:convert';
import 'package:assignment_tripmate/screens/user/homepage.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/user/localBuddyHomepage.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class LocalBuddyEditInfoScreen extends StatefulWidget {
  final String userId;

  const LocalBuddyEditInfoScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _LocalBuddyEditInfoScreenState();
}

class _LocalBuddyEditInfoScreenState extends State<LocalBuddyEditInfoScreen> {
  TextEditingController _occupationController = TextEditingController();
  TextEditingController _languageSpokenController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _pricingController = TextEditingController();
  TextEditingController _previousExperienceController = TextEditingController();
  TextEditingController _bioController = TextEditingController();
  TextEditingController _referenceController = TextEditingController();

  bool isLoading = false;
  bool isFetchLoading = false;
  Uint8List? _image;
  Uint8List? _referenceImage;
  String? localBuddyID;
  String? rejectReason;
  int? registrationStatus;

  List<String> selectedDays = [];

  @override
  void initState() {
    super.initState();
    fetchLocalBuddy();
  }

  Future<void> fetchLocalBuddy() async {
    setState(() {
      isFetchLoading = true;
    });
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('localBuddy')
          .where('userID', isEqualTo: widget.userId)
          .limit(1)
          .get();

      if (userQuery.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userQuery.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>;

        setState(() {
          _occupationController.text = userData['occupation'] ?? '';
          _locationController.text = userData['location'] ?? '';
          _languageSpokenController.text = userData['languageSpoken'] ?? '';
          _pricingController.text = userData['price']?.toString() ?? '0';
          _bioController.text = userData['bio'] ?? '';
          _previousExperienceController.text = userData['previousExperience'] ?? '';
          localBuddyID = userData['localBuddyID'];
          rejectReason = userData['rejectReason'] ?? null;
          registrationStatus = userData['registrationStatus'] ?? null;
          // _referenceController = userData

          print("Reject reason: $rejectReason");
          print("Registration status: $registrationStatus");

          // Ensure availability is a List and extract days
          if (userData['availability'] is List) {
            selectedDays = (userData['availability'] as List<dynamic>)
                .map((item) => item['day'].toString()) // Accessing the 'day' string from each map
                .toList();
          } else {
            selectedDays = []; // Default to an empty list if not available or not a List
          }

          isFetchLoading = false;
        });
      } else {
        print("No user found with userID: ${widget.userId}");
        setState(() {
          isFetchLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
      setState(() {
        isFetchLoading = false;
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

  Future<void> selectReferenceImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _referenceImage = img;
        _referenceController.text = 'Reference Uploaded'; 
      });
    }
  }

  Future<void> _saveBuddyData() async {
    // Check if required fields are filled
    if (_occupationController.text.isEmpty ||
        _locationController.text.isEmpty ||
        _languageSpokenController.text.isEmpty ||
        _pricingController.text.isEmpty ||
        _bioController.text.isEmpty || selectedDays.isEmpty) {
      
      // Show an error dialog if required fields are missing
      showCustomDialog(
        context: context,
        title: 'Error',
        content: 'Please make sure you have filled in all the required fields.',
        onPressed: () {
          Navigator.pop(context);
        }
      );
      return;  // Exit the function if any required field is missing
    }

    setState(() {
      isLoading = true;
    });

    try {

      // Prepare availability data
      List<Map<String, dynamic>> availability = selectedDays.map((day) {
        return {
          'day': day,
        };
      }).toList();

      // Check if previous experience is entered (null or empty check)
      String? previousExperience;
      if (_previousExperienceController.text.isNotEmpty) {
        previousExperience = _previousExperienceController.text;
      }

      // Check if reference image is provided (optional)
      // Uint8List? referenceImage;
      // if (_referenceImage != null) {
      //   referenceImage = _referenceImage!;
      // }

      String? country = '';
      String? area = '';

      var locationData = await _getLocationAreaAndCountry(_locationController.text);
      country = locationData['country'];
      area = locationData['area'];

      String locationArea = '$area, $country';

      // Call the saveLocalBuddyData function with the optional parameters
      String resp = await StoreData().saveLocalBuddyData(
        localBuddyID: localBuddyID,
        occupation: _occupationController.text,
        location: _locationController.text,
        languageSpoken: _languageSpokenController.text,
        locationArea: locationArea,
        availability: availability,
        price: int.tryParse(_pricingController.text) ?? 0,  // Default to 0 if parsing fails
        // referenceImage: referenceImage,  // Optional field
        bio: _bioController.text,  // Required field, already checked
        previousExperience: previousExperience,  // Optional field
        action: 0,
        registrationStatus: rejectReason == null && registrationStatus == 2 ? 2 : 0
      );

      // Show success dialog
      showCustomDialog(
        context: context,
        title: 'Success',
        content: 'You have updated your details successfully.',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LocalBuddyHomepageScreen(userId: widget.userId))
          );
        }
      );

    } catch (e) {
      // Show failure dialog if an error occurs
      showCustomDialog(
        context: context,
        title: 'Failed',
        content: 'Please make sure all required fields are filled in and upload your identification card.',
        onPressed: () {
          Navigator.pop(context);
        }
      );
      print("Error saving buddy data: $e");
    } finally {
      setState(() {
        isLoading = false;
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
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: rejectReason != null && registrationStatus == 3 ? AppBar(
        title: const Text("Local Buddy"),
        centerTitle: true,
        backgroundColor: const Color(0xFFE57373),
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
              MaterialPageRoute(builder: (context) => LocalBuddyHomepageScreen(userId: widget.userId)),
            );
          },
        ),
      ) 
      : null,
      body: isFetchLoading
      ? Center(child: CircularProgressIndicator(color: primaryColor))
      : ListView(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        children: [
          Text(
            rejectReason == null && registrationStatus == 2
            ?'Your registration for local buddy has been approved by admin. You can update your infomation at here:'
            :'Reject reason: $rejectReason \nPlease update the info and submit the request again.',
            style: TextStyle(
              color: rejectReason == null && registrationStatus == 2 ? Colors.grey : Colors.black87,
              fontSize: defaultFontSize,
              fontWeight: FontWeight.w600
            ),
            maxLines: null,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 10),
          Text(
            'Background Information',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: defaultLabelFontSize,
            ),
          ),
          SizedBox(height: 20),
          buildTextField(_occupationController, 'Enter your occupation', 'Occupation'),
          SizedBox(height: 20),
          buildTextField(_locationController, 'Enter your location', 'Location', readOnly: true),
          SizedBox(height: 20),
          buildTextField(_languageSpokenController, 'E.g. English, Mandarin, Hokkien', 'Languages Spoken'),
          SizedBox(height: 30),

          // Availability Section
          Text(
            'Availability',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: defaultLabelFontSize,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Select available days by checking the boxes.',
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.justify,
          ),
          SizedBox(height: 10),
          Table(
            border: TableBorder.all(color: primaryColor, width: 1.5, borderRadius: BorderRadius.circular(10)),
            columnWidths: {
              0: FixedColumnWidth(130), // Fixed width for days
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

          SizedBox(height: 20),
          buildTextField(_pricingController, 'Enter price', 'Price in RM (per day)', isIntField: true),

          SizedBox(height: 30),
          Text(
            'Additional Information',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: Colors.black,
              fontSize: defaultLabelFontSize,
            ),
          ),
          SizedBox(height: 20),
          buildTextField(_bioController, 'Enter your personal bio', 'Personal Bio/ Introduction'),
          SizedBox(height: 20),
          buildTextField(_previousExperienceController, 'Enter your previous experience (if any)', 'Experience for Local Friend/Local Guide (optional)'),
          // SizedBox(height: 20),
          // TextField(
          //   controller: _referenceController,
          //   readOnly: true,
          //   style: const TextStyle(
          //     fontWeight: FontWeight.w800,
          //     fontSize: defaultFontSize,
          //     color: Colors.black54
          //   ),
          //   decoration: InputDecoration(
          //     hintText:  'Please upload any references if applicable...',
          //     labelText: 'References/Reviews (optional)',
          //     filled: true,
          //     fillColor: Colors.white,
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10),
          //       borderSide: const BorderSide(
          //         color: Color(0xFFF50057),
          //         width: 1.5,
          //       ),
          //     ),
          //     focusedBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10),
          //       borderSide: const BorderSide(
          //         color: Color(0xFFF50057),
          //         width: 1.5,
          //       ),
          //     ),
          //     enabledBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(10),
          //       borderSide: const BorderSide(
          //         color: Color(0xFFF50057),
          //         width: 1.5,
          //       ),
          //     ),
          //     floatingLabelBehavior: FloatingLabelBehavior.always,
          //     labelStyle: const TextStyle(
          //       fontSize: defaultLabelFontSize,
          //       fontWeight: FontWeight.bold,
          //       color: Colors.black87,
          //       shadows: [
          //         Shadow(
          //           offset: Offset(0.5, 0.5),
          //           color: Colors.black87,
          //         ),
          //       ],
          //     ),
          //     suffixIcon: IconButton(
          //       icon: const Icon(
          //         Icons.image,
          //         color: Color(0xFFF50057),
          //         size: 25,
          //       ),
          //       onPressed: () {
          //         selectReferenceImage();
          //       }
          //     ),
          //   ),
          // ),
          SizedBox(height: 30),
          Container(
            width: double.infinity,
            height: getScreenHeight(context) * 0.08,
            child: ElevatedButton(
              onPressed: () {_saveBuddyData();},
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white,)
                  : Text(
                      'Update',
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF50057),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextField(TextEditingController controller,String hintText, String label, {bool isIntField = false, readOnly = false}){
    return TextField(
      controller: controller,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: defaultFontSize,
        overflow: TextOverflow.visible
      ),
      maxLines: null,
      textAlign: TextAlign.justify,
      keyboardType: isIntField ? TextInputType.number : TextInputType.multiline,
      decoration: InputDecoration(
        hintText: hintText,
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
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
}

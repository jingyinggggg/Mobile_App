import 'dart:io';
import 'dart:typed_data';
import 'package:assignment_tripmate/constants.dart';
import 'package:http/http.dart' as http;
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewPDF.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewTourList.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TravelAgentEditTourPackageScreen extends StatefulWidget {
  final String userId;
  final String countryName;
  final String cityName;
  final String tourID;

  const TravelAgentEditTourPackageScreen({
    super.key,
    required this.userId,
    required this.countryName,
    required this.cityName,
    required this.tourID
  });

  @override
  State<StatefulWidget> createState() => _TravelAgentEditTourPackageScreenState();
}

class _TravelAgentEditTourPackageScreenState extends State<TravelAgentEditTourPackageScreen> {
  TextEditingController _tourNameController = TextEditingController();
  TextEditingController _travelAgencyController = TextEditingController();
  TextEditingController _imageNameController = TextEditingController();
  TextEditingController _brochureController = TextEditingController();
  List<TextEditingController> _tourHighlightControllers = [];
  List<TextEditingController> _itineraryTitleControllers = [];
  List<TextEditingController> _itineraryDescriptionControllers = [];
  List<TextEditingController> _flightDepartDateControllers = [];
  List<TextEditingController> _flightReturnDateControllers = [];
  List<TextEditingController> _flightNameControllers = [];
  List<TextEditingController> _availableDateRangeControllers = [];
  List<TextEditingController> _availableSlotControllers = [];
  List<TextEditingController> _priceControllers = [];
  bool isLoading = false;
  bool isFetchingLoading = false;
  Uint8List? _image;
  String? existingImagePath;
  File? _uploadedPdfFile;
  late String brochurePath;
  String? companyID;
  Map<String, dynamic>? tourData;

  void _initControllers() {
    for (var i = 0; i < _tourHighlights.length; i++) {
      _tourHighlightControllers.add(TextEditingController(text: _tourHighlights[i]['description']));
    }

    for (var i = 0; i < _itinerary.length; i++) {
      _itineraryTitleControllers.add(TextEditingController(text: _itinerary[i]['title']));
      _itineraryDescriptionControllers.add(TextEditingController(text: _itinerary[i]['description']));
    }

    for (var i = 0; i < _flight.length; i++) {
      _flightDepartDateControllers.add(TextEditingController(text: _flight[i]['depart']));
      _flightReturnDateControllers.add(TextEditingController(text: _flight[i]['return']));
      _flightNameControllers.add(TextEditingController(text: _flight[i]['flight']));
    }

    for (var i = 0; i < _availability.length; i++) {
      _availableDateRangeControllers.add(TextEditingController(text: _availability[i]['date']));
      _availableSlotControllers.add(TextEditingController(text: _availability[i]['slot']));
      _priceControllers.add(TextEditingController(text: _availability[i]['price']));
    }
  }

  List<Map<String, dynamic>> _tourHighlights = [
    {'no': '', 'description': ''},
  ];

  List<Map<String, dynamic>> _itinerary = [
    {'day': '', 'title': '', 'description': ''},
  ];

  List<Map<String, dynamic>> _flight = [
    {'no': '', 'depart': '', 'return': '', 'flight': ''},
  ];

  List<Map<String, dynamic>> _availability = [
    {'no': '', 'date': '', 'slot': '', 'price': ''},
  ];

  @override
  void initState() {
    super.initState();
    _initControllers();
    fetchTravelAgencyName();
    _fetchTourPackageDetails();
  }

  @override
  void dispose() {
    _tourNameController.dispose();
    _travelAgencyController.dispose();
    _imageNameController.dispose();
    _brochureController.dispose();
    
    // Dispose tour highlight controllers
    for (var controller in _tourHighlightControllers) {
      controller.dispose();
    }

    // Dispose itinerary controllers
    for (var controller in _itineraryTitleControllers) {
      controller.dispose();
    }
    for (var controller in _itineraryDescriptionControllers) {
      controller.dispose();
    }

    // Dispose flight controllers
    for (var controller in _flightDepartDateControllers) {
      controller.dispose();
    }
    for (var controller in _flightReturnDateControllers) {
      controller.dispose();
    }
    for (var controller in _flightNameControllers) {
      controller.dispose();
    }

    // Dispose availability controllers
    for (var controller in _availableDateRangeControllers) {
      controller.dispose();
    }
    for (var controller in _availableSlotControllers) {
      controller.dispose();
    }
    for (var controller in _priceControllers) {
      controller.dispose();
    }

    // Call super.dispose() last
    super.dispose();
  }

  Future<void> _fetchTourPackageDetails() async {
    setState(() {
      isFetchingLoading = true;
    });

    try{
      DocumentReference TPref = FirebaseFirestore.instance.collection('tourPackage').doc(widget.tourID);
      DocumentSnapshot TPsnapshot = await TPref.get();

      if(TPsnapshot.exists){
        Map<String, dynamic>? data = TPsnapshot.data() as Map<String, dynamic>?;

        setState(() {
          tourData = data ?? {};
          isFetchingLoading = false;

          _tourNameController.text = tourData?['tourName'] ?? '';
          // _travelAgencyController.text = tourData?['agency'];
          existingImagePath = tourData?['tourCover'] ?? '';

          // Retrieve pdf file name
          if (tourData?['brochure'] != null && tourData!['brochure']!.isNotEmpty) {
            brochurePath = tourData!['brochure'];
            String brochureUrl = tourData!['brochure'];
            Uri uri = Uri.parse(brochureUrl);
            String fileName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
            _brochureController.text = fileName.split('/').last;
            // _brochureController.text = fileName;
          } else {
            _brochureController.text = '';
          }

          // Populate tour highlights
          _tourHighlights = List<Map<String, dynamic>>.from(tourData?['tourHighlight'] ?? []);
          _tourHighlightControllers = List.generate(
            _tourHighlights.length, 
            (index) => TextEditingController(text: _tourHighlights[index]['description'] ?? ''),
          );

          // Populate itinerary
          _itinerary = List<Map<String, dynamic>>.from(tourData?['itinerary'] ?? []);
          _itineraryTitleControllers = List.generate(
            _itinerary.length, 
            (index) => TextEditingController(text: _itinerary[index]['title'] ?? ''),
          );
          _itineraryDescriptionControllers = List.generate(
            _itinerary.length, 
            (index) => TextEditingController(text: _itinerary[index]['description'] ?? ''),
          );

          // Populate flight info
          _flight = List<Map<String, dynamic>>.from(tourData?['flight_info'] ?? []);
          _flightDepartDateControllers = List.generate(
            _flight.length, 
            (index) => TextEditingController(text: _flight[index]['departDate'] ?? ''),
          );
          _flightReturnDateControllers = List.generate(
            _flight.length, 
            (index) => TextEditingController(text: _flight[index]['returnDate'] ?? ''),
          );
          _flightNameControllers = List.generate(
            _flight.length, 
            (index) => TextEditingController(text: _flight[index]['flightName'] ?? ''),
          );

          // Populate availability
          _availability = List<Map<String, dynamic>>.from(tourData?['availability'] ?? []);
          _availableDateRangeControllers = List.generate(
            _availability.length, 
            (index) => TextEditingController(text: _availability[index]['dateRange'] ?? ''),
          );
          _availableSlotControllers = List.generate(
            _availability.length, 
            (index) => TextEditingController(text: _availability[index]['slot'].toString()),
          );
          _priceControllers = List.generate(
            _availability.length, 
            (index) => TextEditingController(text: _availability[index]['price'].toString()),
          );

        });
      } else{
        setState(() {
          isFetchingLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selected tour package does not exists in the system')),
        );
      }
    }catch(e){
      setState(() {
        isFetchingLoading = false;
      });
      print("Error fetch tour package details: $e");
    }
  }

  Future<void> fetchTravelAgencyName() async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('travelAgent')
        .where('id', isEqualTo: widget.userId)
        .limit(1)
        .get();
      
      DocumentSnapshot userDoc = userQuery.docs.first;
      var agencyData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        _travelAgencyController.text = agencyData['companyName'] ?? '';
      });
    } catch (e) {
      print("Error fetching agency details: $e");
    }
  }

  void _addTourHighlightRow() {
    // Check if the last row's content is not empty
    if (_tourHighlightControllers.isNotEmpty && _tourHighlightControllers.last.text.trim().isEmpty) {
      // Show a message to the user to fill in the previous row first
      showSnackBar("Please ensure you have fill in the previous row before adding a new one.", context);
    } else {

      setState(() {
        _tourHighlights.add({'no': '', 'description': ''});
        _tourHighlightControllers.add(TextEditingController());
      });
    }
  }

  void _addItineraryRow() {
    if (_itineraryTitleControllers.isNotEmpty &&
        _itineraryDescriptionControllers.isNotEmpty &&
        (_itineraryTitleControllers.last.text.trim().isEmpty ||
        _itineraryDescriptionControllers.last.text.trim().isEmpty)) {
      showSnackBar("Please ensure you have filled in the previous row before adding a new one.", context);
    } else {
      setState(() {
        _itinerary.add({'day': '', 'title': '', 'description': ''});
        _itineraryTitleControllers.add(TextEditingController());
        _itineraryDescriptionControllers.add(TextEditingController());
      });
    }
  }

  void _addFlightRow() {
    if(_flightDepartDateControllers.isNotEmpty && _flightReturnDateControllers.isNotEmpty & _flightNameControllers.isNotEmpty &&
    (_flightDepartDateControllers.last.text.trim().isEmpty || _flightReturnDateControllers.last.text.trim().isEmpty || _flightNameControllers.last.text.trim().isEmpty)){
      showSnackBar("Please ensure you have fill in the previous row before adding a new one.", context);
    } else{
      setState(() {
        _flight.add({'no': '', 'depart': '', 'return': '', 'flight': ''});
        _flightDepartDateControllers.add(TextEditingController());
        _flightReturnDateControllers.add(TextEditingController());
        _flightNameControllers.add(TextEditingController());

      });
    }
  }

  void _addAvailabilityRow() {
    if(_availableDateRangeControllers.isNotEmpty &&
    (_availableDateRangeControllers.last.text.trim().isEmpty)){
      showSnackBar("Please ensure you have fill in the previous row before adding a new one.", context);
    } else{
      setState(() {
        _availability.add({'no': '', 'date': '', 'slot': '', 'price': ''});
        _availableDateRangeControllers.add(TextEditingController());
        _availableSlotControllers.add(TextEditingController());
        _priceControllers.add(TextEditingController());
      });
    }
  }

  void _removeTourHighlightRow(int index) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove this tour highlight?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      setState(() {
        if (_tourHighlights.length > 1) {
          _tourHighlights.removeAt(index);
          _tourHighlightControllers[index].dispose();
          _tourHighlightControllers.removeAt(index);
        }
      });
    }
  }


  void _removeItineraryRow(int index) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove this row?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      setState(() {
        if (_itinerary.length > 1) {
          // Remove the row
          _itinerary.removeAt(index);

          // Dispose of the text controllers and remove them from the list
          _itineraryTitleControllers[index].dispose();
          _itineraryDescriptionControllers[index].dispose();

          _itineraryTitleControllers.removeAt(index);
          _itineraryDescriptionControllers.removeAt(index);
        }
      });
    }
  }

  void _removeFlightRow(int index) async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Removal'),
          content: Text('Are you sure you want to remove this flight?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Remove'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white, 
                backgroundColor: primaryColor
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      setState(() {
        if (_flight.length > 1) {
          _flight.removeAt(index);
          
          _flightDepartDateControllers[index].dispose();
          _flightReturnDateControllers[index].dispose();
          _flightNameControllers[index].dispose();

          _flightDepartDateControllers.removeAt(index);
          _flightReturnDateControllers.removeAt(index);
          _flightNameControllers.removeAt(index);

          _removeAvailabilityRow(index);
        }
      });
    }
  }

  void _removeAvailabilityRow(int index) {
    setState(() {
      if (_availability.length > 1) {
        _availability.removeAt(index);
        
        _availableDateRangeControllers[index].dispose();
        _availableSlotControllers[index].dispose();
        _priceControllers[index].dispose();

        _availableDateRangeControllers.removeAt(index);
        _availableSlotControllers.removeAt(index);
        _priceControllers.removeAt(index);
      }
    });
  }

  void _saveDataToList(String category) {
    try {
      switch (category) {
        case "highlight":
          for (int i = 0; i < _tourHighlightControllers.length; i++) {
            if (_tourHighlightControllers[i].text.trim().isEmpty) {
              throw Exception("Highlight row ${i + 1} is incomplete. Please provide a description.");
            }
            _tourHighlights[i]['no'] = (i + 1).toString();
            _tourHighlights[i]['description'] = _tourHighlightControllers[i].text.trim();
          }
          break;

        case "itinerary":
          for (int i = 0; i < _itinerary.length; i++) {
            if (_itineraryTitleControllers[i].text.trim().isEmpty || 
                _itineraryDescriptionControllers[i].text.trim().isEmpty) {
              throw Exception("Itinerary row ${i + 1} is incomplete. Please provide both a title and a description.");
            }
            _itinerary[i]['day'] = (i + 1).toString();
            _itinerary[i]['title'] = _itineraryTitleControllers[i].text.trim();
            _itinerary[i]['description'] = _itineraryDescriptionControllers[i].text.trim();
          }
          break;

        case "flight":
          for (int i = 0; i < _flight.length; i++) {
            if (_flightDepartDateControllers[i].text.trim().isEmpty || 
                _flightReturnDateControllers[i].text.trim().isEmpty || 
                _flightNameControllers[i].text.trim().isEmpty) {
              throw Exception("Flight row ${i + 1} is incomplete. Please provide departure date, return date, and flight name.");
            }
            _flight[i]['no'] = (i + 1).toString();
            _flight[i]['depart'] = _flightDepartDateControllers[i].text.trim();
            _flight[i]['return'] = _flightReturnDateControllers[i].text.trim();
            _flight[i]['flight'] = _flightNameControllers[i].text.trim();
          }
          break;

        case "availability":
          for (int i = 0; i < _availability.length; i++) {
            if (_availableDateRangeControllers[i].text.trim().isEmpty || 
                _availableSlotControllers[i].text.trim().isEmpty || 
                _priceControllers[i].text.trim().isEmpty) {
              throw Exception("Availability row ${i + 1} is incomplete. Please provide slot, and price.");
            }
            _availability[i]['no'] = (i + 1).toString();
            _availability[i]['date'] = _availableDateRangeControllers[i].text.trim();
            _availability[i]['slot'] = _availableSlotControllers[i].text.trim();
            _availability[i]['price'] = _priceControllers[i].text.trim();
          }
          break;

        default:
          throw ArgumentError("Unknown category: $category");
      }
    } catch (e) {
      // Show error message
      print(e); // Replace this with your UI error handling, such as a dialog or snackbar
    }
  }

  void _updateReturnDatePicker(int index, DateTime firstDate) {
    setState(() {
      // Update the return date picker's firstDate by storing it in a list or directly in the controller
      _flightReturnDateFirstDates[index] = firstDate;
    });
  }

  DateTime _getFirstReturnDate(int index) {
    // Return the first available return date based on the selected depart date or a default date
    return _flightReturnDateFirstDates[index] ?? DateTime.now().add(const Duration(days: 1));
  }

  void _showSelectDepartDateFirstMessage() {
    showSnackBar("Please select the departure date first.", context);
  }

  void showSnackBar(String message, BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _updateAvailabilityRanges() {
    print("Update availability ranges triggered");

    setState(() {
      for (int i = 0; i < _flightDepartDateControllers.length; i++) {
        print("Processing row $i");

        String? departDate = _flightDepartDateControllers[i].text;
        String? returnDate = _flightReturnDateControllers[i].text;

        print("Depart Date: $departDate");
        print("Return Date: $returnDate");

        if (departDate.isNotEmpty && returnDate.isNotEmpty) {
          print("Updating date range");

          String formattedDateRange = "$departDate - $returnDate";
          _availability[i]['dateRange'] = formattedDateRange; // Update _availability

          if (i < _availableDateRangeControllers.length) {
            _availableDateRangeControllers[i].text = formattedDateRange;
          } else {
            print("Index $i is out of bounds for _availableDateRangeControllers");
          }
        } else {
          // Set the date range to an empty string if either date is missing
          _availability[i]['dateRange'] = ''; // Clear date range in _availability

          if (i < _availableDateRangeControllers.length) {
            _availableDateRangeControllers[i].text = '';
          } else {
            print("Index $i is out of bounds for _availableDateRangeControllers");
          }
        }
      }
    });
  }

  void _updateTextField(
    List<TextEditingController> controllers, 
    int index, 
    dynamic newValue, 
    List<Map<String, dynamic>> listName, 
    String fieldName
  ) {
    setState(() {
      // Update the specific field of the existing item in the list
      Map<String, dynamic> updatedItem = Map.from(listName[index]);
      updatedItem[fieldName] = newValue;

      // Replace the old item with the updated one
      listName[index] = updatedItem;

      // Also update the corresponding TextEditingController
      controllers[index].text = newValue;
    });
  }


  Future<void> selectImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _image = img;
        existingImagePath = null;
      });
    }
  }

  Future<void> selectPdfFile() async {
    File? pdfFile = await FileUtils.selectPdf();
    if (pdfFile != null) {
      // await uploadPdfToFirebase(pdfFile);
      setState(() {
        _uploadedPdfFile = pdfFile;
        _brochureController.text = pdfFile.path.split('/').last;
      });
    }
  }

  Map<String, dynamic> convertToMap(String category, List<Map<String, dynamic>> listName) {
    switch (category) {
      case "highlight":
        return {
          'tourHighlight': listName.map((entry) {
            return {
              'no': entry['no'],
              'description': entry['description'],
            };
          }).toList(),
        };

      case "itinerary":
        return {
          'itinerary': listName.map((entry) {
            return {
              'day': entry['day'],
              'title': entry['title'],
              'description': entry['description'],
            };
          }).toList(),
        };

      case "flight":
        return {
          'flight_info': listName.map((entry) {
            return {
              'no': entry['no'],
              'departDate': entry['depart'],
              'returnDate': entry['return'],
              'flightName': entry['flight'],
            };
          }).toList(),
        };

      case "availability":
        return {
          'availability': listName.map((entry) {
            return {
              'no': entry['no'],
              'dateRange': entry['date'],
              'slot': int.tryParse(entry['slot'] ?? '') ?? 0,
              'price': int.tryParse(entry['price'] ?? '') ?? 0,
            };
          }).toList(),
        };

      default:
        throw ArgumentError("Unknown category: $category");
    }
  }

  Future<Uint8List> _getImageFromURL(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  Future<void> _updateTour() async {
    try{
      _saveDataToList("highlight");
      _saveDataToList("itinerary");
      _saveDataToList("flight");
      _saveDataToList("availability");

      setState(() {
        isLoading = true; // Start loading
      });

      final firestore = FirebaseFirestore.instance;

      // Convert list to map
      final tourHighlightData = convertToMap('highlight', _tourHighlights);
      final itineraryData = convertToMap('itinerary', _itinerary);
      final flightData = convertToMap('flight', _flight);
      final availabilityData = convertToMap('availability', _availability);
    
      if (_tourNameController.text.isNotEmpty &&
          _travelAgencyController.text.isNotEmpty &&
          _tourHighlights.isNotEmpty &&
          _itinerary.isNotEmpty &&
          _flight.isNotEmpty &&
          _availability.isNotEmpty) {

        Uint8List? tourCoverToUpload;
        File? pdfToUpload;

        // Check if a new image or PDF is uploaded, otherwise retain the existing ones.
        if (_image != null) {
          tourCoverToUpload = _image!;
        } else if (existingImagePath != null && existingImagePath!.isNotEmpty) {
          // Fetch the existing image from URL
          tourCoverToUpload = await _getImageFromURL(existingImagePath!);
        } else {
          // Handle case where no image is provided
          throw Exception("Tour cover image is required.");
        }

        if (_uploadedPdfFile != null) {
          pdfToUpload = _uploadedPdfFile;
        } else {
          pdfToUpload = null;
        }

        String resp = await StoreData().updateTourPackageData(
          tourid: widget.tourID, 
          tourName: _tourNameController.text, 
          countryName: widget.countryName, 
          cityName: widget.cityName, 
          agency: _travelAgencyController.text, 
          tourHighlightData: tourHighlightData, 
          itineraryData: itineraryData, 
          flightData: flightData, 
          availabilityData: availabilityData, 
          tourCover: tourCoverToUpload, 
          pdfFile: pdfToUpload
        );

        // Show success dialog
        _showDialog(
          title: 'Successful',
          content: 'You have updated the tour package successfully.',
          onPressed: () {
            Navigator.of(context).pop(); // Close the success dialog
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TravelAgentViewTourListScreen(
                  userId: widget.userId,
                  countryName: widget.countryName,
                  cityName: widget.cityName,
                ),
              ),
            );
          },
        );
      } else {
        throw Exception("All fields are required.");
      }
    } catch (e) {
      // Show error dialog
      _showDialog(
        title: 'Failed',
        content: 'Failed to update tour package: $e',
        onPressed: () {
          Navigator.of(context).pop(); // Close the error dialog
        },
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  // Method to show a dialog with a title and content
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

  // A list to store the first available dates for return date pickers
  List<DateTime?> _flightReturnDateFirstDates = List.filled(10, null);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Edit Tour"),
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
            Navigator.push(context, MaterialPageRoute(builder: (context) => TravelAgentViewTourListScreen(userId: widget.userId, countryName: widget.countryName, cityName: widget.cityName)));
          },
        ),
      ),
      body: Stack(
        children: [
          // Main content
          if (!isFetchingLoading)
            Container(
              padding: const EdgeInsets.only(
                  left: 15, right: 15, top: 10, bottom: 30),
              width: double.infinity,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Tour Information",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    tourName(),
                    const SizedBox(height: 20),
                    travelAgency(),
                    const SizedBox(height: 20),
                    tourHighlightsSection(),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: _addTourHighlightRow,
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(20, 35),
                          backgroundColor: const Color(0xFF467BA1),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    itinerarySection(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: _addItineraryRow,
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(20, 35),
                          backgroundColor: const Color(0xFF467BA1),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    flightSection(),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.topRight,
                      child: ElevatedButton(
                        onPressed: () {
                          _addFlightRow();
                          _addAvailabilityRow();
                        },
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(20, 35),
                          backgroundColor: const Color(0xFF467BA1),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                    availabilitySection(),
                    const SizedBox(height: 20),
                    tourImage(),
                    SizedBox(height: 20),
                    brochure(),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          _updateTour();
                        },
                        child: isLoading
                            ? const CircularProgressIndicator()
                            : const Text(
                                'Update Tour',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF467BA1),
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
            ),
          
          // Centered loading indicator
          if (isFetchingLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget tourName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tour Name",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
        SizedBox(height: 5,),
        TextField(
          controller: _tourNameController,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: 'Example: 9 DAYS SHANGHAI THEME PARK',
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        )
      ],
    );
  }

  Widget travelAgency() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Travel Agency",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            )),
        SizedBox(height: 5,),
        TextField(
          controller: _travelAgencyController,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 15,
          ),
          readOnly: true,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2.5),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
          ),
        )
      ],
    );
  }

  Widget tourHighlightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Tour Highlights",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 5,),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.4),
              1: FlexColumnWidth(2.7),
              2: FlexColumnWidth(0.4),
            },
            border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
            children: [
              TableRow(
                children: [
                  _buildTableHeaderCell('No'),
                  _buildTableHeaderCell('Description'),
                  _buildTableHeaderCell(''),
                ],
              ),
              for (int i = 0; i < _tourHighlights.length; i++)
                TableRow(
                  children: [
                    _buildTableCell(
                      content: Text(
                        (i + 1).toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      alignment: Alignment.center,
                    ),
                    _buildTextField(
                      controller: _tourHighlightControllers[i], 
                      isPriceField: false, 
                      isSlotField: false, 
                      text: _tourHighlights[i]['description'] ?? '', 
                      hintText: 'Description...',
                      onChanged: (newText) => _updateTextField(
                        _tourHighlightControllers, 
                        i, 
                        newText, 
                        _tourHighlights, 
                        'description')
                    ),
                    // _displayDataInTextField(_tourHighlightControllers[i], _tourHighlights[i]['description'] ?? '', 'description'),
                    _buildDeleteButton(i, "tourHighlight"),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget itinerarySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Itinerary",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10,),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.5),
              1: FlexColumnWidth(1.1),
              2: FlexColumnWidth(1.7),
              3: FlexColumnWidth(0.4),
            },
            border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
            children: [
              TableRow(
                children: [
                  _buildTableHeaderCell('Day'),
                  _buildTableHeaderCell('Title'),
                  _buildTableHeaderCell('Description'),
                  _buildTableHeaderCell(''),
                ],
              ),
              for (int i = 0; i < _itinerary.length; i++)
                TableRow(
                  children: [
                    _buildTableCell(
                      content: Text(
                        (i + 1).toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      alignment: Alignment.center,
                    ),
                    _buildTextField(
                      controller: _itineraryTitleControllers[i], 
                      isPriceField: false, 
                      isSlotField: false, 
                      text: _itinerary[i]['title'] ?? '', 
                      hintText: 'Title...',
                      onChanged: (newText) => _updateTextField(
                        _itineraryTitleControllers, 
                        i, 
                        newText, 
                        _itinerary, 
                        'title')
                    ),
                    _buildTextField(
                      controller: _itineraryDescriptionControllers[i], 
                      isPriceField: false, 
                      isSlotField: false, 
                      text: _itinerary[i]['description'] ?? '', 
                      hintText: 'Description...',
                      onChanged: (newText) => _updateTextField(
                        _itineraryDescriptionControllers, 
                        i, 
                        newText, 
                        _itinerary, 
                        'description')
                    ),
                    _buildDeleteButton(i, "itinerary"),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget flightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Flight Info",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 10,),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.45),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
              3: FlexColumnWidth(1.1),
              4: FlexColumnWidth(0.4),
            },
            border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
            children: [
              TableRow(
                children: [
                  _buildTableHeaderCell("No"),
                  _buildTableHeaderCell("Depart"),
                  _buildTableHeaderCell("Return"),
                  _buildTableHeaderCell("Flight"),
                  _buildTableHeaderCell(""),
                ],
              ),
              for (int i = 0; i < _flight.length; i++)
                TableRow(
                  children: [
                    _buildTableCell(
                      content: Text(
                        (i + 1).toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      alignment: Alignment.center,
                    ),
                    _buildDatePickerTextFieldCell(
                      _flightDepartDateControllers[i], 
                      _flight[i]['departDate'] ?? '', 
                      'Pick a date',
                      index: i,
                      flightList: _flight,
                      onDateSelected: (DateTime selectedDate) {
                        // Update the return date controller's first date
                        DateTime firstReturnDate = selectedDate.add(const Duration(days: 1));
                        _updateReturnDatePicker(i, firstReturnDate);
                      },
                    ),
                    _buildDatePickerTextFieldCell(
                      _flightReturnDateControllers[i], 
                      _flight[i]['returnDate'] ?? '', 
                      'Pick a date',
                      index: i,
                      flightList: _flight,
                      firstDate: _getFirstReturnDate(i),
                      isReturnDate: true,
                      departDateSelected: _flightDepartDateControllers[i].text.isNotEmpty,
                    ),
                    _buildTextField(
                      controller: _flightNameControllers[i], 
                      isPriceField: false, 
                      isSlotField: false, 
                      text: _flight[i]['flightName'] ?? '', 
                      hintText: 'Flight name...',
                      onChanged: (newText) => _updateTextField(
                        _flightNameControllers, 
                        i, 
                        newText, 
                        _flight, 
                        'flightName')
                    ),
                    _buildDeleteButton(i, "flight"),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget availabilitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Availability",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF467BA1), width: 1.5),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(0.4),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(0.6),
              3: FlexColumnWidth(1.1),
            },
            border: TableBorder.all(color: const Color(0xFF467BA1), width: 1.5),
            children: [
              TableRow(
                children: [
                  _buildTableHeaderCell("No"),
                  _buildTableHeaderCell("Date Range"),
                  _buildTableHeaderCell("Slot"),
                  _buildTableHeaderCell("Price"),
                ],
              ),
              for (int i = 0; i < _availability.length; i++)
                if (i < _availableDateRangeControllers.length && 
                    i < _availableSlotControllers.length && 
                    i < _priceControllers.length)
                  TableRow(
                    children: [
                      _buildTableCell(
                        content: Text(
                          (i + 1).toString(),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        alignment: Alignment.center,
                      ),
                      _buildDateRangeTextFieldCell(_availableDateRangeControllers[i], _availability[i]['dateRange'] ?? '', 'Date range'),
                      _buildTextField(
                        controller: _availableSlotControllers[i],
                        isPriceField: false,
                        isSlotField: true,
                        text: _availability[i]['slot'].toString(),
                        hintText: 'Slot',
                        onChanged: (newText) => _updateTextField(
                          _availableSlotControllers, 
                          i, 
                          newText, 
                          _availability, 
                          'slot')
                      ),
                      _buildTextField(
                        controller: _priceControllers[i],
                        isPriceField: true,
                        isSlotField: false,
                        text: _availability[i]['price'].toString(),
                        hintText: 'Price',
                        onChanged: (newText) => _updateTextField(
                          _priceControllers, 
                          i, 
                          newText, 
                          _availability, 
                          'price')
                      ),
                    ],
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Widget tourImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Tour Package Cover",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () async {
                // Select a new image
                await selectImage();
              },
              icon: const Icon(
                Icons.edit,
                size: 25,
                color: Color(0xFF467BA1),
              ),
            ),
          ],
        ),
        _image != null // If a new image is selected from memory
          ? Container(
              width: double.infinity,
              height: 200,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF467BA1), width: 3),
              ),
              child: Image.memory(
                _image!,
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
                        'Insert image to preview',
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

  Widget brochure() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Brochure",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () async {
                // Select a new image
                await selectPdfFile();
              },
              icon: const Icon(
                Icons.edit,
                size: 25,
                color: Color(0xFF467BA1),
              ),
            ),
          ],
        ),
        TextField(
          controller: _brochureController,
          readOnly: true,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          decoration: InputDecoration(
            hintText: 'Upload a PDF file...',
            hintStyle: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(
                color: Color(0xFF467BA1),
                width: 2.5,
              ),
            ),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: IconButton(
              icon: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF467BA1),
                size: 30,
              ),
              onPressed: () {
                Navigator.push(
                  context, 
                  MaterialPageRoute(
                    builder: (context) => TravelAgentViewPDFScreen(
                      pdfPath: _uploadedPdfFile != null ? _uploadedPdfFile!.path : brochurePath,
                      savedToFirebase: _uploadedPdfFile != null ? false : true))
                );
              }
            ),
          ),
        )
      ],
    );
  }

  Widget _buildTableHeaderCell(String label) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: const Color(0xFF467BA1).withOpacity(0.6),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCell({required Widget content, Alignment alignment = Alignment.centerLeft}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: Color(0xFF467BA1), width: 1.0),
        ),
      ),
      alignment: alignment,
      child: content,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required bool isPriceField,
    required bool isSlotField,
    dynamic text,
    required String hintText,
    required Function(String) onChanged,
  }) {
    // Only set controller text if `text` is a non-empty String
    if (text != null) {
      if (text is String && text.isNotEmpty) {
        controller.text = text;
      } else if (text is int || text is double) {
        controller.text = text.toString();
      }
    }

    // Common container decoration
    final containerDecoration = const BoxDecoration(
      color: Colors.white,
      border: Border(
        left: BorderSide(color: Color(0xFF467BA1), width: 1.0),
      ),
    );

    // Common text styles
    final commonTextStyle = const TextStyle(
      fontWeight: FontWeight.w500,
    );

    // Return the TextField widget based on the conditions
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      decoration: containerDecoration,
      child: TextField(
        controller: controller,
        style: commonTextStyle.copyWith(fontSize: isPriceField ? 15 : 14),
        keyboardType: isPriceField || isSlotField ? TextInputType.number : TextInputType.multiline,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
          prefixText: isPriceField ? "RM" : '',
          prefixStyle: isPriceField
              ? const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                )
              : null,
          suffixText: isPriceField ? ".00" : '',
          suffixStyle: isPriceField
              ? const TextStyle(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                )
              : null,
        ),
        maxLines: isSlotField ? 1 : null, // Multiline or single line based on slot field
        textAlign: isPriceField
            ? TextAlign.end
            : (isSlotField ? TextAlign.center : TextAlign.justify),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDateRangeTextFieldCell(TextEditingController controller, dynamic text, String hintText) {
    // Only set controller text if `text` is not empty
    if (text != null && text.isNotEmpty) {
      controller.text = text.toString();
    }

    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFF467BA1), width: 1.0),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800
          )
        ),
        maxLines: null, // Allows multiline input
        readOnly: true,
      ),
    );
  }

  Widget _buildDatePickerTextFieldCell(
      TextEditingController controller, 
      String text,
      String hintText, 
      {DateTime? firstDate, 
      void Function(DateTime)? onDateSelected, 
      bool isReturnDate = false, 
      bool departDateSelected = true,
      required int index, 
      required List<Map<String, dynamic>> flightList}) 
  {
    // Only set controller text if `text` is not empty
    if (text.isNotEmpty) {
      controller.text = text;
    }

    return Container(
      padding: const EdgeInsets.only(left: 5, right: 5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: Color(0xFF467BA1), width: 1.0),
        ),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800
          )
        ),
        readOnly: true, // Prevents keyboard from appearing
        textAlign: TextAlign.center,
        onTap: () async {
          if (isReturnDate && !departDateSelected) {
            // Show a message asking the user to select the departure date first
            _showSelectDepartDateFirstMessage();
            return;
          }

          DateTime initialDate = firstDate ?? DateTime.now();
          DateTime firstAvailableDate = firstDate ?? DateTime.now();

          // Show date picker with a minimum date constraint
          DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: initialDate,
            firstDate: firstAvailableDate,
            lastDate: DateTime(2101),
          );

          if (pickedDate != null) {
            // Format the date
            String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
            setState(() {
              controller.text = formattedDate;

              if (isReturnDate) {
                flightList[index]['returnDate'] = formattedDate;
                _updateAvailabilityRanges(); // Update availability ranges
              } else {
                // Check if the new depart date is after the current return date
                DateTime? returnDate = _parseDate(flightList[index]['returnDate']);
                if (returnDate != null && returnDate.isBefore(pickedDate)) {
                  // Clear the return date if it's before the new depart date
                  flightList[index]['returnDate'] = '';
                  _flightReturnDateControllers[index].clear();
                }
                flightList[index]['departDate'] = formattedDate;
                _updateAvailabilityRanges(); // Update availability ranges
              }

              if (onDateSelected != null) {
                onDateSelected(pickedDate);
              }
            });
          }
        },
      ),
    );
  }


  DateTime? _parseDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return null;
    }
    try {
      return DateFormat('dd/MM/yyyy').parse(dateStr);
    } catch (e) {
      print("Error parsing date: $e");
      return null;
    }
  }

  Widget _buildDeleteButton(int index, String rowType) {
    return Container(
      alignment: Alignment.topLeft,
      child: IconButton(
        icon: const Icon(Icons.delete_rounded),
        color: Colors.black54,
        iconSize: 20,
        onPressed: () {
          if (index == 0 && _getRowCount(rowType) == 1){
            _clearFirstRow(rowType);
          } else{
            if (rowType == 'itinerary') {
              _removeItineraryRow(index);
            } else if (rowType == 'tourHighlight') {
              _removeTourHighlightRow(index);
            } else if (rowType == 'flight') {
              _removeFlightRow(index);
            } else if (rowType == 'availability') {
              _removeAvailabilityRow(index);
            }
          }
        },
      ),
    );
  }

  // Method to get the row count for the given row type
  int _getRowCount(String rowType) {
    if (rowType == 'itinerary') {
      return _itinerary.length;
    } else if (rowType == 'tourHighlight') {
      return _tourHighlights.length;
    } else if (rowType == 'flight') {
      return _flight.length;
    } else if (rowType == 'availability') {
      return _availability.length;
    }
    return 0;
  }

  // Method to clear the text in the first row
  void _clearFirstRow(String rowType) {
    if (rowType == 'itinerary') {
      _itineraryTitleControllers[0].clear();
      _itineraryDescriptionControllers[0].clear();
    } else if (rowType == 'tourHighlight') {
      _tourHighlightControllers[0].clear();
    } else if (rowType == 'flight') {
      _flightDepartDateControllers[0].clear();
      _flightReturnDateControllers[0].clear();
      _flightNameControllers[0].clear();
      _updateAvailabilityRanges();
    } else if (rowType == 'availability') {
      _availableDateRangeControllers[0].clear();
      _availableSlotControllers[0].clear();
      _priceControllers[0].clear();
    }
  }

}

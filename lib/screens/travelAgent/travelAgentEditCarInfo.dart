import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:assignment_tripmate/autocomplete_predictions.dart';
import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/network_utility.dart';
import 'package:assignment_tripmate/place_auto_complete_response.dart';
import 'package:assignment_tripmate/saveImageToFirebase.dart';
import 'package:assignment_tripmate/screens/travelAgent/travelAgentViewCarInfo.dart';
import 'package:assignment_tripmate/utils.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TravelAgentEditCarInfoScreen extends StatefulWidget {
  final String userId;
  final String carId;

  const TravelAgentEditCarInfoScreen({
    super.key,
    required this.userId,
    required this.carId,
  });

  @override
  State<StatefulWidget> createState() => _TravelAgentEditCarInfoScreenState();
}

class _TravelAgentEditCarInfoScreenState extends State<TravelAgentEditCarInfoScreen>{
  List<String> _carType = ['SUV', 'Sedan', 'MPV', 'Hatchback'];
  List<String> _transmissionType = ['Auto', 'Manual'];
  List<String> _fuelType = ['Petrol', 'Electricity', 'Hybrid'];

  String? selectedCarType;
  String? selectedTransmission;
  String? selectedFuel;
  String? selectedStatus;

  TextEditingController _carNameController = TextEditingController();
  TextEditingController _seatController = TextEditingController();
  TextEditingController _carImageController = TextEditingController();
  TextEditingController _pickUpLocationController = TextEditingController();
  TextEditingController _dropOffLocationController = TextEditingController();
  TextEditingController _pricingController = TextEditingController();
  TextEditingController _rentalPolicyController = TextEditingController();
  TextEditingController _insuransCoverageController = TextEditingController();
  TextEditingController _carConditionController = TextEditingController();

  Uint8List? _carImage;

  List<AutoCompletePredictions> placedPredictions = [];
  List<AutoCompletePredictions> dropPlacedPredictions = [];
  bool isLoading = false;
  bool isFetching = false;
  String? agencyName;
  String? agencyContact;
  String? existingImagePath;

  @override
  void initState() {
    super.initState();
    _fetchCarData();
  }

  Future<void> _fetchCarData() async {
    setState(() {
      isFetching = true;
    });
    try{
      DocumentReference CarRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carId);
      DocumentSnapshot carSnapshot = await CarRef.get();

      if(carSnapshot.exists){
        Map<String, dynamic>? data = carSnapshot.data() as Map<String, dynamic>?;

        setState(() {
          isFetching = false;

          _carNameController.text = data?['carModel'] ?? '';
          selectedCarType = data?['carType'] ?? '';
          selectedTransmission = data?['transmission'] ?? '';
          _seatController.text = data?['seat'].toString() ?? '';
          selectedFuel = data?['fuel'] ?? '';
          _pickUpLocationController.text = data?['pickUpLocation'] ?? '';
          _dropOffLocationController.text = data?['dropOffLocation'] ?? '';
          _pricingController.text = data?['pricePerDay'].toStringAsFixed(0) ?? '';
          _insuransCoverageController.text = data?['insurance'] ?? '';
          _carConditionController.text = data?['carCondition'] ?? '';
          _rentalPolicyController.text = data?['rentalPolicy'] ?? '';
          existingImagePath = data?['carImage'] ?? '';
        });
      } else{
        setState(() {
          isFetching = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Current car model does not exists in the system')),
          );
        });
      }
    }catch(e){
      setState(() {
        isFetching = false;
      });
      print("Error fetch car details: $e");
    }
  }

  Future<void> selectImage() async {
    Uint8List? img = await ImageUtils.selectImage(context);
    if (img != null) {
      setState(() {
        _carImage = img;
        _carImageController.text = 'Image Selected'; 
      });
    }
  }

  void placeAutoComplete(String query) async{
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json", /// unencoder path
      {
        "input": query,
        "key": apiKey,
      }
    );

    // Make GET request
    String? response = await NetworkUtility.fetchUrl(uri);

    if(response != null){
      PlaceAutoCompleteResponse result = PlaceAutoCompleteResponse.parseAutoCompleteResult(response);

      if(result.predictions != null){
        setState(() {
          placedPredictions = result.predictions!;    
        });
        
      }
    } 
  }

  void dropPlaceAutoComplete(String query) async{
    Uri uri = Uri.https(
      "maps.googleapis.com",
      "maps/api/place/autocomplete/json", /// unencoder path
      {
        "input": query,
        "key": apiKey,
      }
    );

    // Make GET request
    String? response = await NetworkUtility.fetchUrl(uri);

    if(response != null){
      PlaceAutoCompleteResponse result = PlaceAutoCompleteResponse.parseAutoCompleteResult(response);

      if(result.predictions != null){
        setState(() {
          dropPlacedPredictions = result.predictions!;    
        });
        
      }
    } 
  }

  Future<void> fetchTravelAgencyNameAndContact() async {
    try {
      QuerySnapshot userQuery = await FirebaseFirestore.instance
        .collection('travelAgent')
        .where('id', isEqualTo: widget.userId)
        .limit(1)
        .get();
      
      DocumentSnapshot userDoc = userQuery.docs.first;
      var agencyData = userDoc.data() as Map<String, dynamic>;

      setState(() {
        agencyName = agencyData['companyName'];
        agencyContact = agencyData['companyContact'];
      });
    } catch (e) {
      print("Error fetching agency details: $e");
    }
  }

  Future<Uint8List> _getImageFromURL(String imageUrl) async {
    final response = await http.get(Uri.parse(imageUrl));
    return response.bodyBytes;
  }

  // Add car details to database
  Future<void> _updateCar() async {
    setState(() {
      isLoading = true;
    });

    final firestore = FirebaseFirestore.instance;

    try {
      // Check for empty fields and provide feedback
      if (_carNameController.text.isEmpty || selectedCarType == null || selectedTransmission == null || 
          _seatController.text.isEmpty || selectedFuel == null || 
          _pickUpLocationController.text.isEmpty || _dropOffLocationController.text.isEmpty || 
          _pricingController.text.isEmpty || _insuransCoverageController.text.isEmpty || 
          _carConditionController.text.isEmpty || _rentalPolicyController.text.isEmpty) {
        
        setState(() {
          isLoading = false;
        });

        showCustomDialog(
          context: context, 
          title: 'Incomplete Information', 
          content: 'Please fill in all the fields before submitting.',
          onPressed: () {
            Navigator.of(context).pop();
          }
        );

        return; // Exit early
      }

      Uint8List? carImageToUpload;

      if (_carImage != null) {
          carImageToUpload = _carImage!;
        } else if (existingImagePath != null && existingImagePath!.isNotEmpty) {
          // Fetch the existing image from URL
          carImageToUpload = await _getImageFromURL(existingImagePath!);
        } else {
          // Handle case where no image is provided
          throw Exception("Tour cover image is required.");
        }

      String resp = await StoreData().saveCarRentalData(
        carID: widget.carId, 
        carModel: _carNameController.text, 
        carType: selectedCarType!, 
        transmission: selectedTransmission!, 
        seat: int.tryParse(_seatController.text) ?? 0, 
        fuel: selectedFuel!, 
        carImage: carImageToUpload, 
        pickUpLocation: _pickUpLocationController.text, 
        dropOffLocation: _dropOffLocationController.text, 
        price: double.tryParse(_pricingController.text) ?? 0.0, 
        insurance: _insuransCoverageController.text, 
        carCondition: _carConditionController.text, 
        rentalPolicy: _rentalPolicyController.text, 
        agencyID: widget.userId,
        action: 2
      );

      // After successfully saving
      setState(() {
        isLoading = false;
      });

      showCustomDialog(
        context: context, 
        title: 'Successful', 
        content: 'You have updated the car details successfully.', 
        onPressed: () {
          Navigator.push(
            context, 
            MaterialPageRoute(
              builder: (context) => TravelAgentViewCarListingScreen(userId: widget.userId)
            )
          );
        }
      );

    } catch (e) {
      print('Error: $e'); // For debugging
      setState(() {
        isLoading = false;
      });

      showCustomDialog(
        context: context, 
        title: 'Failed', 
        content: 'Something went wrong: $e.', 
        onPressed: () {
          Navigator.of(context).pop();
        }
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Car Rental"),
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
              MaterialPageRoute(builder: (context) => TravelAgentViewCarListingScreen(userId: widget.userId))
            );
          },
        ),
      ),
      body:Stack(
        children: [
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
                    "Car Information",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_carNameController, 'Enter car model', 'Car Model'),
                  SizedBox(height: 20,),
                  buildDropDownList(
                    _carType, 
                    'Select category of car', 
                    'Car Type', 
                    selectedCarType, 
                    (newValue){
                      setState(() {
                        selectedCarType = newValue;
                      });
                    }
                  ),
                  // SizedBox(height: 20,),
                  // buildDropDownList(_carBrand, 'Select brand of car', 'Car Brand', selectedBrand),
                  SizedBox(height: 20,),
                  buildDropDownList(
                    _transmissionType, 
                    'Select type of transmission', 
                    'Transmission', 
                    selectedTransmission,
                    (newValue){
                      setState(() {
                        selectedTransmission = newValue;
                      });
                    }
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_seatController, 'Enter number of seats', 'Number of Seats', isIntField: true),
                  SizedBox(height: 20,),
                  buildDropDownList(
                    _fuelType, 
                    'Select type of fuel', 
                    'Fuel Type', 
                    selectedFuel,
                    (newValue){
                      setState(() {
                        selectedFuel = newValue;
                      });
                    }
                  ),
                  SizedBox(height: 20,),
                  carImage(),
                  SizedBox(height: 30,), 

                  const Text(
                    "Location",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        onChanged: (value) {
                          placeAutoComplete(value);
                        },
                        controller: _pickUpLocationController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: defaultFontSize,
                          overflow: TextOverflow.visible,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search pick up location of car...",
                          labelText: "Pick Up Location",
                          prefixIcon: Icon(
                            Icons.location_on,
                            size: 25,
                            color: primaryColor,
                          ),
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
                        maxLines: null,
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 10,),
                      if (placedPredictions.isNotEmpty) 
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF467BA1), width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: List.generate(placedPredictions.length, (index) {
                              return ListTile(
                                title: Text(placedPredictions[index].description!),
                                onTap: () {
                                  // Handle selection
                                  _pickUpLocationController.text = placedPredictions[index].description!;
                                  setState(() {
                                    placedPredictions.clear(); // Clear predictions after selection
                                  });
                                },
                              );
                            }),
                          ),
                        ),
                    ]
                  ),
                  SizedBox(height: 10,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        onChanged: (value) {
                          dropPlaceAutoComplete(value);
                        },
                        controller: _dropOffLocationController,
                        textInputAction: TextInputAction.search,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: defaultFontSize,
                          overflow: TextOverflow.visible,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search drop off location of car...",
                          labelText: "Drop Off Location",
                          prefixIcon: Icon(
                            Icons.location_on,
                            size: 25,
                            color: primaryColor,
                          ),
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
                        maxLines: null,
                        textAlign: TextAlign.justify,
                      ),
                      SizedBox(height: 10,),
                      if (dropPlacedPredictions.isNotEmpty) 
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF467BA1), width: 2.5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            children: List.generate(dropPlacedPredictions.length, (index) {
                              return ListTile(
                                title: Text(dropPlacedPredictions[index].description!),
                                onTap: () {
                                  // Handle selection
                                  _dropOffLocationController.text = dropPlacedPredictions[index].description!;
                                  setState(() {
                                    dropPlacedPredictions.clear(); // Clear predictions after selection
                                  });
                                },
                              );
                            }),
                          ),
                        ),
                    ]
                  ),
                  SizedBox(height: 30,), 

                  const Text(
                    "Pricing Information",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_pricingController, 'Enter price', 'Price (RM/per day)', isIntField: true),
                  // SizedBox(height: 20,),
                  // buildTextField(_discountController, 'Enter discount price', 'Discount Price (RM/per day)', isIntField: true),
                  SizedBox(height: 30,), 

                  const Text(
                    "Insurance",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_insuransCoverageController, 'Specify available insurance coverage or add-ons', 'Insurance Coverage'),
                  SizedBox(height: 30,), 

                  const Text(
                    "Car Condition",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: defaultLabelFontSize,
                    ),
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_carConditionController, "Describe the car's condition or any recent maintenance", 'Car Condition'),
                  SizedBox(height: 30,), 

                  const Text(
                    "Rental Policy",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                      fontSize: defaultLabelFontSize,
                    ),
                  ),
                  SizedBox(height: 20,),
                  buildTextField(_rentalPolicyController, "State the rental policy clearly", 'Rental Policy'),
                  SizedBox(height: 30,), 

                  Container(
                    width: double.infinity,
                    height: getScreenHeight(context) * 0.08,
                    child: ElevatedButton(
                      onPressed: (){_updateCar();},
                      child: isLoading
                        ? CircularProgressIndicator()
                        : Text(
                            'Update',
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
                ]
              )
            )
          )
        ],
      )
    );
  }

  Widget buildTextField(TextEditingController controller,String hintText, String label, {bool isIntField = false}){
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

  Widget carImage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Car Image",
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
        _carImage != null // If a new image is selected from memory
          ? Container(
              width: double.infinity,
              height: 150,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF467BA1), width: 3),
              ),
              child: Image.memory(
                _carImage!,
                fit: BoxFit.contain,
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
                  fit: BoxFit.contain,
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

}
import 'dart:convert';

import 'package:assignment_tripmate/screens/admin/manageCarList.dart';
import 'package:http/http.dart' as http;
import 'package:assignment_tripmate/constants.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class AdminViewCarRentalDetailsScreen extends StatefulWidget {
  final String userId;
  final String carId;

  const AdminViewCarRentalDetailsScreen({super.key, required this.userId, required this.carId});

  @override
  State<StatefulWidget> createState() => _AdminViewCarRentalDetailsScreenState();
}

class _AdminViewCarRentalDetailsScreenState extends State<AdminViewCarRentalDetailsScreen> {
  Map<String, dynamic>? carData;
  bool isLoading = true;
  LatLng targetCarLocation = LatLng(0, 0);
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _fetchCarDetails();
  }

  Future<void> _fetchCarDetails() async {
    setState(() {
      isLoading = true;
    });

    try {
      DocumentReference carRef = FirebaseFirestore.instance.collection('car_rental').doc(widget.carId);
      DocumentSnapshot carSnapshot = await carRef.get();

      if (carSnapshot.exists) {
        setState(() {
          carData = carSnapshot.data() as Map<String, dynamic>?;
        });
              
        // Convert the pickup location to LatLng
        await _fetchCoordinates(carSnapshot['pickUpLocation']);

      } else {
        _showSnackBar('Car not found');
      }
    } catch (e) {
      _showSnackBar('Error fetching car data: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchCoordinates(String address) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          double lat = data['results'][0]['geometry']['location']['lat'];
          double lng = data['results'][0]['geometry']['location']['lng'];
          setState(() {
            targetCarLocation = LatLng(lat, lng);

            // Add marker at the target location
            _markers.add(
              Marker(
                markerId: MarkerId('targetLocation'),
                position: targetCarLocation,
                infoWindow: InfoWindow(
                  title: 'Car Location',
                ),
              ),
            );
          });
        } else {
          _showSnackBar('No locations found for the provided address.');
        }
      } else {
        _showSnackBar('Error fetching location data.');
      }
    } catch (e) {
      _showSnackBar('Error fetching location data: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
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
          fontSize: defaultAppBarTitleFontSize,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => AdminManageCarListScreen(userId: widget.userId))
            );
          },
        ),

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor,))
          : Stack(
              children: [
                Container(
                  height: getScreenHeight(context) * 0.3,
                  child: GoogleMap(

                    markers: _markers,
                    initialCameraPosition: CameraPosition(
                      target: targetCarLocation,
                      zoom: 13
                    ),
                    mapType: MapType.normal,
                  ),
                ),
                SizedBox(height: getScreenHeight(context) * 0.9,),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Color(0xFF749CB9),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.4), // Adjust shadow color and opacity as needed
                              blurRadius: 10.0,
                              offset: Offset(0, -4), // Shadow above the container
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              carData?['carModel'] ?? 'Car Model not available',
                              style: const TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildAgencyInfo(),
                                _buildAgencyContact(),
                              ],
                            )
                          ],
                        ),
                      ),
                      _buildScrollView(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAgencyInfo() {
    return Row(
      children: [
        const Icon(Icons.support_agent, color: Colors.white, size: 20),
        const SizedBox(width: 5),
        Text(
          carData?['agencyName'] ?? 'N/A',
          style: const TextStyle(color: Colors.white, fontSize: defaultFontSize),
        ),
      ],
    );
  }

  Widget _buildAgencyContact() {
    return Row(
      children: [
        const Icon(Icons.phone, color: Colors.white, size: 20),
        const SizedBox(width: 5),
        Text(
          carData?['agencyContact'] ?? 'N/A',
          style: const TextStyle(color: Colors.white, fontSize: defaultFontSize),
        ),
      ],
    );
  }

  Widget _buildScrollView() {
    return Container(
      height: getScreenHeight(context) * 0.50, // Fixed height for the scrollable container
      decoration: const BoxDecoration(color: Colors.white),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Car Info", style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              _buildCarInfoRow(),
              const SizedBox(height: 15),
              _buildLocationSection(),
              const SizedBox(height: 15),
              _buildConditionSection(),
              const SizedBox(height: 15),
              _buildInsuranceSection(),
              const SizedBox(height: 15),
              _buildRentalPolicySection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarInfoRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        carInfoIcon(
          carData?['transmission'] == "Auto"
              ? const AssetImage("images/automatic-transmission.png")
              : const AssetImage("images/gearbox.png"),
          carData?['transmission'] ?? 'N/A',
          'Transmission',
        ),
        carInfoIcon(
          carData?['fuel'] == "Petrol"
              ? const AssetImage("images/gasoline.png")
              : carData?['fuel'] == "Electricity"
                  ? const AssetImage("images/charging-station.png")
                  : const AssetImage("images/hybrid-car.png"),
          carData?['fuel'] ?? 'N/A',
          'Fuel',
        ),
        carInfoIcon(
          const AssetImage("images/car.png"),
          carData!['carType'].toString(),
          'Car Type',
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Location", style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        _buildLocationContainer('Pick Up Location', carData?['pickUpLocation']),
      ],
    );
  }

  Widget _buildLocationContainer(String title, String? location) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: primaryColor, width: 1.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding( // Adding some padding to avoid text touching the container's border
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
          children: [
            Text(
              'Pick Up Location',
              style: TextStyle(
                fontSize: defaultFontSize,
                fontWeight: FontWeight.w600,
                ),
            ),
            SizedBox(height: 5), // Adding some space between the title and the content
            Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  carData!['pickUpLocation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Drop Off Location',
            style: TextStyle(
            fontSize: defaultFontSize,
            fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 5), // Adding some space between the title and the content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                size: 20,
                color: primaryColor,
              ),
              SizedBox(width: 5),
              Flexible( // Wraps the text, allowing it to wrap properly within the row and container
                child: Text(
                  carData!['dropOffLocation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: defaultFontSize,
                  ),
                  maxLines: null,
                  overflow: TextOverflow.visible, 
                  textAlign: TextAlign.justify,
                ),
              ),
            ],
          ),
        ] ,
        ),
      ),
    );
  }

  Widget _buildConditionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Car Condition",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['carCondition'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInsuranceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Insurance",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['insurance'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRentalPolicySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Rental Policy",
          style: TextStyle(fontSize: defaultLabelFontSize, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: primaryColor, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0), // Adding some padding to avoid text touching the container's border
            child: Text(
              carData!['rentalPolicy'],
              style: TextStyle(
                fontSize: defaultFontSize,
              ),
              textAlign: TextAlign.justify,
              maxLines: null,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      ],
    );
  }

  Widget carInfoIcon(AssetImage image, String title, String subtitle) {
    return Container(
      width: 100,
      height: 100,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF749CB9), width: 1.5),
      ),
      child: Column(
        children: [
          const SizedBox(height: 5),
          Image(image: image, width: 30, height: 30),
          const SizedBox(height: 10),
          Text(title),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }
}

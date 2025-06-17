import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

final FirebaseStorage _storage = FirebaseStorage.instance;
final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class StoreData {
  Future<String> uploadImageToStorage(String childName, Uint8List file) async{
    
    Reference ref = _storage.ref().child(childName);
    UploadTask uploadTask = ref.putData(file);
    TaskSnapshot snapshot = await uploadTask;
    String downloadURL = await snapshot.ref.getDownloadURL();
    return downloadURL;
  }

  Future<String> uploadPdfToStorage(String childName, File file) async {
    // Convert File to Uint8List
    Uint8List fileData = await file.readAsBytes();

    // Create a reference to the location you want to upload to in Firebase Storage
    Reference ref = _storage.ref().child(childName);

    // Start the upload task
    UploadTask uploadTask = ref.putData(
      fileData,
      SettableMetadata(contentType: 'application/pdf'), // Set the content type as PDF
    );

    // Wait for the upload to complete and get the snapshot
    TaskSnapshot snapshot = await uploadTask;

    // Retrieve the download URL
    String downloadURL = await snapshot.ref.getDownloadURL();

    return downloadURL;
  }

  Future<String> updateUserProfile({
    required String userId,
    required String name,
    required String username,
    required String email,
    required String contact,
    required String address,
    Uint8List? file, // Make file nullable
  }) async {
    String resp = "Some Error Occurred";
    try {
      String? imageURL;

      if (file != null) {
        String fileName = "$userId($name).jpg";
        imageURL = await uploadImageToStorage("profile_images/users/$fileName", file);
      }

      // Prepare the update data
      Map<String, dynamic> updateData = {
        'name': name,
        'username': username,
        'email': email,
        'contact': contact,
        'address': address,
      };

      // Add profileImage to updateData only if it's not null
      if (imageURL != null) {
        updateData['profileImage'] = imageURL;
      }

      // Update the Firestore document
      await _firestore.collection("users").doc(userId).update(updateData);

      resp = "Success";
    } catch (err) {
      resp = err.toString();
    }
    return resp;
  }

  Future<String> updateTravelAgentProfile({
    required String userId, 
    required String name, 
    required String username, 
    required String email, 
    required String companyName, 
    required String companyContact, 
    required String companyAddress, 
    Uint8List? file, // Make file parameter optional
    Uint8List? employeeCard,
    int? accountStatus
  }) async {
    String resp = "Some Error Occurred";
    try {
      String? imageURL;
      String? employeeCardURL;

      if (file != null) {
        String fileName = "$userId($name).jpg"; 
        imageURL = await uploadImageToStorage("profile_images/travelAgent/$fileName", file);
      }

      if (employeeCard != null){
        String filename = "$userId-$companyName.jpg"; 
        employeeCardURL = await uploadImageToStorage("travelAgent(employee card)/$filename", employeeCard);
      }

      // Build the update data map with only non-null values
      Map<String, dynamic> updateData = {
        'name': name,
        'username': username,
        'email': email,
        'companyName': companyName,
        'companyContact': companyContact,
        'companyAddress': companyAddress,
      };

      // Only include 'profileImage' if a new image is provided
      if (imageURL != null) {
        updateData['profileImage'] = imageURL;
      }

      if (employeeCardURL != null){
        updateData['employeeCardPath'] = employeeCardURL;
      }

      if (accountStatus != null){
        updateData['accountApproved'] = accountStatus;
      }

      await _firestore.collection("travelAgent").doc(userId).update(updateData);
      resp = "Success";
    } catch (err) {
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveCountryData({
    required String country, 
    required String countryID, 
    required Uint8List file,
    required int type,
  }) async{
    String resp = "Some Error Occurred";
    try{
      String fileName = "$country.jpg"; 
      String imageURL = await uploadImageToStorage("countries/$country/$fileName", file);

      if(type == 0){
        await _firestore.collection("countries").doc(country).set({
          'name': country,
          'countryID': countryID,
          'countryImage': imageURL
        });
      } else{
        await _firestore.collection("countries").doc(country).update({
          'name': country,
          'countryID': countryID,
          'countryImage': imageURL
        });
      }
      
      resp = "Success";
    } catch(err){
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveCityData({
    required String country, 
    required String city, 
    required String cityID, 
    required Uint8List file,
    required int type,
  }) async{
    String resp = "Some Error Occurred";
    try{
      String fileName = "$city.jpg"; 
      String imageURL = await uploadImageToStorage("countries/$country/$fileName", file);

      if(type == 0){
        await _firestore.collection("countries").doc(country).collection("cities").doc(city).set({
          'city_name': city,
          'cityID': cityID,
          'cityImage': imageURL
        });
      } else{
        await _firestore.collection("countries").doc(country).collection("cities").doc(city).update({
          'city_name': city,
          'cityID': cityID,
          'cityImage': imageURL
        });
      }
      resp = "Success";
    } catch(err){
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveTAData({
    required String name, 
    required String TAid, 
    required String companyID,
    required String email,
    required DateTime dob,
    required String companyContact, 
    required String companyName,
    required String companyAddress,
    required String password,
    required String gender,
    required Uint8List employeeCard,
  }) async{
    String resp = "Some Error Occurred";
    try{
      String fileName = "$TAid-$companyName.jpg"; 
      String imageURL = await uploadImageToStorage("travelAgent(employee card)/$fileName", employeeCard);
      await _firestore.collection("travelAgent").doc(TAid).set({
        'id': TAid,
        'name': name,
        'username': null,
        'email': email,
        'dob': dob,
        'companyID': companyID,
        'companyContact': companyContact,
        'companyName': companyName,
        'companyAddress': companyAddress,
        'password': password,
        'gender': gender,
        'accountApproved': 0,
        'employeeCardPath': imageURL,
        'profileImage': null
      });
      resp = "Success";
    } catch(err){
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveTourPackageData({
    required String tourid, 
    required String tourName, 
    required String countryName,
    required String cityName,
    required String agency,
    required String companyID,
    required String agentID,
    required Map tourHighlightData,
    required Map itineraryData,
    required Map flightData, 
    required Map availabilityData,
    required Uint8List tourCover,
    required File pdfFile,
    required int isPublish,
  }) async {
    String resp = "Some Error Occurred";
    try {
      String fileName = "$tourName.jpg"; 
      String pdfFileName = "$tourName.pdf"; 

      String imageURL;
      String pdfURL;

      if (cityName.isNotEmpty) {
        imageURL = await uploadImageToStorage("tourPackage/$agency/$countryName/$cityName/$fileName", tourCover);
        pdfURL = await uploadPdfToStorage("tourPackage/$agency/$countryName/$cityName/$pdfFileName", pdfFile);
      } else {
        imageURL = await uploadImageToStorage("tourPackage/$agency/$countryName/$fileName", tourCover);
        pdfURL = await uploadPdfToStorage("tourPackage/$agency/$countryName/$pdfFileName", pdfFile);
      }

      // Add the converted list data to the Firestore document
      await _firestore.collection("tourPackage").doc(tourid).set({
        'tourID': tourid,
        'tourName': tourName,
        'agency': agency,
        'companyID': companyID,
        'agentID': agentID,
        'countryName': countryName,
        'cityName': cityName,
        'tourCover': imageURL,
        'brochure': pdfURL,
        'tourHighlight': tourHighlightData['tourHighlight'],
        'itinerary': itineraryData['itinerary'],
        'flight_info': flightData['flight_info'],
        'availability': availabilityData['availability'],
        'isPublish': isPublish
      });
      resp = "Success";
    } catch (err) {
      resp = err.toString();
    }
    return resp;
  }

  Future<String> updateTourPackageData({
    required String tourid,
    required String tourName,
    required String countryName,
    required String cityName,
    required String agency,
    required Map<String, dynamic> tourHighlightData,
    required Map<String, dynamic> itineraryData,
    required Map<String, dynamic> flightData,
    required Map<String, dynamic> availabilityData,
    required Uint8List tourCover,
    File? pdfFile, // Make pdfFile nullable
  }) async {
    String resp = "Some Error Occurred";
    try {
      String fileName = "$tourName.jpg";
      String pdfFileName = "$tourName.pdf";

      String imageURL;
      String? pdfURL; // Make pdfURL nullable

      // Upload image
      if (cityName.isNotEmpty) {
        imageURL = await uploadImageToStorage("tourPackage/$agency/$countryName/$cityName/$fileName", tourCover);
      } else {
        imageURL = await uploadImageToStorage("tourPackage/$agency/$countryName/$fileName", tourCover);
      }

      // Conditionally upload PDF
      if (pdfFile != null) {
        pdfURL = await uploadPdfToStorage("tourPackage/$agency/$countryName/$cityName/$pdfFileName", pdfFile);
      }

      // Prepare the data to update
      final updateData = {
        'tourName': tourName,
        'agency': agency,
        'tourCover': imageURL,
        'tourHighlight': tourHighlightData['tourHighlight'],
        'itinerary': itineraryData['itinerary'],
        'flight_info': flightData['flight_info'],
        'availability': availabilityData['availability'],
      };

      // Add PDF URL only if it's not null
      if (pdfURL != null) {
        updateData['brochure'] = pdfURL;
      }

      // Perform the update
      await _firestore.collection("tourPackage").doc(tourid).update(updateData);
      resp = "Success";
    } catch (err) {
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveCarBrandData({
    required String carBrandName, 
    required String carBrandID, 
    required Uint8List carBrandImage,
  }) async{
    String resp = "Some Error Occurred";
    try{
      String fileName = "$carBrandName.jpg"; 
      String imageURL = await uploadImageToStorage("carBrand/$carBrandName/$fileName", carBrandImage);
      await _firestore.collection("carBrand").doc(carBrandID).set({
        'carBrandName': carBrandName,
        'carBrandID': carBrandID,
        'carBrandImage': imageURL
      });
      resp = "Success";
    } catch(err){
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveCarRentalData({
    required String carID, 
    required String carModel, 
    required String carType, 
    required String transmission, 
    required int seat, 
    required String fuel, 
    required Uint8List carImage,
    required String pickUpLocation, 
    required String dropOffLocation, 
    required double price, 
    required String insurance, 
    required String carCondition, 
    required String rentalPolicy, 
    required String agencyID,
    String? agencyName,
    String? agencyContact,
    required int action
  }) async{
    String resp = "Some Error Occurred";
    try{
      String fileName = "$carModel.jpg"; 
      String imageURL = await uploadImageToStorage("car/$agencyID/$fileName", carImage);

      if(action == 1){
        await _firestore.collection("car_rental").doc(carID).set({
          'carID': carID,
          'carModel': carModel,
          'carType': carType,
          'transmission': transmission,
          'seat': seat,
          'fuel': fuel,
          'carImage': imageURL,
          'pickUpLocation': pickUpLocation,
          'dropOffLocation': dropOffLocation,
          'pricePerDay': price,
          'insurance': insurance,
          'carCondition': carCondition,
          'rentalPolicy': rentalPolicy,
          'agencyID': agencyID,
          'agencyName': agencyName ?? "",
          'agencyContact': agencyContact ?? ""
        });
      } else{
        await _firestore.collection("car_rental").doc(carID).update({
          'carID': carID,
          'carModel': carModel,
          'carType': carType,
          'transmission': transmission,
          'seat': seat,
          'fuel': fuel,
          'carImage': imageURL,
          'pickUpLocation': pickUpLocation,
          'dropOffLocation': dropOffLocation,
          'pricePerDay': price,
          'insurance': insurance,
          'carCondition': carCondition,
          'rentalPolicy': rentalPolicy,
          'agencyID': agencyID,
          // 'agencyName': agencyName,
          // 'agencyContact': agencyContact
        });
      }
      resp = "Success";
    } catch(err){
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveLocalBuddyData({
    String? localBuddyID,
    required String occupation,
    required String location,
    String? userID,
    required String languageSpoken,
    required String locationArea,
    required List<Map<String, dynamic>> availability,
    required int price,
    Uint8List? idCard,
    Uint8List? referenceImage,
    required String bio,
    String? previousExperience,
    required int action,
    int? registrationStatus,
  }) async {
    String resp = "Some Error Occurred";
    try {

      
      // Prepare the base data to store in Firestore
      Map<String, dynamic> buddyData = {
        'occupation': occupation,
        'location': location,
        'languageSpoken': languageSpoken,
        'locationArea': locationArea,
        'availability': availability,
        'price': price,
        'bio': bio,
        'registrationStatus': registrationStatus,
      };

      // // Conditionally add referenceImage if provided
      // if (referenceImage != null) {
      //   String referenceFileName = "referenceImage.jpg";
      //   String referenceImageURL = await uploadImageToStorage("localBuddy/$localBuddyID/$referenceFileName", referenceImage);
      //   buddyData['referenceImage'] = referenceImageURL;
      // }

      // Conditionally add previousExperience if provided
      if (previousExperience != null && previousExperience.isNotEmpty) {
        buddyData['previousExperience'] = previousExperience;
      }

      if(idCard != null){
        // Upload the ID card image
        String idCardFileName = "identificationCard.jpg"; 
        String imageURL = await uploadImageToStorage("localBuddy/$localBuddyID/$idCardFileName", idCard);
        buddyData['idCardImage'] = imageURL;
      }

      // Firestore operations: set or update based on action
      if (action == 1) {
        // Create a new document
        buddyData['localBuddyID'] = localBuddyID; // Add only when creating
        buddyData['userID'] = userID; // Add only when creating
        buddyData['registrationStatus'] = registrationStatus;
        await _firestore.collection("localBuddy").doc(localBuddyID).set(buddyData);
      } else {
        // Update the existing document
        // Remove localBuddyID and userID from the data before updating
        // buddyData.remove('localBuddyID');
        // buddyData.remove('userID');
        await _firestore.collection("localBuddy").doc(localBuddyID).update(buddyData);
      }

      resp = "Success";
    } catch (err) {
      resp = err.toString();
    }
    return resp;
  }

  Future<String> saveInvoice({
    required String userID,
    required String bookingID,
    required String servicesType,
    required String collectionName,
    required String pdfName,
    required File pdf, 
    bool isDeposit = false,
    bool isRefund = false,
    bool isDepositRefund = false,
  }) async {
    String resp = "Some Error Occurred";

    try {
      // Upload the PDF file to Firebase Storage
      String pdfURL = await uploadPdfToStorage("invoice/$servicesType/$userID/$bookingID/$pdfName", pdf);

    // Save the PDF URL in Firestore
    print('isDeposit: $isDeposit'); // Debugging line

    if (isDeposit) {
      await _firestore.collection(collectionName).doc(bookingID).update({
        'depositInvoice': pdfURL,
      });
      print('Deposit invoice updated.'); // Debugging line
    } else if(isRefund){
        await _firestore.collection(collectionName).doc(bookingID).update({
          'refundInvoice': pdfURL,
        });
      print('Refund invoice updated.'); // Debugging line
    } else if(isDepositRefund){
        await _firestore.collection(collectionName).doc(bookingID).update({
          'depositRefundInvoice': pdfURL,
        });
      print('Deposit Refund invoice updated.'); // Debugging line
    } else {
        await _firestore.collection(collectionName).doc(bookingID).update({
          'invoice': pdfURL,
        });
        print('Standard invoice updated.'); // Debugging line
    }


      resp = 'Success';
    } catch (e) {
      resp = e.toString();
    }

    return resp;
  }
}
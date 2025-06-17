import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:file_picker/file_picker.dart';

// class ImageUtils {
//   // // Request permission to access photos
//   // static Future<void> requestPermissions(BuildContext context) async {
//   //   final permissionStatus = await Permission.photos.request();
//   //   if(permissionStatus.isGranted){
//   //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission is granted.")));
//   //   }
//   //   else if (permissionStatus.isDenied) {
//   //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission is not granted. Please go to setting to allow TripMate access to your gallery.")));
//   //     print('Permission denied');
//   //   } else if (permissionStatus.isPermanentlyDenied) {
//   //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Permission is not granted. Please go to setting to allow TripMate access to your gallery.")));
//   //     await openAppSettings();
//   //   }
//   // }

//   static Future<void> requestPermissions(BuildContext context) async {
//     Permission permission;

//     if (Platform.isAndroid) {
//       // Use READ_MEDIA_IMAGES for Android 13+, otherwise use READ_EXTERNAL_STORAGE
//       permission = await Permission.photos.isGranted ? Permission.photos : Permission.storage;
//     } else if (Platform.isIOS) {
//       permission = Permission.photos;
//     } else {
//       return;
//     }

//     final permissionStatus = await permission.request();

//     if (permissionStatus.isGranted) {
//       // Uint8List? img = await pickImage(ImageSource.gallery);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Permission is granted."))
//       );
//     } else if (permissionStatus.isDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Permission is denied. Please allow access to your gallery in settings."))
//       );
//     } else if (permissionStatus.isPermanentlyDenied) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Permission is permanently denied. Please allow access to your gallery in settings."))
//       );
//       await openAppSettings(); // Open app settings if permission is permanently denied
//     }
//   }

//   // Select image from gallery
//   static Future<Uint8List?> selectImage(BuildContext context) async {
//     try {
//       await requestPermissions(context);

//       final permissionStatus = await Permission.photos.status;
//       print(permissionStatus);
//       // if (permissionStatus.isGranted) {
//       //   Uint8List? img = await pickImage(ImageSource.gallery);
//       //   return img;
//       // } else {
//       //   print('Permission to access photos was not granted.');
//       //   // await openAppSettings();
//       //   return null;
//       // }
//     } catch (e) {
//       print('Error selecting image: $e');
//       return null;
//     }
//   }

//   // Function to pick an image using ImagePicker
//   static Future<Uint8List?> pickImage(ImageSource source) async {
//     final ImagePicker _imagePicker = ImagePicker();
//     try {
//       XFile? _file = await _imagePicker.pickImage(source: source);
//       if (_file != null) {
//         return await _file.readAsBytes();
//       } else {
//         print('No image selected');
//         return null;
//       }
//     } catch (e) {
//       print('Error picking image: $e');
//       return null;
//     }
//   }
// }

class ImageUtils {
  // Request permission to access photos and then pick an image
  static Future<Uint8List?> selectImage(BuildContext context) async {
    try {
      Permission permission;

      if (Platform.isAndroid) {
        // Use READ_MEDIA_IMAGES for Android 13+, otherwise use READ_EXTERNAL_STORAGE
        permission = await Permission.photos.isGranted ? Permission.photos : Permission.storage;
      } else if (Platform.isIOS) {
        permission = Permission.photos;
      } else {
        return null;
      }

      final permissionStatus = await permission.request();

      if (permissionStatus.isGranted) {
        Uint8List? img = await pickImage(ImageSource.gallery);
        return img;
      } else if (permissionStatus.isDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission is denied. Please allow access to your gallery in settings.")),
        );
        return null;
      } else if (permissionStatus.isPermanentlyDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission is permanently denied. Please allow access to your gallery in settings.")),
        );
        await openAppSettings(); // Open app settings if permission is permanently denied
        return null;
      }
    } catch (e) {
      print('Error selecting image: $e');
      return null;
    }
    return null;
  }

  // Function to pick an image using ImagePicker
  static Future<Uint8List?> pickImage(ImageSource source) async {
    final ImagePicker _imagePicker = ImagePicker();
    try {
      XFile? _file = await _imagePicker.pickImage(source: source);
      if (_file != null) {
        return await _file.readAsBytes();
      } else {
        print('No image selected');
        return null;
      }
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }
}


class FileUtils {
  static Future<bool> _request_per(Permission permission) async{
    AndroidDeviceInfo build = await DeviceInfoPlugin().androidInfo;
    if(build.version.sdkInt>=30){
      var re = await Permission.manageExternalStorage.request();
      if(re.isGranted){
        return true;
      }
      else {
        return false;
      }
    }
    else{
      if(await permission.isGranted){
        return true;
      }
      else{
        var result = await permission.request();
        if(result.isGranted){
          return true;
        }
        else{
          return false;
        }
      }
    }
    
  }

  // Select PDF file
  static Future<File?> selectPdf() async {
    try {
      if (await _request_per(Permission.storage) == true){
        print('Permission is granted');
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );

        if (result != null && result.files.isNotEmpty) {
          return File(result.files.first.path!);
        } else {
          print('No file selected');
          return null;
        }
      }
      else{
        print('Permission is not granted');
        return null;
      }
    } catch (e) {
      print('Error selecting PDF file: $e');
      return null;
    }
  }
}

class Country{
  final String countryName;
  final String countryID;
  final String image;

  Country(this.countryName, this.countryID, this.image);
}

class City{
  final String cityName;
  final String cityID;
  final String image;

  City(this.cityName, this.cityID, this.image);
}

class TourPackage{
  final String tourName;
  final String tourID;
  final String image;
  final String agency;

  TourPackage(this.tourName, this.tourID, this.image, this.agency);
}

class TravelAgent{
  final String name;
  final String companyName;
  final String id;
  final String image;

  TravelAgent(this.name, this.companyName, this.id, this.image);
}

class UserViewTourList{
  final String tourName;
  final String tourID;
  final String image;
  final String agency;
  final String? agentID;
  final List<dynamic> tourHighlight;
  final List<dynamic> availability;

  UserViewTourList(this.tourName, this.tourID, this.image, this.agency, this.tourHighlight, this.availability, {this.agentID});
}

class MessageList{
  final String receiverName;
  final String receiverProfile;
  final String receiverID;
  final String latestMessage;
  final Timestamp latestReceiveTime;
  final bool isCurrentUser;

  MessageList(this.receiverName, this.receiverProfile, this.receiverID, this.latestMessage, this.latestReceiveTime, this.isCurrentUser);
}

class CarList{
  final String carID;
  final String carModel;
  final String? carImage;
  final String? carType;
  final String? fuel;
  final String? transmission;
  final int? seat;
  final double? price;
  final String? agentID;
  final String? agencyName;
  final String? agencyContact;
  final String? pickUpLocation;
  final String? dropOffLocation;
  double? distance;

  CarList(this.carID, this.carModel, {this.carImage, this.carType, this.fuel, this.transmission, this.seat, this.price, this.agentID, this.agencyName, this.agencyContact, this.pickUpLocation, this.dropOffLocation, this.distance});
}

class LocalBuddy{
  final String localBuddyID;
  final String localBuddyName;
  final String localBuddyImage;
  final String? occupation;
  final int? status;
  final int? ranking;
  final String? locationArea;
  final String? languageSpoken;
  final String? locationAddress;
  final int? price;
  double? distance;

  LocalBuddy({required this.localBuddyID, required this.localBuddyName, required this.localBuddyImage, this.occupation, this.status, this.ranking, this.locationArea, this.languageSpoken, this.locationAddress, this.price, this.distance});

}

class itinerary{
  final String title;
  final String content;
  final String itineraryID;
  final String image;

  itinerary(this.title, this.content, this.itineraryID, this.image);
}

class tourBooking {
  final String tourBookingID;
  final String tourID;
  late String tourName;
  late String tourImage;
  late String agencyName;
  late String agencyAddress;
  final int fullyPaid;
  final String travelDate;
  final double totalPrice;
  final int pax;
  final int bookingStatus;
  final int? isReviewSubmitted;

  tourBooking({
    required this.tourBookingID, 
    required this.tourID,
    required this.fullyPaid, 
    required this.travelDate, 
    required this.totalPrice, 
    required this.pax,
    required this.bookingStatus,
    this.isReviewSubmitted,
  });

  factory tourBooking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Create the tourBooking object
    tourBooking tourbooking = tourBooking(
      tourBookingID: doc.id, 
      tourID: data['tourID'],
      fullyPaid: data['fullyPaid'], 
      travelDate: data['travelDate'], 
      totalPrice: data['totalPrice'], 
      pax: data['numberOfPeople'],
      bookingStatus: data['bookingStatus'],
      isReviewSubmitted: data.containsKey('reviewSubmitted') ? data['reviewSubmitted'] : null, // Check if reviewSubmitted exists
    );

    // Assign other fields
    tourbooking.tourName = data['tourName'] ?? '';
    tourbooking.tourImage = data['tourCover'] ?? '';
    tourbooking.agencyName = data['agencyName'] ?? '';
    tourbooking.agencyAddress = data['agencyAddress'] ?? '';

    return tourbooking;
  }
}


class carRentalBooking {
  final String carRentalBookingID;
  final String carID;
  late String carName;
  late String carImage;
  final List<DateTime> bookingDate;
  final double totalPrice;
  final int bookingStatus;
  final int isRefund;
  final int? isDepositRefund;
  final int? isReviewSubmitted;

  carRentalBooking({
    required this.carRentalBookingID,
    required this.carID,
    required this.bookingDate,
    required this.totalPrice,
    required this.bookingStatus,
    required this.isRefund,
    required this.isDepositRefund,
    this.isReviewSubmitted,
  });

  factory carRentalBooking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert the list of timestamps to DateTime objects
    List<DateTime> bookingDates = (data['bookingDate'] as List<dynamic>)
        .map((date) => (date as Timestamp).toDate())
        .toList();

    carRentalBooking carRentalBookings = carRentalBooking(
      carRentalBookingID: doc.id,
      carID: data['carID'],
      totalPrice: data['totalPrice'],
      bookingDate: bookingDates, // Use the converted DateTime list here
      bookingStatus: data['bookingStatus'],
      isRefund: data['isRefund'],
      isDepositRefund: data['isRefundDeposit'],
      isReviewSubmitted: data.containsKey('reviewSubmitted') ? data['reviewSubmitted'] : null, // Check if reviewSubmitted exists
    );

    carRentalBookings.carName = data['carModel'] ?? '';
    carRentalBookings.carImage = data['carImage'] ?? '';

    return carRentalBookings;
  }
}

class localBuddyBooking{
  final String localBuddyBookingID;
  final String localBuddyID;
  late String localBuddyName;
  late String localBuddyImage;
  late String locationArea;
  final List<DateTime> bookingDate;
  final double totalPrice;
  final int bookingStatus;
  final int isRefund;
  final int? isReviewSubmitted;

  localBuddyBooking({
    required this.localBuddyBookingID, 
    required this.localBuddyID, 
    required this.bookingDate, 
    required this.totalPrice, 
    required this.bookingStatus,
    required this.isRefund,
    this.isReviewSubmitted,
  });

  factory localBuddyBooking.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert the list of timestamps to DateTime objects
    List<DateTime> bookingDates = (data['bookingDate'] as List<dynamic>)
        .map((date) => (date as Timestamp).toDate())
        .toList();

    localBuddyBooking localBuddyBookings = localBuddyBooking(
      localBuddyBookingID: doc.id,
      localBuddyID: data['localBuddyID'],
      totalPrice: data['totalPrice'],
      bookingDate: bookingDates,  // Use the formatted date range here
      bookingStatus: data['bookingStatus'],
      isRefund: data['isRefund'],
      isReviewSubmitted: data.containsKey('reviewSubmitted') ? data['reviewSubmitted'] : null, // Check if reviewSubmitted exists
    );

    localBuddyBookings.localBuddyName = data['localBuddyName'] ?? '';
    localBuddyBookings.localBuddyImage = data['profileImage'] ?? '';
    localBuddyBookings.locationArea = data['locationArea'] ?? '';

    return localBuddyBookings;
  }
}

class TravelAgentTourBookingList {
  final String tourID;
  final String tourName;
  final String tourImage;
  late int totalBookingNumber;
  late bool haveCancelBooking;

  TravelAgentTourBookingList({
    required this.tourID,
    required this.tourName,
    required this.tourImage,
    this.totalBookingNumber = 0,  // Default to 0 if no bookings
    this.haveCancelBooking = false,
  });

  // Factory constructor to create a TravelAgentTourBookingList object from Firestore
  factory TravelAgentTourBookingList.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TravelAgentTourBookingList(
      tourID: doc.id,
      tourName: data['tourName'],
      tourImage: data['tourCover'],
      totalBookingNumber: data['totalBookingNumber'] ?? 0,  
      haveCancelBooking: data['haveCancelBooking'] ?? false
    );
  }
}

class TravelAgentCarRentalBookingList {
  final String carRentalID;
  final String carName;
  final String carImage;
  late int totalBookingNumber;
  late bool haveCancelBooking;

  TravelAgentCarRentalBookingList({
    required this.carRentalID,
    required this.carName,
    required this.carImage,
    this.totalBookingNumber = 0,  
    this.haveCancelBooking = false
  });

  factory TravelAgentCarRentalBookingList.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return TravelAgentCarRentalBookingList(
      carRentalID: doc.id,
      carName: data['carModel'],
      carImage: data['carImage'],
      totalBookingNumber: data['totalBookingNumber'] ?? 0,  // Default to 0 if missing
      haveCancelBooking: data['haveCancelBooking'] ?? false
    );
  }
}

class AdminLocalBuddyBookingList {
  final String localBuddyID;
  final String userID;
  String localBuddyName; 
  String localBuddyImage; 
  int totalBookingNumber;
  late bool haveCancelBooking;

  AdminLocalBuddyBookingList({
    required this.localBuddyID,
    required this.userID,
    this.localBuddyName = '',
    this.localBuddyImage = '',
    this.totalBookingNumber = 0, // Default to 0 if no bookings
    this.haveCancelBooking = false
  });

  factory AdminLocalBuddyBookingList.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminLocalBuddyBookingList(
      localBuddyID: doc.id,
      userID: data['userID'] ?? '', // Default to empty string if null
      localBuddyName: data['name'] ?? '', // Default to empty string if null
      localBuddyImage: data['profileImage'] ?? '', // Default to empty string if null
      totalBookingNumber: data['totalBookingNumber'] ?? 0, // Default to 0 if missing
      haveCancelBooking: data['haveCancelBooking'] ?? false
    );
  }
}

class AdminAgencyList {
  final String agencyID;
  final String agentID;
  final String agencyName; 
  late int totalTourBookingNumber;
  late int totalCarBookingNumber;
  late bool haveCancelBooking;

  AdminAgencyList({
    required this.agencyID,
    required this.agentID,
    required this.agencyName,
    this.totalTourBookingNumber = 0, 
    this.totalCarBookingNumber = 0,
    this.haveCancelBooking = false,
  });

  factory AdminAgencyList.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return AdminAgencyList(
      agencyID: data['companyID'] ?? '',
      agentID: doc.id, 
      agencyName: data['companyName'] ?? '', 
      totalTourBookingNumber: data['totalTourBookingNumber'] ?? 0, 
      totalCarBookingNumber: data['totalCarBookingNumber'] ?? 0, 
      haveCancelBooking: data['haveCancelBooking'] ?? false,
    );
  }
}

class localBuddyCustomerAppointment {
  final String localBuddyBookingID;
  final String custID;
  late String custName;
  final List<DateTime> bookingDate;
  final double totalPrice;
  final int bookingStatus;
  final int totalDays;

  localBuddyCustomerAppointment({
    required this.localBuddyBookingID,
    required this.custID,
    required this.bookingDate,
    required this.totalPrice,
    required this.bookingStatus,
    required this.totalDays,
  });

  factory localBuddyCustomerAppointment.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<DateTime> bookingDates = (data['bookingDate'] as List<dynamic>)
        .map((date) => (date as Timestamp).toDate())
        .toList();

    localBuddyCustomerAppointment localBuddyAppointments = localBuddyCustomerAppointment(
      localBuddyBookingID: doc.id,
      custID: data['userID'],
      totalPrice: data['totalPrice'],
      bookingDate: bookingDates,
      bookingStatus: data['bookingStatus'],
      totalDays: data['totalDays'],
    );

    localBuddyAppointments.custName = data['name'] ?? '';

    return localBuddyAppointments;
  }
}




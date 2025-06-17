import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>> getCurrentUserDetails(String id) async {
    return await FirebaseFirestore.instance.collection("users").doc(id).snapshots();
  }
}
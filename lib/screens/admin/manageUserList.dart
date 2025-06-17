import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/admin/adminViewUserDetails.dart';
import 'package:assignment_tripmate/screens/admin/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminManageUserListScreen extends StatefulWidget {
  final String userId;

  const AdminManageUserListScreen({
    super.key,
    required this.userId,
  });

  @override
  State<StatefulWidget> createState() => _AdminManageUserListScreenState();
}

class _AdminManageUserListScreenState extends State<AdminManageUserListScreen> {
  List<Map<String, dynamic>> userList = [];
  List<Map<String, dynamic>> travelAgentList = [];
  List<Map<String, dynamic>> localBuddyList = [];
  List<Map<String, dynamic>> foundedUserList = [];
  List<Map<String, dynamic>> foundedTravelAgentList = [];
  List<Map<String, dynamic>> foundedLocalBuddyList = [];

  bool isFetchingUser = false;
  bool isFetchingTravelAgent = false;
  bool isFetchingLocalBuddy = false;

  @override
  void initState() {
    super.initState();
    _fetchUser();
    _fetchTravelAgent();
    _fetchLocalBuddy();
  }

  Future<void> _fetchUser() async {
    setState(() {
      isFetchingUser = true;
    });
    try {
      CollectionReference userRef = FirebaseFirestore.instance.collection('users');
      QuerySnapshot snapshot = await userRef.get();

      userList = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() {
        foundedUserList = userList;
      });
    } catch (e) {
      showCustomDialog(
        context: context,
        title: "Error",
        content: "Something went wrong: $e",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    } finally {
      setState(() {
        isFetchingUser = false;
      });
    }
  }

  Future<void> _fetchTravelAgent() async {
    setState(() {
      isFetchingTravelAgent = true;
    });
    try {
      CollectionReference taRef = FirebaseFirestore.instance.collection('travelAgent');
      QuerySnapshot snapshot = await taRef.where('accountApproved', isEqualTo: 1).get();

      travelAgentList = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

      setState(() {
        foundedTravelAgentList = travelAgentList;
      });
    } catch (e) {
      showCustomDialog(
        context: context,
        title: "Error",
        content: "Something went wrong: $e",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    } finally {
      setState(() {
        isFetchingTravelAgent = false;
      });
    }
  }

  Future<void> _fetchLocalBuddy() async {
    setState(() {
      isFetchingLocalBuddy = true;
    });
    try {
      CollectionReference lbRef = FirebaseFirestore.instance.collection('localBuddy');
      QuerySnapshot snapshot = await lbRef.where('registrationStatus', isEqualTo: 2).get();

      List<Map<String, dynamic>> lb = [];

      for (var lbDoc in snapshot.docs) {
        Map<String, dynamic> lbData = lbDoc.data() as Map<String, dynamic>;
        String userId = lbDoc['userID'] as String;

        // Fetch user document based on userID from local buddy document
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
        
        if (userDoc.exists) {
          // Get user data
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          String localBuddyName = userData['name'] as String;
          String localBuddyUserID = userDoc.id;

          // Combine local buddy data with user data
          Map<String, dynamic> combinedData = {
            ...lbData,
            'localBuddyName': localBuddyName,
            'localBuddyUserID': localBuddyUserID,
          };

          lb.add(combinedData);
        }
      }

      setState(() {
        localBuddyList = lb;
        foundedLocalBuddyList = localBuddyList;
      });
    } catch (e) {
      showCustomDialog(
        context: context,
        title: "Error",
        content: "Something went wrong: $e",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    } finally {
      setState(() {
        isFetchingLocalBuddy = false;
      });
    }
  }


  void _searchUser(String query) {
    setState(() {
      foundedUserList = userList
          .where((user) => user['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _searchTravelAgent(String query) {
    setState(() {
      foundedTravelAgentList = travelAgentList
          .where((agent) => agent['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _searchLocalBuddy(String query) {
    setState(() {
      foundedLocalBuddyList = localBuddyList
          .where((buddy) => buddy['localBuddyName'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  Future<void> _deleteUser(String userId, String collection) async {
    try {
      // Delete the user from the specified collection
      await FirebaseFirestore.instance.collection(collection).doc(userId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User deleted successfully.')),
      );

      // Check if the deleted user is a local buddy if the collection is 'users'
      if (collection == 'users') {
        // Query to check if there's a local buddy with userID matching the userId
        final localBuddySnapshot = await FirebaseFirestore.instance
            .collection('localBuddy')
            .where('userID', isEqualTo: userId)
            .get();

        if (localBuddySnapshot.docs.isNotEmpty) {
          for (var doc in localBuddySnapshot.docs) {
            await doc.reference.delete();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Associated local buddy deleted successfully.')),
          );
        }
      }

      // Update local lists in the UI
      setState(() {
        if (collection == 'users') {
          userList.removeWhere((user) => user['id'] == userId);
          foundedUserList = userList;
          localBuddyList.removeWhere((buddy) => buddy['localBuddyUserID'] == userId);
          foundedLocalBuddyList = localBuddyList;
        } else if (collection == 'travelAgent') {
          travelAgentList.removeWhere((agent) => agent['id'] == userId);
          foundedTravelAgentList = travelAgentList;
        } else if (collection == 'localBuddy') {
          localBuddyList.removeWhere((buddy) => buddy['localBuddyID'] == userId);
          foundedLocalBuddyList = localBuddyList;
        }
      });
    } catch (e) {
      showCustomDialog(
        context: context,
        title: "Error",
        content: "Something went wrong: $e",
        onPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text("User List"),
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
                MaterialPageRoute(builder: (context) => AdminHomepageScreen(userId: widget.userId)),
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0),
            child: Container(
              height: 50,
              color: Colors.white,
              child: TabBar(
                tabs: [
                  Tab(child: Text("User")),
                  Tab(child: Text("Travel Agent")),
                  Tab(child: Text("Local Buddy")),
                ],
                labelColor: primaryColor,
                indicatorColor: primaryColor,
                indicatorWeight: 2,
                unselectedLabelColor: Color(0xFFA4B4C0),
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelStyle: TextStyle(fontSize: defaultFontSize),
                labelStyle: TextStyle(fontSize: defaultFontSize),
              ),
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildUserListTab(foundedUserList, _searchUser, "user"),
            _buildUserListTab(foundedTravelAgentList, _searchTravelAgent, "ta"),
            _buildUserListTab(foundedLocalBuddyList, _searchLocalBuddy, "lb"),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListTab(List<Map<String, dynamic>> list, Function(String) onSearch, String type) {
  return Column(
    children: [
      Container(
        height: 60,
        margin: EdgeInsets.only(top: 10),
        padding: EdgeInsets.symmetric(horizontal: 10),
        child: TextField(
          onChanged: (value) => onSearch(value),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.blueGrey, width: 2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF467BA1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            hintText: type == "user" ? "Search user with name..." : type == "ta" ? "Search travel agent with name..." : "Search local buddy with name...",
            hintStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      Expanded(
        child: ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            return ListTile(
              contentPadding: EdgeInsets.only(left: 15, right: 0),
              title: Text(type == "lb" ? item['localBuddyName'] ?? 'No Name' : item['name'] ?? 'No Name'),
              subtitle: Text('ID: ${type == "lb" ? item['localBuddyID'] ?? 'No ID' : item['id'] ?? 'No ID'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(
                          builder: (context) => AdminManageUserDetailsScreen(
                            userId: widget.userId,
                            userListID: item['id'] ?? '',
                            type: type,
                            localBuddyId: type == "lb" ? item['localBuddyID'] ?? '' : '',
                            localBuddyname: type == "lb" ? item['localBuddyName'] ?? '' : '',
                          )
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Delete User'),
                            content: Text('Are you sure you want to delete user (${type == "lb" ? item['localBuddyName'] ?? 'No Name' : item['name'] ?? 'No Name'})?'),
                            actions: <Widget>[
                              TextButton(
                                child: Text('Cancel'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Delete', style: TextStyle(color: Colors.red)),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _deleteUser(
                                    type == "lb" ? item['localBuddyID'] : item['id'], 
                                    type == "lb" ? "localBuddy" : type == "user" ? "users" : "travelAgent"
                                  );
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  );
}

}

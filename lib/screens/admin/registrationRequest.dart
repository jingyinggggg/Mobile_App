import "package:assignment_tripmate/constants.dart";
import "package:assignment_tripmate/screens/admin/homepage.dart";
import "package:assignment_tripmate/screens/admin/manageLocalBuddyRegistrationRequest.dart";
import "package:assignment_tripmate/screens/admin/manageRegistrationRequest.dart";
import "package:assignment_tripmate/utils.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";

class RegistrationRequestScreen extends StatefulWidget {
  final String userId;

  const RegistrationRequestScreen({super.key, required this.userId});

  @override
  State<RegistrationRequestScreen> createState() => _RegistrationRequesrScreenState();
}

class _RegistrationRequesrScreenState extends State<RegistrationRequestScreen> {
  List<TravelAgent> _TAList = [];
  List<LocalBuddy> _LocalBuddyList = [];
  bool isFetchTravelAgentList = false;
  bool isFetchingLocalBuddyList = false;

  @override
  void initState() {
    super.initState();
    fetchTAList();
    fetchLocalBuddyList();
  }

  Future<void> fetchTAList() async {
    setState(() {
      isFetchTravelAgentList = true;
    });
    try {
      // Get the reference to the 'travelAgent' collection
      CollectionReference taRef = FirebaseFirestore.instance.collection('travelAgent');
      
      // Query where 'accountApproved' is equal to 0 or 3
      QuerySnapshot querySnapshot = await taRef.where('accountApproved', whereIn: [0, 3]).get();
      
      _TAList = querySnapshot.docs.map((doc) {
        // Use default values if any field is null
        return TravelAgent(
          doc['name'] ?? 'Unnamed Agent', 
          doc['companyName'] ?? 'No Company', 
          doc['id'] ?? 'No ID',
          doc['profileImage'] ?? 'default_image_url_here' // Provide a default image URL if needed
        );
      }).toList();

      setState(() {
        _TAList;
      });

    } catch (e) {
      print("Error fetching travel agents list: $e");
    } finally {
      setState(() {
        isFetchTravelAgentList = false;
      });
    }
  }


  Future<void> fetchLocalBuddyList() async {
    setState(() {
      isFetchingLocalBuddyList = true;
    });
    try {
      CollectionReference localBuddyRef = FirebaseFirestore.instance.collection('localBuddy');
      CollectionReference userRef = FirebaseFirestore.instance.collection('users');
      
      // Fetch localBuddy where registrationStatus is 0 or 1 or 5
      QuerySnapshot querySnapshot = await localBuddyRef.where('registrationStatus', whereIn: [0, 1, 5]).get();

      // Clear the current list
      _LocalBuddyList = [];

      // Loop through each localBuddy document
      for (var doc in querySnapshot.docs) {
        // Fetch corresponding user details using the userID
        DocumentSnapshot userSnapshot = await userRef.doc(doc['userID']).get();

        // Check if the user document exists
        if (userSnapshot.exists) {
          // Create a LocalBuddy object and save both localBuddy and user details
          _LocalBuddyList.add(LocalBuddy(
            localBuddyID:  doc['localBuddyID'], 
            localBuddyName:  userSnapshot['name'], 
            localBuddyImage: userSnapshot['profileImage'], 
            occupation: doc['occupation'],
            status: doc['registrationStatus'] ?? -1
          ));
        }
      }

      // Update state to reflect the new list
      setState(() {
        _LocalBuddyList;
      });

    } catch (e) {
      print("Error fetching local buddies and user info: $e");
    } finally{
      setState(() {
        isFetchingLocalBuddyList = false;
      });
    }
  }

  @override 
  Widget build(BuildContext context) { 
    return DefaultTabController( 
      length: 2, 
      child: Scaffold( 
        backgroundColor: Colors.white,
        appBar: AppBar( 
          title: Text("Registration Request"), 
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
                MaterialPageRoute(builder: (context) => AdminHomepageScreen(userId: widget.userId))
              );
            },
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(50.0), // Adjust the height as needed
            child: Container(
              height: 50,
              color: Colors.white, // Set the background color of the TabBar
              child: TabBar(
                tabs: [
                  Tab(
                    child: 
                    Container(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          ImageIcon(
                            AssetImage("images/travel-agent.png"),
                            size: 35,
                          ),
                          SizedBox(width: 8),
                          Text(
                            "Travel Agent",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold), 
                          ),
                        ],
                      ),
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          child: ImageIcon(
                            AssetImage("images/tour-guide.png"),
                            size: 35,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Local Buddy",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
                labelColor: Color(0xFF467BA1),
                indicatorColor: Color(0xFF467BA1),
                indicatorWeight: 3,
                unselectedLabelColor: Color(0xFFA4B4C0), // Unselected tab text color
                indicatorPadding: EdgeInsets.zero,
                indicatorSize: TabBarIndicatorSize.tab,
                unselectedLabelStyle: TextStyle(fontSize: defaultFontSize),
              ),
            ),
          ),
        ), 
        body: TabBarView( 
          children: [ 
            Container(
              padding: EdgeInsets.only(right: 10, left: 10, top: 10), // Adjust the top padding as needed
              child: isFetchTravelAgentList
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _TAList.isEmpty
                ? Center(child: Text('No pending review registration for travel agent.', style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                : ListView.builder(
                    itemCount: _TAList.length,
                    itemBuilder: (context, index) {
                      return TAComponent(travelAgent: _TAList[index]);
                    }
                  ),
            ),
            Container(
              padding: EdgeInsets.only(right: 10, left: 10, top: 10),
              child: isFetchingLocalBuddyList
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : _LocalBuddyList.isEmpty
                ? Center(child: Text('No pending review registration for local buddy.', style: TextStyle(fontSize: defaultFontSize, color: Colors.black)))
                : ListView.builder(
                    itemCount: _LocalBuddyList.length,
                    itemBuilder: (context, index) {
                      return LocalBuddyComponent(localBuddy: _LocalBuddyList[index]);
                    }
                  ),
            )
          ], 
        ),
      ), 
    ); 
  } 

  Widget TAComponent({required TravelAgent travelAgent}) {
    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 60, 
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF467BA1), 
                    width: 2.0, 
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  backgroundImage: travelAgent.image != "default_image_url_here"
                    ? NetworkImage(travelAgent.image) 
                    : AssetImage("images/profile.png") as ImageProvider,
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(travelAgent.name, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
                  SizedBox(height: 5),
                  Text("Agency: " + travelAgent.companyName, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12))
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => AdminManageRegistrationRequestScreen(userId: widget.userId, TAId: travelAgent.id))
              );
            }, 
            icon: Icon(Icons.edit_document),
            iconSize: 25,
            color: Color(0xFF467BA1),
            tooltip: 'Review Request',
          ),
        ],
      ),
    );
  }

  Widget LocalBuddyComponent({required LocalBuddy localBuddy}) {
    // Default to -1 if status is null
    int status = localBuddy.status ?? -1;

    return Container(
      padding: EdgeInsets.only(top: 10, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 60, 
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Color(0xFF467BA1), 
                    width: 2.0,
                  ),
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundImage: NetworkImage(localBuddy.localBuddyImage),
                ),
              ),
              SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localBuddy.localBuddyName, 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Occupation: ${localBuddy.occupation}", 
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  SizedBox(height: 5),
                  Row(
                    children: [
                      Text(
                        "Status: ${status == 0 || status == 5 ? 'Pending Review' : status == 1 ? 'Pending Interview' : 'Unknown Status'} ",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      SizedBox(width: 5),
                      Icon(
                        status == 0 || status == 5 
                            ? Icons.hourglass_bottom 
                            : status == 1 
                                ? Icons.schedule 
                                : Icons.help_outline,
                        color: status == 0 || status == 5 
                            ? Colors.orange 
                            : status == 1 
                                ? Colors.blue 
                                : Colors.grey,
                        size: defaultFontSize,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(
                  builder: (context) => AdminManageLocalBuddyRegistrationRequestScreen(
                    userId: widget.userId, 
                    localBuddyId: localBuddy.localBuddyID,
                  ),
                ),
              );
            }, 
            icon: Icon(Icons.edit_document),
            iconSize: 25,
            color: Color(0xFF467BA1),
            tooltip: 'Review Request',
          ),
        ],
      ),
    );
  }

 
}

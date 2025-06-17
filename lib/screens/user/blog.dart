import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:assignment_tripmate/constants.dart';

class BlogMainScreen extends StatefulWidget {
  final String userId;

  const BlogMainScreen({super.key, required this.userId});

  @override
  State<BlogMainScreen> createState() => _BlogMainScreenState();
}

class _BlogMainScreenState extends State<BlogMainScreen> {
  int _currentIndex = 0; // Track selected tab index

  // List of widgets for each tab
  final List<Widget> _screens = [
    ExploreScreen(),
    SizedBox.shrink(), // Placeholder for AddScreen
    MeScreen(),
  ];

  // Handling bottom navigation bar tap
  void _onTabTapped(int index) {
    if (index != 1) { // Prevent changing to Add tab
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Blog"),
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
            Navigator.pop(context);
          },
        ),
      ),
      body: _screens[_currentIndex], // Display the corresponding screen
      bottomNavigationBar: ConvexAppBar(
        height: 60,
        backgroundColor: Color(0xFF749CB9),
        color: Colors.white,
        style: TabStyle.fixedCircle,
        items: [
          TabItem(icon: Icons.explore, title: 'Explore'),
          TabItem(icon: Icons.add, title: 'Add'),
          TabItem(icon: Icons.person, title: 'Me'),
        ],
        initialActiveIndex: 1,
        onTap: _onTabTapped,
      )
    );
  }
}

// Placeholder for ExploreScreen
class ExploreScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Explore Screen"),
    );
  }
}

// Placeholder for MeScreen
class MeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text("Me Screen"),
    );
  }
}

import 'package:assignment_tripmate/screens/login.dart';
import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/welcome_background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // White container with opacity
          Container(
            // color: const Color(0xFFEDF2F6).withOpacity(0.2),
            child: Stack(
              children: [
                // App name
                const Positioned(
                  top: 250, // Adjust the top position as needed
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      'TripTop',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black, // Change the text color to black
                        fontFamily: 'Inika',
                      ),
                    ),
                  ),
                ),

                // Button
                Positioned(
                  top: 490, // Adjust the top position as needed
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle button press to navigate to the next page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      // ignore: sort_child_properties_last
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF50057),
                        padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 20),
                        textStyle: const TextStyle(
                          fontSize: 20, 
                          fontFamily: 'Inika',
                          fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

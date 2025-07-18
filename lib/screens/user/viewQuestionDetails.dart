import 'package:assignment_tripmate/constants.dart';
import 'package:flutter/material.dart';

class HelpCenterDetailsScreen extends StatefulWidget{
  final String userId;
  final String questionTitle;
  final String questionContent;

  const HelpCenterDetailsScreen({
    super.key, 
    required this.userId,
    required this.questionTitle,
    required this.questionContent
  });

  @override
  State<HelpCenterDetailsScreen> createState() => _HelpCenterDetailsScreenState();
}

class _HelpCenterDetailsScreenState extends State<HelpCenterDetailsScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 236, 236, 236),
      
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFE57373), Color.fromARGB(255, 236, 236, 236)], // Soft pink gradient
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: AppBar(
            title: const Text("Help Center"),
            centerTitle: true,
            backgroundColor: Colors.transparent, // Makes the gradient visible
            elevation: 0,
            titleTextStyle: const TextStyle(
              color: Colors.black,
              fontFamily: 'Inika',
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              widget.questionTitle, 
              style: TextStyle(
                fontSize: defaultLabelFontSize,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 15),
            Text(
              widget.questionContent.replaceAll(r'\n', '\n'),
              style: TextStyle(
                fontSize: defaultFontSize,
                color: Colors.black,
                fontWeight: FontWeight.w500,
                height: 1.8
              ),
              maxLines: null,
              textAlign: TextAlign.justify,
              overflow: TextOverflow.visible,
            ),
          ],
        ),
      ),
    );
  }
}
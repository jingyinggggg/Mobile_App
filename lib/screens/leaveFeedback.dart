import 'package:assignment_tripmate/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class FeedbackScreen extends StatefulWidget {
  final String userID;

  const FeedbackScreen({super.key, required this.userID});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen>{
  final TextEditingController _feedbackController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    super.dispose();
    _feedbackController.dispose();
  }

  Future<void>_submitFeedback() async{
    setState(() {
      isLoading = true;
    });
    try{
      if(_feedbackController.text.isNotEmpty){
        await FirebaseFirestore.instance.collection('feedback').doc().set({
          'feedback': _feedbackController.text,
          'userID': widget.userID,
          'timestamp': DateTime.now()
        });

        showCustomDialog(
          context: context, 
          title: "Submission Successful", 
          content: "You have submitted your feedback successfully. Thank you!", 
          onPressed: (){
            Navigator.of(context).pop();
            Navigator.pop(context);
          }
        );
      }
      
    }catch(e){
      showCustomDialog(
        context: context, 
        title: "Submission Failed", 
        content: "Something went wrong! Please try again...", 
        onPressed: (){
          Navigator.of(context).pop();
        }
      );
    } finally{
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 236, 236, 236),
      resizeToAvoidBottomInset: true, // Ensures the page resizes when keyboard opens
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
            title: const Text("Feedback"),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      """Thank you for using TripTop. This page is dedicated to gathering your valuable insights and suggestions to help us enhance your experience. Your feedback is crucial in making TripTop more tailored to your travel needs and preferences. Whether it's about the features, user interface, or any improvements you'd like to see, we want to hear from you.
                      
                      Let us know what you love, what could be better, and any ideas you have for making TripTop the ultimate travel companion. Your input helps us innovate and grow, ensuring that our platform continually evolves to provide the best service possible.
                      """,
                      style: TextStyle(
                        fontSize: defaultFontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 10),
                    feedback(),
                    SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _feedbackController.text.isEmpty
                            ? null
                            : isLoading
                                ? null
                                : () {
                                    _submitFeedback();
                                  },
                        child: isLoading
                            ? SizedBox(
                                width: 1.50,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white
                                )
                              )
                            : const Text(
                                'Submit',
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          textStyle: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20), // Additional padding to avoid overflow
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget feedback() {
    return TextField(
      controller: _feedbackController,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        fontSize: defaultFontSize,
      ),
      decoration: InputDecoration(
        hintText: 'Write down any doubt or any improvement for TripTop...',
        labelText: 'Feedback',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFFF50057),
            width: 1.5,
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
      keyboardType: TextInputType.multiline,
      maxLines: 8, 
      textAlign: TextAlign.justify,
    );
  }
}

import 'package:assignment_tripmate/constants.dart';
import 'package:assignment_tripmate/screens/user/chatDetailsPage.dart';
import 'package:assignment_tripmate/screens/user/viewQuestionDetails.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget{
  final String userId;
  final bool isUser;
  final bool isTravelAgent;
  final bool isAdmin;

  const HelpCenterScreen({
    super.key, 
    required this.userId,
    this.isUser = false,
    this.isTravelAgent = false,
    this.isAdmin = false
  });

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>{
  List<Question> question = [];
  bool isFetching = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestion();
  }

  Future<void>_fetchQuestion() async {
    setState(() {
      isFetching = true;
    });
    try{
      CollectionReference helpCenterRef = FirebaseFirestore.instance.collection('helpCenter');
      QuerySnapshot helpCenterSnapshot = await helpCenterRef.get();

      List<Question> questionList = [];

      for(var doc in helpCenterSnapshot.docs){
        if(widget.isUser){
          CollectionReference subCollection = await helpCenterRef.doc(doc.id).collection('user');
          QuerySnapshot subSnapshot = await subCollection.get();

          for(var subDoc in subSnapshot.docs){
            Question fetchQuestion = Question.fromFirestore(subDoc);
            questionList.add(fetchQuestion);
          }

        } else if (widget.isTravelAgent){
          CollectionReference subCollection = await helpCenterRef.doc(doc.id).collection('travelAgent');
          QuerySnapshot subSnapshot = await subCollection.get();

          for(var subDoc in subSnapshot.docs){
            Question fetchQuestion = Question.fromFirestore(subDoc);
            questionList.add(fetchQuestion);
          }

        } else if (widget.isAdmin){
          CollectionReference subCollection = await helpCenterRef.doc(doc.id).collection('admin');
          QuerySnapshot subSnapshot = await subCollection.get();

          for(var subDoc in subSnapshot.docs){
            Question fetchQuestion = Question.fromFirestore(subDoc);
            questionList.add(fetchQuestion);
          }

        }
      }
      setState(() {
        question = questionList;
      });
      
    } catch(e){
      print("Error fetching question: $e");
    } finally{
      setState(() {
        isFetching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Help Center"),
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
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: isFetching
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You got a problem?',
                style: TextStyle(
                  fontSize: defaultLabelFontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.black
                ),
              ),
              SizedBox(height: 5),
              Text(
                "Don't worry! We will help you solve the problem.",
                style: TextStyle(
                  fontSize: defaultFontSize,
                  fontWeight: FontWeight.w600,
                  color: Colors.black
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Frequently Asked Question 🙋🏻‍♀️',
                style: TextStyle(
                  fontSize: defaultLabelFontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.black
                ),
              ),
              SizedBox(height: 10),
              _buildFrequentlyAskedQuestions(question),
              SizedBox(height: 20),
              Text(
                'All Questions 🙋🏻‍♀️',
                style: TextStyle(
                  fontSize: defaultLabelFontSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.black
                ),
              ),
              SizedBox(height: 10),
              _buildAllQuestions(question)
            ],
          ),
        )
      ),
      floatingActionButton: widget.isUser || widget.isTravelAgent
      ? FloatingActionButton(
          backgroundColor: appBarColor,
          onPressed: (){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatDetailsScreen(userId: widget.userId, receiverUserId: 'A1001'))
            );
          },
          tooltip: 'Customer Support',
          child: Icon(
            Icons.contact_support,
            color: Colors.white,
          ),
        )
      : null
    );
  }

  Widget _buildFrequentlyAskedQuestions(List<Question> questions) {
    // Ensure we only display the top 4 questions
    List<Question> topQuestions = questions.take(4).toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: topQuestions.map((q) {
          return GestureDetector(
            onTap: (){
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => HelpCenterDetailsScreen(userId: widget.userId, questionTitle: q.title, questionContent: q.content,))
              );
            },
            child: Container(
              height: 140,
              width: 150,
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.only(right: 10), // Add margin for spacing
              decoration: BoxDecoration(
                color: appBarColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start, // Align text to start
                children: [
                  Text(
                    q.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: defaultLabelFontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Spacer(), // Pushes the icon to the bottom
                  Align(
                    alignment: Alignment.bottomRight, // Align icon to the bottom right
                    child: Icon(
                      Icons.help_outline, 
                      size: 25,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAllQuestions(List<Question> questions) {
    // Create a copy of the questions list and shuffle it
    List<Question> randomizedQuestions = List.from(questions); // Copy the list
    randomizedQuestions.shuffle(); // Shuffle the copied list

    return Expanded( // Use Expanded to take the available space
      child: ListView.builder( // Use ListView.builder for better performance
        itemCount: randomizedQuestions.length,
        itemBuilder: (context, index) {
          final q = randomizedQuestions[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpCenterDetailsScreen(
                  userId: widget.userId, 
                  questionTitle: q.title, 
                  questionContent: q.content,
                ))
              );
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(15),
              margin: EdgeInsets.only(bottom: 10), // Add margin for spacing
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: primaryColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1), // Shadow color with opacity
                    spreadRadius: 2, // Spread radius of the shadow
                    blurRadius: 5, // Blur radius of the shadow
                    offset: Offset(0, 3), // Offset of the shadow (x, y)
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded( // Wraps the Text widget with Expanded
                    child: Text(
                      q.title,
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: defaultLabelFontSize,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis, // Adds ellipsis
                      maxLines: 1, // Limits to one line
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Colors.black,
                    size: 20,
                  ),
                ],
              ),

            ),
          );
        },
      ),
    );
  }
}

  class Question{
    final String title;
    final String content;
    final int id;

    Question({
      required this.title,
      required this.content,
      required this.id,
    });

    factory Question.fromFirestore(DocumentSnapshot doc){
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>;

      Question question = Question(
        content: data['content'],
        title: data['title'],
        id: data['id'],
      );

      return question;
    }

  }
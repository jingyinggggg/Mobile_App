import 'package:flutter/material.dart';
import 'package:assignment_tripmate/GoogleAPI.dart'; // Import the GoogleTranslateApi
import 'package:assignment_tripmate/language_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:assignment_tripmate/screens/user/homepage.dart';

class LanguageTranslatorScreen extends StatefulWidget {
  final String userId;

  const LanguageTranslatorScreen({super.key, required this.userId});

  @override
  State<LanguageTranslatorScreen> createState() => _LanguageTranslatorScreenState();
}

class _LanguageTranslatorScreenState extends State<LanguageTranslatorScreen> {
  final inputController = TextEditingController(); // Controller for input TextField
  final outputController = TextEditingController(text: "Result here...");
  final googleTranslateApi = GoogleTranslateApi(); // Create an instance of GoogleTranslateApi
  final languageService = LanguageService(); // Create an instance of LanguageService
  final SpeechToText _speechToText = SpeechToText();
  String wordSpoken = '';

  String? inputLanguage;
  String? outputLanguage;
  List<Map<String, String>> languages = []; // Store the fetched languages
  bool isTranslating = false; // To manage translating state
  bool speechEnabled = false;

  @override
  void initState() {
    super.initState();
    fetchLanguages(); // Fetch available languages when the screen loads
    inputController.addListener(translateText); // Add listener for input changes
    initSpeech();
  }

  void initSpeech() async {
    speechEnabled = await _speechToText.initialize();
    setState(() {});
  }

  void _startListening() async {
    if (speechEnabled) {
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {});
    }
  }

  void _stopListening() async {
    if (speechEnabled) {
      await _speechToText.stop();
      setState(() {});
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      wordSpoken = '${result.recognizedWords}';
      // Update the inputController's text with the recognized words
      inputController.text = wordSpoken;
      // Move the cursor to the end of the text field
      inputController.selection = TextSelection.fromPosition(
        TextPosition(offset: inputController.text.length),
      );
    });
  }

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

  Future<void> fetchLanguages() async {
    List<Map<String, String>> fetchedLanguages = await languageService.fetchSupportedLanguages();
    setState(() {
      languages = fetchedLanguages;
      inputLanguage = languages.isNotEmpty ? languages.first['code'] : null;
      outputLanguage = languages.isNotEmpty ? languages.first['code'] : null;
    });
  }

  Future<void> translateText() async {
    if (inputLanguage != null && outputLanguage != null && inputController.text.isNotEmpty) {
      setState(() {
        isTranslating = true; // Start translating
        outputController.text = ""; // Clear the previous result
      });

      try {
        // Use the googleTranslateApi instance to get the translated text
        final translatedText = await googleTranslateApi.translateText(
          inputController.text,
          outputLanguage!,
        );

        setState(() {
          outputController.text = translatedText;
          isTranslating = false; // Translation complete
        });
      } catch (e) {
        // Handle any errors
        setState(() {
          outputController.text = "Error: ${e.toString()}";
          isTranslating = false;
        });
      }
    }
  }

  void _swapLanguages() {
    setState(() {
      final tempLanguage = inputLanguage;
      inputLanguage = outputLanguage;
      outputLanguage = tempLanguage;
    });
    translateText(); // Update translation after swapping languages
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text("Language Translator"),
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
              MaterialPageRoute(
                builder: (context) => UserHomepageScreen(userId: widget.userId),
              ),
            );
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (languages.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: 120,  // Adjust the width as needed
                        child: DropdownButton<String>(
                          value: inputLanguage,
                          isExpanded: true,
                          underline: Container(
                            height: 2,  // Height of the underline
                            color: Color(0xFF467BA1),  // Color of the underline
                          ),
                          onChanged: (newValue) {
                            setState(() {
                              inputLanguage = newValue!;
                            });
                            translateText(); // Update translation when language changes
                          },
                          items: languages.map<DropdownMenuItem<String>>((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Text(lang['name']!),
                            );
                          }).toList(),
                          dropdownColor: Colors.blue.shade100, // Sets dropdown background color
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded),
                        onPressed: _swapLanguages, // Swap languages on button press
                      ),
                      SizedBox(
                        width: 120,  // Adjust the width as needed
                        child: DropdownButton<String>(
                          value: outputLanguage,
                          isExpanded: true,
                          underline: Container(
                            height: 2,  // Height of the underline
                            color: Color(0xFF467BA1),  // Color of the underline
                          ),
                          onChanged: (newValue) {
                            setState(() {
                              outputLanguage = newValue!;
                            });
                            translateText(); // Update translation when language changes
                          },
                          items: languages.map<DropdownMenuItem<String>>((lang) {
                            return DropdownMenuItem<String>(
                              value: lang['code'],
                              child: Text(lang['name']!),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  )
                else
                  const Center(child: CircularProgressIndicator()),

                const SizedBox(height: 20),

                TextField(
                  controller: inputController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                    ),
                    hintText: _speechToText.isListening
                              ? "Listening ..."
                              : speechEnabled
                                ? "Enter text to translate or use the microphone for voice input..."
                                : "Text or speech not available"
                  ),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color: Color(0xFF467BA1),
                  ),
                ),

                const SizedBox(height: 20),

                TextField(
                  controller: outputController,
                  readOnly: true,
                  maxLines: 5,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF467BA1), width: 1.5),
                    ),
                    hintText: isTranslating ? "Translating..." : "Result here...", // Show translating hint
                  ),
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Color(0xFF467BA1),
        onPressed: _speechToText.isListening ? _stopListening : _startListening,
        tooltip: 'Listen',
        child: Icon(
          _speechToText.isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}

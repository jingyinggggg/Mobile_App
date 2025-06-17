import 'package:assignment_tripmate/constants.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiApi {
  Future<String> generateItinerary(String departDate, String returnDate, String country, String budget, String travelStyle, String pax) async {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: apiKey,
    );

    final prompt = '''
      Create a travel itinerary for $pax people trip from $departDate to $returnDate in $country with a budget of $budget and a travel style of $travelStyle.
      Please provide the following:
      - Title of the trip
      - Day-wise itinerary (e.g., Day 1, Day 2, etc.)
      - Additional notes for the trip
    ''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String generatedText = response.text ?? 'No itinerary generated.';

      return generatedText;
    } catch (e) {
      print('Error generating itinerary: $e');
      return 'Error generating itinerary.';
    }

  }
}
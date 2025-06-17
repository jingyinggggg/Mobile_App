import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleTranslateApi {
  final String _apiKey = 'AIzaSyBFCbi7ht9miK8Mcqrusg25VWZzvLNa8qE'; // Replace with your API key

  Future<String> translateText(String text, String targetLanguage) async {
    final url = 'https://translation.googleapis.com/language/translate/v2?key=$_apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
        'target': targetLanguage,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('data') &&
          data['data'].containsKey('translations') &&
          data['data']['translations'].isNotEmpty) {
        return data['data']['translations'][0]['translatedText'];
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData.containsKey('error')
          ? errorData['error']['message']
          : 'Failed to translate text';
      throw Exception(errorMessage);
    }
  }

  Future<String> detectLanguage(String text) async {
    final url = 'https://translation.googleapis.com/language/translate/v2/detect?key=$_apiKey';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'q': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.containsKey('data') &&
          data['data'].containsKey('detections') &&
          data['data']['detections'].isNotEmpty &&
          data['data']['detections'][0].isNotEmpty) {
        return data['data']['detections'][0][0]['language'];
      } else {
        throw Exception('Unexpected response format');
      }
    } else {
      final errorData = jsonDecode(response.body);
      final errorMessage = errorData.containsKey('error')
          ? errorData['error']['message']
          : 'Failed to detect language';
      throw Exception(errorMessage);
    }
  }
}

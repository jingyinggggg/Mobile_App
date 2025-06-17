import 'dart:convert';
import 'package:http/http.dart' as http;

class LanguageService {
  Future<List<Map<String, String>>> fetchSupportedLanguages() async {
    const url = 'https://libretranslate.com/languages';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List languages = jsonDecode(response.body);
        return languages.map<Map<String, String>>((lang) {
          return {
            'code': lang['code'],
            'name': lang['name'],
          };
        }).toList();
      } else {
        throw Exception('Failed to load languages');
      }
    } catch (e) {
      print('Error fetching languages: $e');
      return [];
    }
  }
}

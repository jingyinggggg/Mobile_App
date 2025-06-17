import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> getAmadeusToken() async {
  // Define the URL for the token request
  final url = Uri.parse('https://test.api.amadeus.com/v1/security/oauth2/token');
  
  // API credentials from Amadeus dashboard
  final clientId = 'TMlifrazAHYWNoxNmOXUki1vCKv4DBVt';
  final clientSecret = 'wRafdrHSpna6AFad';

  // Set up the request headers and body
  final headers = {'Content-Type': 'application/x-www-form-urlencoded'};
  final body = {
    'grant_type': 'client_credentials',
    'client_id': clientId,
    'client_secret': clientSecret,
  };

  // Make the POST request
  final response = await http.post(
    url,
    headers: headers,
    body: body,
  );

  // Check if the request was successful
  if (response.statusCode == 200) {
    // Decode the response body
    final Map<String, dynamic> data = json.decode(response.body);
    // Return the access token
    return data['access_token'];
  } else {
    // If something went wrong, print the error and return null
    print('Failed to get access token: ${response.body}');
    return null;
  }
}

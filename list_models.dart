import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyCBfi3KLIRV_rg7E4YNWXRg_WjOTXDzQes';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  
  print('🔍 Listing available models...');
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['models'] as List;
      print('✅ Found ${models.length} models:');
      for (var m in models) {
        if (m['supportedGenerationMethods'].contains('generateContent')) {
           print(' - ${m['name']}');
        }
      }
    } else {
      print('❌ Failed to list models. Status: ${response.statusCode}');
      print('Body: ${response.body}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = 'AIzaSyCBfi3KLIRV_rg7E4YNWXRg_WjOTXDzQes';
  final url = 'https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey';
  
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final models = data['models'] as List;
      for (var m in models) {
        // Just print the name, nothing else, to save space
        print(m['name'].toString().replaceAll('models/', '')); 
      }
    }
  } catch (e) {
    print(e);
  }
}

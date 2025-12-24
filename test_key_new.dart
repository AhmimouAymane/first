import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = 'AIzaSyCBfi3KLIRV_rg7E4YNWXRg_WjOTXDzQes';
  
  print('Checking NEW key validity...');

  try {
     print('Testing gemini-1.5-flash...');
     final m = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
     final response = await m.generateContent([Content.text('Hi')]);
     print('✅ Key works with gemini-1.5-flash! Response: ${response.text}');
  } catch (e) {
    print('❌ Key failed with gemini-1.5-flash: $e');
  }

  try {
     print('Testing gemini-pro...');
     final m = GenerativeModel(model: 'gemini-pro', apiKey: apiKey);
     final response = await m.generateContent([Content.text('Hi')]);
     print('✅ Key works with gemini-pro! Response: ${response.text}');
  } catch (e) {
    print('❌ Key failed with gemini-pro: $e');
  }
}

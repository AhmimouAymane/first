import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  const apiKey = 'AIzaSyBuU6q7kS5B_j-vpf114GGHY1eUIZeBhKc';
  const modelName = 'gemini-1.5-flash';
  
  print('Testing model: $modelName...');
  try {
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
    );
    
    final content = [Content.text('Say hello briefly in French')];
    final response = await model.generateContent(content);
    print('✅ Success with $modelName: ${response.text}');
  } catch (e) {
    print('❌ Failed with $modelName: $e');
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';
// Kept for image generation if needed

class GeminiService {
  // TODO: Replace with your VALID API Key from Google AI Studio
  // Ensure this key has "Generative Language API" enabled.
  static const String _apiKey = 'AIzaSyDmooKfmZYGVXj6F4Z3WIpd-sxeTAxfxFY';
  
  // Use the standard model name. The SDK handles the URL/Version.
  // Using gemini-2.5-flash which is available in the model list
  final String _modelName = 'gemini-2.5-flash';
  
  late final GenerativeModel _model;
  late final ChatSession _chat;
  
  final List<Map<String, dynamic>> _localHistory = []; // For UI display if needed
  List<Map<String, dynamic>> get history => _localHistory;

  GeminiService() {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: _apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 1024,
      ),
    );
    _chat = _model.startChat(history: []);
  }

  /// Send a message to Gemini and get a response
  Future<String> sendMessage(String message) async {
    print('🎤 Voice Input Recognized: "$message"'); // Debug print to verify STT
    try {
      // 1. Detect image generation request (Legacy logic preserved)
      final lowerMsg = message.toLowerCase();
      bool isImageRequest = [
        'génère', 'dessin', 'crée', 'fais', 'photo', 'image', 'montre', 'peux-tu', 'peux tu', 'veux voir', 'fait', 'fais'
      ].any((word) => lowerMsg.contains(word));

      // 2. Prepare prompt
      final String promptToSend = isImageRequest 
          ? "L'utilisateur veut une image. Réponds brièvement que tu vas la créer. Prompt: $message"
          : message;

      // 3. Send to Gemini using SDK
      print('🌐 Sending to Gemini ($_modelName)...');
      final response = await _chat.sendMessage(Content.text(promptToSend));
      final responseText = response.text;

      if (responseText == null) {
        return 'L\'IA a renvoyé une réponse vide.';
      }

      // 4. Handle Image Generation (Pollinations.ai)
      String finalResponse = responseText;
      if (isImageRequest) {
        String cleanPrompt = message.toLowerCase();
        final stopWords = [
          'dessine-moi', 'dessine moi', 'dessine', 'dessiner', 'génère', 'génère-moi', 'génère moi', 
          'crée', 'fais une', 'fais-moi', 'montre-moi', 'montre moi', 'montre', 
          'une image de', 'une photo de', 'un dessin de', 'le', 'la', 'un', 'une', 'de', 'du', "d'", 'des',
          'est ce que', 'est-ce que', 'tu peux', 'peux-tu', 'peux tu'
        ];
        for (var word in stopWords) {
          cleanPrompt = cleanPrompt.replaceAll(word, '').trim();
        }
        if (cleanPrompt.isEmpty) cleanPrompt = 'nature';
        final seed = DateTime.now().millisecondsSinceEpoch % 100000;
        final encodedPrompt = Uri.encodeComponent(cleanPrompt);
        final imageUrl = 'https://image.pollinations.ai/prompt/$encodedPrompt?width=1024&height=1024&nologo=true&seed=$seed';
        finalResponse = '$finalResponse\n\n![Image de $cleanPrompt]($imageUrl)';
      }

      // 5. Update Local History (for UI)
      // Note: The SDK's _chat object maintains its own history automatically!
      _localHistory.add({'role': 'user', 'text': message});
      _localHistory.add({'role': 'model', 'text': finalResponse});
      
      return finalResponse;

    } catch (e) {
      print('❌ Gemini Service Error: $e');
      if (e.toString().contains('404')) {
        return 'Erreur 404: Modèle non trouvé ou Clé API invalide. Vérifiez votre clé API.';
      }
      return 'Erreur de connexion: ${e.toString()}';
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _localHistory.clear();
    // Re-initialize chat to clear SDK history
    _chat = _model.startChat(history: []);
  }
}

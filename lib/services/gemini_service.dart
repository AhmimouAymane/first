import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  static const String _apiKey = 'AIzaSyBuU6q7kS5B_j-vpf114GGHY1eUIZeBhKc';
  String _workingUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent';
  
  final List<Map<String, dynamic>> _conversationHistory = [];
  List<Map<String, dynamic>> get history => _conversationHistory;
  
  Future<void>? _discoveryFuture;
  
  GeminiService() {
    _discoveryFuture = _findWorkingModel();
  }

  Future<void> _findWorkingModel() async {
    final models = [
      'gemini-flash-latest',
      'gemini-1.5-flash',
      'gemini-1.5-flash-8b',
      'gemini-1.5-pro',
      'gemini-2.0-flash-exp',
      'gemini-2.0-flash',
      'gemini-pro-latest',
      'gemini-pro',
    ];
    final versions = ['v1beta', 'v1', 'v1beta1'];

    for (var model in models) {
      for (var version in versions) {
        final url = 'https://generativelanguage.googleapis.com/$version/models/$model:generateContent';
        try {
          print('🔍 Testing: $url ...');
          final response = await http.post(
            Uri.parse('$url?key=$_apiKey'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'contents': [{'parts': [{'text': 'hi'}]}]
            }),
          ).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            print('🎯 SUCCESS! Found working Gemini URL: $url');
            _workingUrl = url;
            return;
          } else {
            print('❌ Status ${response.statusCode} for $url');
          }
        } catch (e) {
          print('⚠️ Error for $url: $e');
        }
      }
    }
  }

  /// Send a message to Gemini and get a response
  Future<String> sendMessage(String message) async {
    // Wait for discovery to finish if it's still running
    if (_discoveryFuture != null) {
      await _discoveryFuture;
    }

    try {
      final contents = <Map<String, dynamic>>[];
      
      // Detect image generation request
      final lowerMsg = message.toLowerCase();
      bool isImageRequest = [
        'génère', 'dessin', 'crée', 'fais', 'photo', 'image', 'montre', 'peux-tu', 'peux tu', 'veux voir', 'fait', 'fais'
      ].any((word) => lowerMsg.contains(word));

      // 1. Build request contents from history (ENSURING ALTERNATION)
      for (var chat in _conversationHistory) {
        contents.add({
          'role': chat['role'],
          'parts': [{'text': chat['text'].split('![').first.trim()}]
        });
      }
      
      // 2. Add current message
      final currentMessageText = isImageRequest 
          ? "L'utilisateur veut une image. Réponds brièvement que tu vas la créer. Prompt: $message"
          : message;
          
      contents.add({
        'role': 'user',
        'parts': [{'text': currentMessageText}]
      });

      // Prepare request body
      final body = {
        'contents': contents,
        'generationConfig': {
          'temperature': 0.7,
          'topK': 40,
          'topP': 0.95,
          'maxOutputTokens': 1024,
        }
      };

      // Send POST request
      print('🌐 Gemini API Request to: $_workingUrl');
      final response = await http.post(
        Uri.parse('$_workingUrl?key=$_apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      print('🌐 Gemini API Response Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
          return 'Désolé, je n\'ai pas reçu de réponse valide de l\'IA.';
        }

        final candidates = data['candidates'] as List;
        final firstCandidate = candidates[0];
        
        if (firstCandidate['content'] == null || firstCandidate['content']['parts'] == null) {
          return 'L\'IA a renvoyé une réponse vide.';
        }

        final parts = firstCandidate['content']['parts'] as List;
        
        if (parts.isNotEmpty) {
          String responseText = parts[0]['text'] as String;
          
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
            responseText = '$responseText\n\n![Image de $cleanPrompt]($imageUrl)';
          }

          // SUCCESS: Only now add to persistent history
          _conversationHistory.add({'role': 'user', 'text': message});
          _conversationHistory.add({'role': 'model', 'text': responseText});
          
          if (_conversationHistory.length > 20) {
            _conversationHistory.removeRange(0, 2);
          }
          
          return responseText;
        }
        return 'Désolé, je n\'ai pas pu extraire de texte.';
      } else {
        print('❌ Gemini API Error (${response.statusCode}): ${response.body}');
        final errorData = json.decode(response.body);
        final errorMessage = errorData['error']?['message'] ?? 'Unknown error';
        return 'Erreur API (${response.statusCode}): $errorMessage';
      }
    } catch (e) {
      print('❌ Gemini Service Catch Error: $e');
      return 'Erreur de connexion: ${e.toString()}';
    }
  }

  /// Clear conversation history
  void clearHistory() {
    _conversationHistory.clear();
  }
}

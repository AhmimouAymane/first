import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CNNApiService {
  // IMPORTANT: Update this URL based on where you run your Flask server
  // 
  // For Android Emulator: 'http://10.0.2.2:5000'
  // For iOS Simulator: 'http://localhost:5000'
  // For Physical Device on same WiFi: 'http://YOUR_COMPUTER_IP:5000'
  //   (Find your IP: Windows = ipconfig, Mac/Linux = ifconfig)
  // For Production: 'https://your-deployed-server.com'
  
  static const String baseUrl = 'http://192.168.1.17:5000';  // Default for Android Emulator
 
  // Check if server is running
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('Server health check failed: $e');
      return false;
    }
  }

  // Get list of supported classes
  static Future<List<String>?> getClasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/classes'),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<String>.from(data['classes']);
      }
      return null;
    } catch (e) {
      print('Error getting classes: $e');
      return null;
    }
  }

  // Predict image - Returns fruit/vegetable classification
  static Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict'),
      );
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      print('📤 Sending request to: $baseUrl/predict');
      
      // Send request with timeout
      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );
      
      // Get response
      var response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check if response has required fields
        if (data['predicted_class'] != null) {
          // Sort all predictions by confidence
          List<dynamic> allPredictions = data['all_predictions'] ?? [];
          
          // Get top 3 predictions
          List<Map<String, dynamic>> topPredictions = allPredictions
              .take(3)
              .map((pred) => {
                'class': pred['class'],
                'confidence': pred['confidence'],
              })
              .toList();
          
          print('✅ Prediction: ${data['predicted_class']} (${(data['confidence'] * 100).toStringAsFixed(1)}%)');
          
          return {
            'success': true,
            'label': data['predicted_class'],
            'confidence': data['confidence'],
            'top_predictions': topPredictions,
            'all_predictions': allPredictions,
          };
        } else {
          return {
            'success': false,
            'error': 'Invalid response format',
          };
        }
      } else {
        // Try to get error message from response
        try {
          final errorData = json.decode(response.body);
          return {
            'success': false,
            'error': errorData['error'] ?? 'Server error: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Server error: ${response.statusCode}',
          };
        }
      }
    } on TimeoutException catch (e) {
      print('⏱️ Request timeout: $e');
      return {
        'success': false,
        'error': 'La requête a expiré. Vérifiez votre connexion.',
      };
    } on SocketException catch (e) {
      print('🔌 Connection error: $e');
      return {
        'success': false,
        'error': 'Impossible de se connecter au serveur. Assurez-vous qu\'il est démarré.',
      };
    } catch (e) {
      print('❌ Error during prediction: $e');
      return {
        'success': false,
        'error': 'Erreur de connexion: ${e.toString()}',
      };
    }
  }
}
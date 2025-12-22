import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class ANNApiService {
  static const String baseUrl = 'http://192.168.1.17:5000';
  
  /// Check if ANN server is running
  static Future<bool> checkServerHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (e) {
      print('ANN Health check error: $e');
      return false;
    }
  }
  
  /// Get available classes from ANN model
  static Future<List<String>> getClasses() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ann/classes'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> classes = data['classes'];
        return classes.cast<String>();
      }
      return [];
    } catch (e) {
      print('Error getting ANN classes: $e');
      return [];
    }
  }
  
  /// Classify image using ANN model
  static Future<Map<String, dynamic>> predictImage(File imageFile) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/ann/predict'),
      );
      
      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
        ),
      );
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('ANN Prediction error: $e');
      return {
        'success': false,
        'error': 'Connection failed: $e',
      };
    }
  }
  
  /// Test connection with different URLs
  static Future<String> testConnection() async {
    final urls = [
      'http://10.0.2.2:5000',      // Android emulator
      'http://localhost:5000',      // iOS simulator
      'http://192.168.1.17:5000',   // Physical device
    ];
    
    for (var url in urls) {
      try {
        final response = await http.get(
          Uri.parse('$url/health'),
        ).timeout(const Duration(seconds: 2));
        
        if (response.statusCode == 200) {
          return url;
        }
      } catch (e) {
        print('URL $url failed: $e');
      }
    }
    
    throw Exception('No working server URL found');
  }
}
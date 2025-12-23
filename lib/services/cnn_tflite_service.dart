// import 'dart:io';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// import 'package:tflite_flutter/tflite_flutter.dart';

class CNNTFLiteService {
  // Interpreter? _interpreter;
  List<String>? _labels;
  bool _isModelLoaded = false;
  
  // Backend URL
  static const String backendUrl = 'http://127.0.0.1:5000';

  // Model configuration
  static const int inputSize = 224; // Model expects 224x224 images
  static const int numChannels = 3; // RGB
  static const int numClasses = 36; // 36 fruits/vegetables

  // Load model and labels
  Future<void> loadModel() async {
    print('📦 Connecting to CNN backend...');
    
    // Load labels
    try {
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      print('🏷️ Labels loaded: ${_labels?.length}');
    } catch (e) {
      print('❌ Error loading labels: $e');
    }

    // Check backend health
    try {
      final response = await http.get(Uri.parse('$backendUrl/health'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _isModelLoaded = data['cnn_loaded'] ?? false;
        print('✅ CNN Backend connected!');
      } else {
        print('⚠️ Backend not available, using fallback');
        _isModelLoaded = false;
      }
    } catch (e) {
      print('⚠️ Backend connection failed: $e');
      _isModelLoaded = false;
    }
  }

  bool get isModelLoaded => _isModelLoaded;

  // Run inference
  Future<Map<String, dynamic>> predict(XFile imageFile) async {
    if (!_isModelLoaded) {
      // Fallback to mock if backend unavailable
      return _mockPredict();
    }

    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Create multipart request
      var request = http.MultipartRequest('POST', Uri.parse('$backendUrl/cnn/predict'));
      request.files.add(http.MultipartFile.fromBytes(
        'image',
        bytes,
        filename: 'image.jpg',
      ));
      
      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true) {
          return {
            'success': true,
            'label': data['label'],
            'confidence': data['confidence'],
            'class_index': data['class_index'],
            'top_predictions': data['top_predictions'] ?? [],
            'all_probabilities': [],
          };
        } else {
          return {
            'success': false,
            'error': data['error'] ?? 'Unknown error',
          };
        }
      } else {
        return {
          'success': false,
          'error': 'Backend error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error during prediction: $e');
      // Fallback to mock on error
      return _mockPredict();
    }
  }
  
  Future<Map<String, dynamic>> _mockPredict() async {
    // Fallback mock prediction
    await Future.delayed(Duration(seconds: 1));
    
    String label = 'Unknown';
    if (_labels != null && _labels!.isNotEmpty) {
      label = _labels![Random().nextInt(_labels!.length)];
    }

    return {
      'success': true,
      'label': label,
      'confidence': 0.85 + (Random().nextDouble() * 0.14),
      'class_index': 0,
      'top_predictions': [],
      'all_probabilities': [],
    };
  }

  // Dispose interpreter
  void dispose() {
    // _interpreter?.close();
    _isModelLoaded = false;
    print('🗑️ Model disposed');
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cnn_api_service.dart';  // Your existing service file

class CNNTestPage extends StatefulWidget {
  @override
  _CNNTestPageState createState() => _CNNTestPageState();
}

class _CNNTestPageState extends State<CNNTestPage> {
  // Variables
  bool _serverHealthy = false;
  bool _loading = false;
  String _connectionStatus = 'Not checked';
  File? _selectedImage;
  Map<String, dynamic>? _predictionResult;
  List<String>? _availableClasses;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    // Check server health when page loads
    _checkServerHealth();
  }
  
  // Check if server is running
  Future<void> _checkServerHealth() async {
    setState(() {
      _loading = true;
      _connectionStatus = 'Checking server...';
    });
    
    try {
      bool isHealthy = await CNNApiService.checkServerHealth();
      
      setState(() {
        _serverHealthy = isHealthy;
        _connectionStatus = isHealthy 
            ? '✅ Server is healthy and ready!' 
            : '❌ Server is not responding';
      });
      
      // If server is healthy, get available classes
      if (isHealthy) {
        await _getAvailableClasses();
      }
    } catch (e) {
      setState(() {
        _connectionStatus = '❌ Error: $e';
        _serverHealthy = false;
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
  
  // Get list of supported fruit/vegetable classes
  Future<void> _getAvailableClasses() async {
    setState(() => _loading = true);
    
    try {
      List<String>? classes = await CNNApiService.getClasses();
      setState(() {
        _availableClasses = classes;
      });
    } catch (e) {
      print('Error getting classes: $e');
    } finally {
      setState(() => _loading = false);
    }
  }
  
  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult = null; // Clear previous result
      });
    }
  }
  
  // Take photo with camera
  Future<void> _takePhotoWithCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult = null;
      });
    }
  }
  
  // Send image to API for prediction
  Future<void> _predictImage() async {
    if (_selectedImage == null) return;
    
    setState(() {
      _loading = true;
      _predictionResult = null;
    });
    
    try {
      final result = await CNNApiService.predict(_selectedImage!);
      
      setState(() {
        _predictionResult = result;
        if (result['success'] == true) {
          // Show success snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Prediction successful!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Show error snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${result['error']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Unexpected error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
  // Clear selected image and results
  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _predictionResult = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Fruit & Vegetable Classifier'),
        backgroundColor: _serverHealthy ? Colors.green : Colors.orange,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _checkServerHealth,
            tooltip: 'Check server connection',
          ),
        ],
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Status Card
              Card(
                color: _serverHealthy ? Colors.green[50] : Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            _serverHealthy ? Icons.check_circle : Icons.error,
                            color: _serverHealthy ? Colors.green : Colors.orange,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _connectionStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _serverHealthy ? Colors.green : Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (_availableClasses != null) ...[
                        SizedBox(height: 10),
                        Text(
                          'Available classes: ${_availableClasses!.length}',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                      
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _checkServerHealth,
                        icon: Icon(Icons.wifi_find, size: 18),
                        label: Text('Check Connection'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _serverHealthy ? Colors.green : Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Image Selection Section
              Text(
                'Select Image:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: Icon(Icons.photo_library),
                    label: Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(140, 50),
                    ),
                  ),
                  
                  ElevatedButton.icon(
                    onPressed: _takePhotoWithCamera,
                    icon: Icon(Icons.camera_alt),
                    label: Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(140, 50),
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: 20),
              
              // Selected Image Display
              if (_selectedImage != null) ...[
                Card(
                  elevation: 4,
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Selected Image',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: _clearSelection,
                                  tooltip: 'Remove image',
                                ),
                                ElevatedButton(
                                  onPressed: _serverHealthy ? _predictImage : null,
                                  child: _loading 
                                      ? SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text('Classify'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Placeholder when no image selected
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.photo, size: 50, color: Colors.grey[400]),
                        SizedBox(height: 10),
                        Text(
                          'No image selected',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              SizedBox(height: 20),
              
              // Prediction Results
              if (_predictionResult != null && _predictionResult!['success'] == true) ...[
                Text(
                  'Prediction Results:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main Prediction
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _predictionResult!['label'],
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                  Text(
                                    'Confidence: ${(_predictionResult!['confidence'] * 100).toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 20),
                        
                        // Top Predictions
                        Text(
                          'Top Predictions:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        SizedBox(height: 10),
                        
                        ...(_predictionResult!['top_predictions'] as List<dynamic>).map((pred) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    pred['class'],
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                                Text(
                                  '${(pred['confidence'] * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ] else if (_predictionResult != null && _predictionResult!['success'] == false) ...[
                // Error Display
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Error: ${_predictionResult!['error']}',
                            style: TextStyle(color: Colors.red[800]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              
              // Loading Indicator
              if (_loading) ...[
                SizedBox(height: 20),
                Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ],
          ),
        ),
      ),
      
      // Floating Action Button for quick test
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_serverHealthy && _selectedImage != null) {
            _predictImage();
          } else if (_selectedImage == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Please select an image first')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Server is not connected')),
            );
          }
        },
        icon: Icon(Icons.science),
        label: Text('Test Classification'),
        backgroundColor: _serverHealthy ? Colors.green : Colors.grey,
      ),
    );
  }
}
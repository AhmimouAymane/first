import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ann_api_service.dart';

class ANNScannerPage extends StatefulWidget {
  const ANNScannerPage({super.key});
  
  @override
  _ANNScannerPageState createState() => _ANNScannerPageState();
}

class _ANNScannerPageState extends State<ANNScannerPage> {
  // State variables
  File? _selectedImage;
  bool _isLoading = false;
  bool _serverConnected = false;
  String _connectionStatus = 'Checking connection...';
  Map<String, dynamic>? _predictionResult;
  List<String> _availableClasses = [];
  
  @override
  void initState() {
    super.initState();
    _checkServerConnection();
    _loadClasses();
  }
  
  // Check if ANN server is running
  Future<void> _checkServerConnection() async {
    setState(() {
      _connectionStatus = 'Connecting to ANN server...';
    });
    
    try {
      final connected = await ANNApiService.checkServerHealth();
      
      setState(() {
        _serverConnected = connected;
        _connectionStatus = connected 
            ? '✅ Connected to ANN Server'
            : '❌ ANN Server not reachable';
      });
    } catch (e) {
      setState(() {
        _serverConnected = false;
        _connectionStatus = '❌ Connection error: $e';
      });
    }
  }
  
  // Load available classes
  Future<void> _loadClasses() async {
    final classes = await ANNApiService.getClasses();
    setState(() {
      _availableClasses = classes;
    });
  }
  
  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _predictionResult = null;
      });
      _classifyImage(_selectedImage!);
    }
  }
  
  // Take image from camera
  Future<void> _takeImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _predictionResult = null;
      });
      _classifyImage(_selectedImage!);
    }
  }
  
  // Classify image using ANN
  Future<void> _classifyImage(File imageFile) async {
    if (!_serverConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ANN server not connected'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    final result = await ANNApiService.predictImage(imageFile);
    
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _predictionResult = result['data'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${result['error']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
  
  // Build connection status widget
  Widget _buildConnectionStatus() {
    Color statusColor = _serverConnected ? Colors.green : Colors.red;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              _serverConnected ? Icons.check_circle : Icons.error,
              color: statusColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ANN Server Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    _connectionStatus,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            if (!_serverConnected)
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _checkServerConnection,
                tooltip: 'Retry Connection',
              ),
          ],
        ),
      ),
    );
  }
  
  // Build image preview
  Widget _buildImagePreview() {
    if (_selectedImage == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.image, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text('No image selected'),
            ],
          ),
        ),
      );
    }
    
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue),
            borderRadius: BorderRadius.circular(10),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.file(_selectedImage!, fit: BoxFit.cover),
          ),
        ),
        if (_isLoading)
          Container(
            height: 200,
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
      ],
    );
  }
  
  // Build prediction results
  Widget _buildPredictionResults() {
    if (_predictionResult == null) return Container();
    
    final predictions = _predictionResult!['predictions'] as List;
    final primary = _predictionResult!['primary'];
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ANN Prediction Results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            
            // Primary prediction
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          primary['class'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Confidence: ${primary['confidence'].toStringAsFixed(2)}%',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 10),
            const Text(
              'Top Predictions:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            
            // All predictions
            ...predictions.map<Widget>((prediction) {
              return ListTile(
                leading: CircleAvatar(
                  child: Text(
                    (predictions.indexOf(prediction) + 1).toString(),
                  ),
                ),
                title: Text(prediction['class']),
                trailing: Text(
                  '${prediction['confidence'].toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: prediction['confidence'] > 50 
                        ? Colors.green 
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            }),
            
            // Model type
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'Model: ${_predictionResult!['model_type']}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ANN Image Classifier'),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('ANN Model Info'),
                  content: const Text(
                    'Artificial Neural Network (ANN) for classifying 36 types of fruits and vegetables.\n\n'
                    '• Input: 28x28 RGB images\n'
                    '• Output: 36 classes\n'
                    '• Architecture: 3 Dense layers with Dropout\n'
                    '• Optimizer: Adam',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Connection status
            _buildConnectionStatus(),
            
            const SizedBox(height: 20),
            
            // Image source buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _takeImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickImageFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Image preview
            _buildImagePreview(),
            
            const SizedBox(height: 20),
            
            // Prediction results
            if (_predictionResult != null) _buildPredictionResults(),
            
            // Available classes
            if (_availableClasses.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Available Classes (36)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableClasses
                            .map(
                              (cls) => Chip(
                                label: Text(cls),
                                backgroundColor: Colors.deepPurple[50],
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      
      // Clear button
      floatingActionButton: _selectedImage != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _predictionResult = null;
                });
              },
              backgroundColor: Colors.red,
              tooltip: 'Clear Image',
              child: const Icon(Icons.clear),
            )
          : null,
    );
  }
}
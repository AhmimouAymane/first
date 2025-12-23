import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/cnn_api_service.dart';

class CNNTestPage extends StatefulWidget {
  const CNNTestPage({super.key});

  @override
  _CNNTestPageState createState() => _CNNTestPageState();
}

class _CNNTestPageState extends State<CNNTestPage> {
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
    _checkServerHealth();
  }
  
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
  
  Future<void> _pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult = null;
      });
    }
  }
  
  Future<void> _takePhotoWithCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
        _predictionResult = null;
      });
    }
  }
  
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('✅ Prediction successful!'),
              backgroundColor: const Color(0xFF5CFBAC),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: ${result['error']}'),
              backgroundColor: const Color(0xFFFF5252),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Unexpected error: $e'),
          backgroundColor: const Color(0xFFFF5252),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _loading = false);
    }
  }
  
  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _predictionResult = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Fruit & Vegetable Classifier',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF5CFBAC)),
            onPressed: _checkServerHealth,
            tooltip: 'Check server connection',
          ),
        ],
      ),
      
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Connection Status Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _serverHealthy 
                    ? const Color(0xFF5CFBAC).withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _serverHealthy 
                      ? const Color(0xFF5CFBAC).withOpacity(0.3)
                      : Colors.orange.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _serverHealthy 
                              ? const Color(0xFF5CFBAC).withOpacity(0.2)
                              : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          _serverHealthy ? Icons.check_circle : Icons.error,
                          color: _serverHealthy ? const Color(0xFF5CFBAC) : Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Server Status',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _connectionStatus,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _serverHealthy ? const Color(0xFF5CFBAC) : Colors.orange,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  if (_availableClasses != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Available classes: ${_availableClasses!.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9E9E9E),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Image Selection Section
            const Text(
              'Select Image',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickImageFromGallery,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2E2E2E),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5CFBAC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.photo_library,
                              color: Color(0xFF121212),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Gallery',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: InkWell(
                    onTap: _takePhotoWithCamera,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 120,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF2E2E2E),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5CFBAC),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF121212),
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Camera',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Selected Image Display
            if (_selectedImage != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF2E2E2E),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: SizedBox(
                        height: 250,
                        width: double.infinity,
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Selected Image',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Color(0xFFFF5252)),
                                onPressed: _clearSelection,
                                tooltip: 'Remove image',
                              ),
                              const SizedBox(width: 8),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: const Color(0xFF5CFBAC),
                                ),
                                child: ElevatedButton(
                                  onPressed: _serverHealthy && !_loading ? _predictImage : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _loading 
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF121212),
                                          ),
                                        )
                                      : const Text(
                                          'Classify',
                                          style: TextStyle(
                                            color: Color(0xFF121212),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  border: Border.all(color: const Color(0xFF2E2E2E)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo,
                        size: 60,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No image selected',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // Prediction Results
            if (_predictionResult != null && _predictionResult!['success'] == true) ...[
              const Text(
                'Prediction Results',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF5CFBAC).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF5CFBAC).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5CFBAC),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            color: Color(0xFF121212),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _predictionResult!['label'],
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF5CFBAC),
                                ),
                              ),
                              Text(
                                'Confidence: ${(_predictionResult!['confidence'] * 100).toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF9E9E9E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Top Predictions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    ...(_predictionResult!['top_predictions'] as List<dynamic>).map((pred) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF5CFBAC),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                pred['class'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              '${(pred['confidence'] * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5CFBAC),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ] else if (_predictionResult != null && _predictionResult!['success'] == false) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Color(0xFFFF5252)),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Error: ${_predictionResult!['error']}',
                        style: const TextStyle(color: Color(0xFFFF5252)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (_loading && _selectedImage == null) ...[
              const SizedBox(height: 32),
              const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF5CFBAC),
                ),
              ),
            ],
            
            const SizedBox(height: 32),
          ],
        ),
      ),
      
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: _serverHealthy && _selectedImage != null
                ? [const Color(0xFF5CFBAC), const Color(0xFF4AE89B)]
                : [Colors.grey.shade700, Colors.grey.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            if (_serverHealthy && _selectedImage != null) {
              _predictImage();
            } else if (_selectedImage == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Please select an image first'),
                  backgroundColor: const Color(0xFFFF5252),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Server is not connected'),
                  backgroundColor: const Color(0xFFFF5252),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.science, color: Color(0xFF121212)),
          label: const Text(
            'Test Classification',
            style: TextStyle(
              color: Color(0xFF121212),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
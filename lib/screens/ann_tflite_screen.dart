import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ann_tflite_service.dart';

class ANNTFLiteScreen extends StatefulWidget {
  const ANNTFLiteScreen({super.key});

  @override
  State<ANNTFLiteScreen> createState() => _ANNTFLiteScreenState();
}

class _ANNTFLiteScreenState extends State<ANNTFLiteScreen> {
  final ANNTFLiteService _modelService = ANNTFLiteService();
  final ImagePicker _picker = ImagePicker();
  
  XFile? _selectedImage;
  Uint8List? _imageBytes;
  Map<String, dynamic>? _prediction;
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    setState(() => _isLoading = true);
    try {
      await _modelService.loadModel();
      setState(() {
        _modelLoaded = true;
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Modèle ANN chargé avec succès'),
            backgroundColor: const Color(0xFFFFA726),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: ${e.toString()}'),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _imageBytes = bytes;
          _prediction = null;
        });
      }
    } catch (e) {
      _showError('Erreur: $e');
    }
  }

  Future<void> _classifyImage() async {
    if (_selectedImage == null || !_modelLoaded) return;

    setState(() => _isLoading = true);
    
    try {
      final result = await _modelService.predict(_selectedImage!);
      
      if (result['success'] == true) {
        setState(() {
          _prediction = result;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        _showError(result['error'] ?? 'Erreur inconnue');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF5252),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _getEmoji(String className) {
    final emojiMap = {
      'apple': '🍎', 'banana': '🍌', 'beetroot': '🥕', 'bell pepper': '🫑',
      'cabbage': '🥬', 'capsicum': '🌶️', 'carrot': '🥕', 'cauliflower': '🥦',
      'chilli pepper': '🌶️', 'corn': '🌽', 'cucumber': '🥒', 'eggplant': '🍆',
      'garlic': '🧄', 'ginger': '🫚', 'grapes': '🍇', 'jalepeno': '🌶️',
      'kiwi': '🥝', 'lemon': '🍋', 'lettuce': '🥬', 'mango': '🥭',
      'onion': '🧅', 'orange': '🍊', 'paprika': '🫑', 'pear': '🍐',
      'peas': '🫛', 'pineapple': '🍍', 'pomegranate': '🍎', 'potato': '🥔',
      'raddish': '🥕', 'soy beans': '🫘', 'spinach': '🥬', 'sweetcorn': '🌽',
      'sweetpotato': '🍠', 'tomato': '🍅', 'turnip': '🥕', 'watermelon': '🍉',
    };
    return emojiMap[className.toLowerCase()] ?? '🥗';
  }

  @override
  void dispose() {
    _modelService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'ANN Model (Offline)',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFFFFA726)), // Orange accent
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Model Status
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _modelLoaded ? const Color(0xFFFFA726) : const Color(0xFF2E2E2E),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _modelLoaded ? Icons.check_circle : Icons.pending,
                      color: _modelLoaded ? const Color(0xFFFFA726) : const Color(0xFF9E9E9E),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _modelLoaded ? 'ANN Ready (Offline)' : 'Chargement...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Image Display
              if (_selectedImage != null)
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(_imageBytes!, fit: BoxFit.contain),
                  ),
                )
              else
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.image_outlined, size: 64, color: Color(0xFF9E9E9E)),
                        SizedBox(height: 16),
                        Text('Sélectionnez une image', 
                            style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 16)),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Caméra'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E1E1E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF2E2E2E), width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text('Galerie'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: const Color(0xFF121212),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Classify Button
              ElevatedButton(
                onPressed: _selectedImage != null && _modelLoaded && !_isLoading
                    ? _classifyImage : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA726),
                  foregroundColor: const Color(0xFF121212),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: const Color(0xFF2E2E2E),
                  disabledForegroundColor: const Color(0xFF9E9E9E),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF121212)),
                        ),
                      )
                    : const Text('Classifier (ANN)', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 24),

              // Results
              if (_prediction != null && _prediction!['success'] == true) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFFFA726).withOpacity(0.2),
                        const Color(0xFF1E1E1E),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFA726), width: 1),
                  ),
                  child: Column(
                    children: [
                      Text(_getEmoji(_prediction!['label']), 
                          style: const TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        _prediction!['label'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '${(_prediction!['confidence'] * 100).toStringAsFixed(1)}% confiance',
                        style: const TextStyle(
                          color: Color(0xFFFFA726), fontSize: 18, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: _prediction!['confidence'],
                          minHeight: 8,
                          backgroundColor: const Color(0xFF2E2E2E),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_prediction!['top_predictions'] != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2E2E2E), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Top 3 Prédictions',
                            style: TextStyle(
                                color: Color(0xFFFFA726),
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        ...(_prediction!['top_predictions'] as List).map((pred) =>
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                children: [
                                  Text(_getEmoji(pred['class']),
                                      style: const TextStyle(fontSize: 24)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(pred['class'],
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500)),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pred['confidence'],
                                            minHeight: 4,
                                            backgroundColor: const Color(0xFF2E2E2E),
                                            valueColor: const AlwaysStoppedAnimation<Color>(
                                                Color(0xFFFFA726)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text('${(pred['confidence'] * 100).toStringAsFixed(1)}%',
                                      style: const TextStyle(
                                          color: Color(0xFF9E9E9E), fontSize: 14)),
                                ],
                              ),
                            ))
                        ,
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

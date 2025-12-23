import 'package:flutter/material.dart';
import '../services/stock_api_service.dart';
import 'dart:math';

class StockPredictionScreen extends StatefulWidget {
  const StockPredictionScreen({super.key});

  @override
  State<StockPredictionScreen> createState() => _StockPredictionScreenState();
}

class _StockPredictionScreenState extends State<StockPredictionScreen> {
  final StockApiService _apiService = StockApiService();
  final TextEditingController _controller = TextEditingController();
  
  bool _isLoading = false;
  double? _prediction;
  String? _error;
  List<double> _currentHistory = [];

  @override
  void initState() {
    super.initState();
    _generateSampleData();
  }

  void _generateSampleData() {
    final random = Random();
    double startPrice = 100 + random.nextDouble() * 200;
    List<double> data = [];
    for (int i = 0; i < 60; i++) {
      startPrice += (random.nextDouble() - 0.45) * 5; // Slight upward trend
      data.add(double.parse(startPrice.toStringAsFixed(2)));
    }
    _controller.text = data.join(', ');
    setState(() {
      _currentHistory = data;
      _prediction = null;
      _error = null;
    });
  }

  Future<void> _predict() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _prediction = null;
    });

    try {
      // Parse input
      final text = _controller.text;
      final parts = text.split(RegExp(r'[\s,]+')).where((s) => s.isNotEmpty).toList();
      
      if (parts.length != 60) {
        throw 'Veuillez entrer exactement 60 valeurs (reçu: ${parts.length})';
      }

      final history = parts.map((e) => double.parse(e)).toList();
      setState(() => _currentHistory = history);

      final result = await _apiService.predictStockPrice(history);

      if (result['success'] == true) {
        setState(() {
          _prediction = result['prediction'];
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error'] ?? 'Erreur lors de la prédiction';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Prédiction Boursière (Keras)'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInfoCard(),
            const SizedBox(height: 24),
            _buildInputSection(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF5CFBAC)))
            else if (_prediction != null)
              _buildResultCard()
            else if (_error != null)
              _buildErrorCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.blue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Modèle LSTM / RNN',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  'Fournissez les 60 derniers jours de prix pour prédire la valeur du lendemain.',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Données Historiques (60 valeurs)',
          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          maxLines: 6,
          style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
          decoration: InputDecoration(
            hintText: 'Ex: 150.2, 152.4, 149.8...',
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: const Color(0xFF2A2A2A),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _predict,
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('PRÉDIRE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5CFBAC),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _isLoading ? null : _generateSampleData,
          icon: const Icon(Icons.casino, color: Colors.white70),
          tooltip: 'Générer des données de test',
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xFF2A2A2A),
            padding: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Prix Prédit pour demain',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '${_prediction!.toStringAsFixed(2)} \$',
            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          const Text(
            'Basé sur les 60 dernières sessions enregistrées.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.5)),
      ),
      child: Text(
        _error!,
        style: const TextStyle(color: Colors.redAccent),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class StockApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  Future<Map<String, dynamic>> predictStockPrice(List<double> history) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/stock/predict'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'history': history}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error': errorData['error'] ?? 'Unknown error'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network Error: Check if backend is running'
      };
    }
  }
}

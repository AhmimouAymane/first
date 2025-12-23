import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class RagApiService {
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// Process multiple PDF files
  Future<Map<String, dynamic>> processPdfs(List<dynamic> files) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/rag/process'));
      
      for (var file in files) {
        // Handle both File (native) and XFile (web) if necessary
        // For web, use file.bytes, for native use file.path
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'files',
            file.bytes!,
            filename: file.name,
            contentType: MediaType('application', 'pdf'),
          ));
        }
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Unknown error'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Query the RAG system
  Future<Map<String, dynamic>> queryRag(String question) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/rag/query'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['error'] ?? 'Unknown error'
        };
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

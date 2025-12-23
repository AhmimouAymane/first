import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/rag_api_service.dart';

class RagChatScreen extends StatefulWidget {
  const RagChatScreen({super.key});

  @override
  State<RagChatScreen> createState() => _RagChatScreenState();
}

class _RagChatScreenState extends State<RagChatScreen> {
  final RagApiService _apiService = RagApiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  final List<Map<String, String>> _messages = [];
  bool _isProcessing = false;
  bool _isQuerying = false;
  bool _isDocsLoaded = false;
  List<String> _uploadedFiles = [];

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
        withData: true, // Required for Web
      );

      if (result != null) {
        setState(() {
          _isProcessing = true;
          _uploadedFiles = result.files.map((f) => f.name).toList();
        });

        final response = await _apiService.processPdfs(result.files);

        setState(() {
          _isProcessing = false;
          if (response['success'] == true) {
            _isDocsLoaded = true;
            _messages.add({
              'role': 'assistant',
              'content': '✅ ${response['message']}. Vous pouvez maintenant poser vos questions sur ces documents !'
            });
          } else {
            _messages.add({
              'role': 'assistant',
              'content': '❌ Erreur lors du traitement: ${response['error']}'
            });
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _messages.add({'role': 'assistant', 'content': '❌ Erreur: $e'});
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isDocsLoaded || _isQuerying) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isQuerying = true;
    });
    _scrollToBottom();

    try {
      final response = await _apiService.queryRag(text);
      setState(() {
        _isQuerying = false;
        if (response['success'] == true) {
          _messages.add({'role': 'assistant', 'content': response['answer']});
        } else {
          _messages.add({'role': 'assistant', 'content': '❌ Erreur: ${response['error']}'});
        }
      });
    } catch (e) {
      setState(() {
        _isQuerying = false;
        _messages.add({'role': 'assistant', 'content': '❌ Erreur réseau: $e'});
      });
    }
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('EMSI RAG Chatbot 🧠'),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () => setState(() {
              _messages.clear();
              _isDocsLoaded = false;
              _uploadedFiles.clear();
            }),
          ),
        ],
      ),
      body: Column(
        children: [
          if (!_isDocsLoaded) _buildUploadPlaceholder(),
          if (_isDocsLoaded) _buildFileList(),
          Expanded(child: _buildChatList()),
          if (_isQuerying) 
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(color: Color(0xFF5CFBAC), backgroundColor: Colors.transparent),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5CFBAC).withOpacity(0.3), width: 2, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          const Icon(Icons.picture_as_pdf, size: 64, color: Color(0xFF5CFBAC)),
          const SizedBox(height: 16),
          const Text(
            'Aucun document chargé',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez charger vos fichiers PDF pour commencer la discussion contextuelle.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _pickFiles,
            icon: _isProcessing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : const Icon(Icons.upload_file),
            label: Text(_isProcessing ? 'Traitement en cours...' : 'CHARGER DES PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5CFBAC),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF1E1E1E),
      child: Row(
        children: [
          const Icon(Icons.description, size: 16, color: Color(0xFF5CFBAC)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Documents: ${_uploadedFiles.join(", ")}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: _pickFiles,
            child: const Text('Ajouter', style: TextStyle(color: Color(0xFF5CFBAC), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return _buildMessageTile(msg['content']!, isUser);
      },
    );
  }

  Widget _buildMessageTile(String content, bool isUser) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFF5CFBAC) : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            if (!isUser) BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.black : Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: _isDocsLoaded && !_isQuerying,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: _isDocsLoaded ? 'Posez votre question...' : 'Chargez des documents d\'abord',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: const Color(0xFF2A2A2A),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          CircleAvatar(
            backgroundColor: _isDocsLoaded && !_isQuerying ? const Color(0xFF5CFBAC) : Colors.grey.shade800,
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.black, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}

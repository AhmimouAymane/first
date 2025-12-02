import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final void Function(String)? onResultReceived;

  const VoiceAssistantWidget({super.key, this.onResultReceived});

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget> {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isTestMode = false; // Flag pour mode test/simulation

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    try {
      // Request microphone permission
      final permissionStatus = await Permission.microphone.request();

      if (permissionStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission de microphone refusée'),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _speechEnabled = false);
        return;
      }

      _speechEnabled = await _speechToText.initialize(
        onError: (error) {
          print('Speech recognition error: $error');
          if (mounted) {
            final msg = error.errorMsg;
            final isTimeout = msg.contains('timeout');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $msg'),
                action: isTimeout
                    ? SnackBarAction(
                        label: 'Réessayer',
                        onPressed: () {
                          Future.delayed(
                            const Duration(milliseconds: 500),
                            _startListening,
                          );
                        },
                      )
                    : null,
              ),
            );
          }
          // If error is permanent, fall back to test mode
          try {
            if (error.permanent == true) {
              setState(() => _isTestMode = true);
            }
          } catch (_) {
            // ignore
          }
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
      );

      // Si pas de service speech disponible, mode test
      if (!_speechEnabled) {
        setState(() => _isTestMode = true);
        print('Speech service not available, using test mode');
      }

      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _speechEnabled = false;
        _isTestMode = true; // Activer mode test en cas d'erreur
      });
    }
  }

  /// Start listening for speech
  void _startListening() async {
    if (_isTestMode) {
      // Mode test: simulation
      _startTestMode();
      return;
    }

    if (!_speechEnabled) {
      // Not initialized or permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone non disponible')),
        );
      }
      return;
    }

    // Listen with explicit options to reduce timeouts and enable partial results
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 10),
      partialResults: true,
      localeId: 'fr_FR',
      cancelOnError: true,
    );

    setState(() {});
  }

  /// Simulate speech recognition for testing
  void _startTestMode() {
    setState(() {
      _lastWords = '';
    });

    // Simulation avec délai
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _lastWords = 'Ceci est une parole simulée pour tester';
        });
        widget.onResultReceived?.call(_lastWords);
      }
    });
  }

  /// Stop listening for speech
  void _stopListening() async {
    if (_isTestMode) return;
    await _speechToText.stop();
    setState(() {});
  }

  /// Callback when speech is recognized
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });
    // Log and call the callback if provided
    print('Reconnu (final=${result.finalResult}): $_lastWords');
    widget.onResultReceived?.call(_lastWords);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistant Vocal'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isTestMode)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Tooltip(
                message: 'Mode test (service non disponible)',
                child: Chip(
                  label: const Text('TEST', style: TextStyle(fontSize: 10)),
                  backgroundColor: Colors.orange[100],
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Status indicator
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                _speechToText.isListening ? '🎤 En écoute...' : '🎤 Prêt',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Recognized words display
            Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Paroles reconnues:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _speechToText.isListening
                        ? _lastWords.isEmpty
                              ? 'En attente de paroles...'
                              : _lastWords
                        : _speechEnabled || _isTestMode
                        ? _lastWords.isEmpty
                              ? 'Appuyez sur le microphone pour commencer'
                              : _lastWords
                        : 'Reconnaissance vocale non disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _speechToText.isListening
                          ? Colors.blue
                          : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // Confidence indicator (if listening)
            if (_speechToText.isListening)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '⏱️ Écoute en cours... (Parlez maintenant)',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _speechToText.isNotListening
            ? _startListening
            : _stopListening,
        backgroundColor: _speechToText.isListening ? Colors.red : Colors.blue,
        icon: Icon(
          _speechToText.isListening ? Icons.mic : Icons.mic_none,
          size: 28,
        ),
        label: Text(
          _speechToText.isListening ? 'Arrêter' : 'Écouter',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    super.dispose();
  }
}

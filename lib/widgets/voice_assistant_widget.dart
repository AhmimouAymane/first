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

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  bool _isTestMode = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Animation for mic pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  void _initSpeech() async {
    try {
      final permissionStatus = await Permission.microphone.request();

      if (permissionStatus.isDenied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Permission de microphone refusée'),
              backgroundColor: const Color(0xFFFF5252),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                backgroundColor: const Color(0xFFFF5252),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                action: isTimeout
                    ? SnackBarAction(
                        label: 'Réessayer',
                        textColor: const Color(0xFF5CFBAC),
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
          try {
            if (error.permanent == true) {
              setState(() => _isTestMode = true);
            }
          } catch (_) {}
        },
        onStatus: (status) {
          print('Speech recognition status: $status');
        },
      );

      if (!_speechEnabled) {
        setState(() => _isTestMode = true);
        print('Speech service not available, using test mode');
      }

      setState(() {});
    } catch (e) {
      print('Error initializing speech: $e');
      setState(() {
        _speechEnabled = false;
        _isTestMode = true;
      });
    }
  }

  void _startListening() async {
    if (_isTestMode) {
      _startTestMode();
      return;
    }

    if (!_speechEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Microphone non disponible'),
            backgroundColor: const Color(0xFFFF5252),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

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

  void _startTestMode() {
    setState(() {
      _lastWords = '';
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _lastWords = 'Ceci est une parole simulée pour tester';
        });
        widget.onResultReceived?.call(_lastWords);
      }
    });
  }

  void _stopListening() async {
    if (_isTestMode) return;
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      // Only show the last sentence (split by period, question mark, or exclamation)
      final sentences = result.recognizedWords.split(RegExp(r'[.!?]'));
      _lastWords = sentences.last.trim();
      if (_lastWords.isEmpty && sentences.length > 1) {
        _lastWords = sentences[sentences.length - 2].trim();
      }
    });
    print('Reconnu (final=${result.finalResult}): $_lastWords');
    widget.onResultReceived?.call(_lastWords);
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _speechToText.isListening;
    
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // Test mode badge
              if (_isTestMode)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.science,
                        color: Colors.orange,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'MODE TEST',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Animated microphone circle
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: isListening
                            ? [
                                const Color(0xFF5CFBAC).withOpacity(0.3),
                                const Color(0xFF5CFBAC).withOpacity(0.1),
                                Colors.transparent,
                              ]
                            : [
                                const Color(0xFF2E2E2E),
                                const Color(0xFF1E1E1E),
                              ],
                      ),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF5CFBAC).withOpacity(0.3),
                                blurRadius: 40 * _pulseAnimation.value,
                                spreadRadius: 10 * _pulseAnimation.value,
                              ),
                            ]
                          : [],
                    ),
                    child: Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isListening
                              ? const Color(0xFF5CFBAC)
                              : const Color(0xFF2E2E2E),
                          border: Border.all(
                            color: isListening
                                ? const Color(0xFF5CFBAC)
                                : const Color(0xFF3E3E3E),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          isListening ? Icons.mic : Icons.mic_none,
                          size: 60,
                          color: isListening
                              ? const Color(0xFF121212)
                              : const Color(0xFF5CFBAC),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Status text
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFF5CFBAC).withOpacity(0.1)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isListening
                        ? const Color(0xFF5CFBAC).withOpacity(0.3)
                        : const Color(0xFF2E2E2E),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? const Color(0xFF5CFBAC)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      isListening ? 'En écoute...' : 'Prêt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isListening
                            ? const Color(0xFF5CFBAC)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Recognized words display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5CFBAC).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Color(0xFF5CFBAC),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Paroles reconnues',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9E9E9E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isListening
                          ? _lastWords.isEmpty
                              ? 'En attente de paroles...'
                              : _lastWords
                          : _speechEnabled || _isTestMode
                          ? _lastWords.isEmpty
                              ? 'Appuyez sur le bouton pour commencer'
                              : _lastWords
                          : 'Reconnaissance vocale non disponible',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isListening
                            ? const Color(0xFF5CFBAC)
                            : Colors.white,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Listening indicator
              if (isListening)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5CFBAC).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF5CFBAC).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        color: Color(0xFF5CFBAC),
                        size: 18,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Écoute en cours... Parlez maintenant',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF5CFBAC),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),

              // Action button
              Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: isListening
                      ? const Color(0xFFFF5252)
                      : const Color(0xFF5CFBAC),
                ),
                child: ElevatedButton(
                  onPressed: isListening ? _stopListening : _startListening,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isListening ? Icons.stop : Icons.mic,
                        size: 24,
                        color: const Color(0xFF121212),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isListening ? 'Arrêter l\'écoute' : 'Commencer l\'écoute',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF121212),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    super.dispose();
  }
}
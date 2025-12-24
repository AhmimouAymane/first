import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:js' as js;
import '../services/gemini_service.dart';

class VoiceAssistantWidget extends StatefulWidget {
  final void Function(String)? onResultReceived;

  const VoiceAssistantWidget({super.key, this.onResultReceived});

  @override
  State<VoiceAssistantWidget> createState() => _VoiceAssistantWidgetState();
}

class _VoiceAssistantWidgetState extends State<VoiceAssistantWidget>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final GeminiService _geminiService = GeminiService();
  final ScrollController _scrollController = ScrollController();
  
  bool _speechEnabled = false;
  String _userInput = '';
  String _aiResponse = '';
  bool _isProcessing = false;
  bool _isTestMode = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    
    // Animation for mic pulse effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _speechToText.stop();
    _pulseController.dispose();
    _flutterTts.stop();
    try {
      js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
    } catch (_) {}
    _scrollController.dispose();
    super.dispose();
  }

  void _initTts() async {
    try {
      print('🔊 Initializing TTS...');
      
      // On Web, we need to wait for voices to be loaded
      if (identical(0, 0.0)) { // Web check
        await Future.delayed(const Duration(milliseconds: 500));
      }

      final voices = await _flutterTts.getVoices;
      print('🔊 TTS Voices available: ${voices.length}');
      
      // Look for a French voice specifically
      dynamic bestVoice;
      for (var voice in voices) {
        final name = voice.toString().toLowerCase();
        if (name.contains('fr') || name.contains('french')) {
          bestVoice = voice;
          if (name.contains('google') || name.contains('premium')) break;
        }
      }

      if (bestVoice != null) {
        print('🔊 Selected Voice: $bestVoice');
        if (bestVoice is Map) {
          await _flutterTts.setVoice({"name": bestVoice["name"], "locale": bestVoice["locale"]});
        }
      } else {
        await _flutterTts.setLanguage("fr-FR");
      }

      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print('🔊 TTS Init Error: $e');
    }
  }

  String? _extractImageUrl(String text) {
    final regExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final match = regExp.firstMatch(text);
    return match?.group(1);
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    
    // Stop any ongoing speech first (Universal stop)
    try {
      await _flutterTts.stop();
      js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
    } catch (_) {}

    // Clean text (remove image markdown)
    String cleanText = text;
    if (text.contains('![')) {
      cleanText = text.split('![').first.trim();
    }
    if (cleanText.isEmpty) return;

    try {
      print('🔊 Plugin speak: ${cleanText.substring(0, cleanText.length > 20 ? 20 : cleanText.length)}...');
      await _flutterTts.setLanguage("fr-FR");
      await _flutterTts.setVolume(1.0);
      await _flutterTts.speak(cleanText);
    } catch (e) {
      print('🔊 Plugin failed ($e). Using Web Native Speech fallback...');
      try {
        // Direct JavaScript SpeechSynthesis API call bypassing the plugin
        js.context.callMethod('eval', [
          "var msg = new SpeechSynthesisUtterance('${cleanText.replaceAll("'", "\\'").replaceAll("\n", " ").replaceAll("\r", "")}'); " "msg.lang = 'fr-FR'; " "window.speechSynthesis.speak(msg);"
        ]);
      } catch (jsError) {
        print('🚨 Critical Speak Error: $jsError');
      }
    }
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erreur: $msg'),
                backgroundColor: const Color(0xFFFF5252),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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

    setState(() {
      _userInput = '';
      _aiResponse = '';
    });
    
    // Web audio unlock
    _speak('');

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      localeId: 'fr_FR',
      cancelOnError: true,
    );

    setState(() {});
  }

  void _startTestMode() async {
    setState(() {
      _userInput = '';
      _aiResponse = '';
    });

    Future.delayed(const Duration(milliseconds: 500), () async {
      if (mounted) {
        final testQuestion = 'Qu\'est-ce qu\'une pomme?';
        setState(() {
          _userInput = testQuestion;
        });
        await _processWithGemini(testQuestion);
      }
    });
  }

  void _stopListening() async {
    if (_isTestMode) return;
    await _speechToText.stop();
    setState(() {});
  }

  void _onSpeechResult(SpeechRecognitionResult result) async {
    setState(() {
      _userInput = result.recognizedWords;
    });
    
    // If final result, process with Gemini
    if (result.finalResult) {
      await _processWithGemini(_userInput);
    }
    
    widget.onResultReceived?.call(_userInput);
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

  Future<void> _processWithGemini(String input) async {
    if (input.trim().isEmpty) return;

    setState(() {
      _isProcessing = true;
      _userInput = input; // Keep for the current turn UI feedback if needed
      _aiResponse = 'Réflexion en cours...';
    });
    
    _scrollToBottom();

    try {
      final response = await _geminiService.sendMessage(input);
      
      setState(() {
        _aiResponse = response;
        _isProcessing = false;
      });

      _scrollToBottom();

      // Speak the response
      await _speak(response);
      
    } catch (e) {
      setState(() {
        _aiResponse = 'Erreur: ${e.toString()}';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = _speechToText.isListening;
    
    return Container(
      color: const Color(0xFF121212),
      child: Center(
        child: SingleChildScrollView(
          controller: _scrollController,
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
              // Assistant Header with Reset
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Assistant Omnium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.volume_up, color: Color(0xFF5CFBAC)),
                        tooltip: 'Initialiser l\'Audio',
                        onPressed: () => _speak('Audio activée'),
                      ),
                      IconButton(
                        icon: const Icon(Icons.stop_circle_outlined, color: Color(0xFFFF5252)),
                        tooltip: 'Arrêter la Voix',
                        onPressed: () {
                          _flutterTts.stop();
                          js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Color(0xFF5CFBAC)),
                        tooltip: 'Réinitialiser',
                        onPressed: () {
                          _geminiService.clearHistory();
                          _flutterTts.stop();
                          js.context.callMethod('eval', ["window.speechSynthesis.cancel();"]);
                          setState(() {
                            _aiResponse = '';
                            _userInput = '';
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

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
                        colors: isListening || _isProcessing
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
                      boxShadow: isListening || _isProcessing
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
                          color: isListening || _isProcessing
                              ? const Color(0xFF5CFBAC)
                              : const Color(0xFF2E2E2E),
                          border: Border.all(
                            color: isListening || _isProcessing
                                ? const Color(0xFF5CFBAC)
                                : const Color(0xFF3E3E3E),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          _isProcessing 
                              ? Icons.psychology 
                              : (isListening ? Icons.mic : Icons.mic_none),
                          size: 60,
                          color: isListening || _isProcessing
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
                  color: isListening || _isProcessing
                      ? const Color(0xFF5CFBAC).withOpacity(0.1)
                      : const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isListening || _isProcessing
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
                        color: isListening || _isProcessing
                            ? const Color(0xFF5CFBAC)
                            : const Color(0xFF9E9E9E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _isProcessing 
                          ? 'Traitement...' 
                          : (isListening ? 'En écoute...' : 'Prêt'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isListening || _isProcessing
                            ? const Color(0xFF5CFBAC)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Chat History Display
              if (_geminiService.history.isNotEmpty)
                ..._geminiService.history.map((chat) {
                  final isUser = chat['role'] == 'user';
                  final text = chat['text'] as String;
                  
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF1E1E1E) : null,
                      gradient: isUser ? null : LinearGradient(
                        colors: [
                          const Color(0xFF5CFBAC).withOpacity(0.1),
                          const Color(0xFF1E1E1E),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isUser ? const Color(0xFF5CFBAC).withOpacity(0.3) : const Color(0xFF5CFBAC),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isUser ? Icons.person : Icons.auto_awesome,
                              color: const Color(0xFF5CFBAC),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isUser ? 'Vous' : 'Gemini',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF5CFBAC),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (!isUser)
                              IconButton(
                                icon: const Icon(Icons.volume_up, color: Color(0xFF5CFBAC), size: 18),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _speak(text),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          text.contains('![') ? text.split('![').first.trim() : text,
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white,
                            height: 1.4,
                          ),
                        ),
                        if (text.contains('!['))
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _extractImageUrl(text) ?? '',
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: CircularProgressIndicator(color: Color(0xFF5CFBAC)),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.broken_image, color: Colors.orange),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }),

              // Processing hint (if Gemini is thinking)
              if (_isProcessing && (_geminiService.history.isEmpty || _geminiService.history.last['role'] != 'model'))
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF5CFBAC).withOpacity(0.1)),
                  ),
                  child: const Row(
                    children: [
                      CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF5CFBAC), value: null),
                      SizedBox(width: 16),
                      Text('Gemini réfléchit...', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

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
                  onPressed: _isProcessing 
                      ? null 
                      : (isListening ? _stopListening : _startListening),
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
                        isListening ? 'Arrêter l\'écoute' : 'Poser une question',
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

}
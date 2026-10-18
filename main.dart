import 'package:flutter/material.dart';
import 'package:torch_light/torch_light.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const FlashlightVoiceApp());
}

class FlashlightVoiceApp extends StatelessWidget {
  const FlashlightVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voice Flashlight',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Colors.amber,
          secondary: Colors.amberAccent,
        ),
      ),
      home: const FlashlightScreen(),
    );
  }
}

class FlashlightScreen extends StatefulWidget {
  const FlashlightScreen({super.key});

  @override
  State<FlashlightScreen> createState() => _FlashlightScreenState();
}

class _FlashlightScreenState extends State<FlashlightScreen> {
  // Flashlight state
  bool _isTorchOn = false;

  // Speech to text state
  late stt.SpeechToText _speech;
  bool _speechEnabled = false;
  bool _isListening = false;
  String _lastRecognizedWords = '';

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onStatus: (status) {
          if (status == 'notListening' || status == 'done') {
            setState(() => _isListening = false);
          }
        },
        onError: (errorNotification) {
          setState(() => _isListening = false);
          _showMessage('Voice Error: ${errorNotification.errorMsg}');
        },
      );
    } catch (e) {
      _showMessage('Failed to initialize speech recognition.');
    }
    setState(() {});
  }

  /// Turn Flashlight ON
  Future<void> _turnOnTorch() async {
    try {
      await TorchLight.enableTorch();
      setState(() => _isTorchOn = true);
    } catch (e) {
      _showMessage('Error: Could not enable flashlight ($e)');
    }
  }

  /// Turn Flashlight OFF
  Future<void> _turnOffTorch() async {
    try {
      await TorchLight.disableTorch();
      setState(() => _isTorchOn = false);
    } catch (e) {
      _showMessage('Error: Could not disable flashlight ($e)');
    }
  }

  /// Toggle button handler
  Future<void> _toggleTorch() async {
    if (_isTorchOn) {
      await _turnOffTorch();
    } else {
      await _turnOnTorch();
    }
  }

  /// Start listening for voice commands
  void _startListening() async {
    if (!_speechEnabled) {
      _showMessage('Speech recognition is not available.');
      return;
    }

    setState(() {
      _lastRecognizedWords = '';
      _isListening = true;
    });

    await _speech.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      localeId: 'en_US',
      cancelOnError: true,
      partialResults: true,
    );
  }

  /// Stop listening manually
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
  }

  /// Voice result parser
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastRecognizedWords = result.recognizedWords;
    });

    final spokenText = result.recognizedWords.toLowerCase().trim();

    // Trigger phrases for ON
    if (spokenText.contains('turn on the flashlight') ||
        spokenText.contains('turn on flashlight') ||
        spokenText.contains('turn on')) {
      if (!_isTorchOn) {
        _turnOnTorch();
      }
    }
    // Trigger phrases for OFF
    else if (spokenText.contains('turn off the flashlight') ||
        spokenText.contains('turn off flashlight') ||
        spokenText.contains('turn off')) {
      if (_isTorchOn) {
        _turnOffTorch();
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
    );
  }

  @override
  void dispose() {
    if (_isTorchOn) {
      TorchLight.disableTorch();
    }
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Flashlight'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Status Indicator Text
            Text(
              _isTorchOn ? 'FLASHLIGHT IS ON' : 'FLASHLIGHT IS OFF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                color: _isTorchOn ? Colors.amber : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),

            // Single Large Toggle Button
            Center(
              child: GestureDetector(
                onTap: _toggleTorch,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 180,
                  width: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _isTorchOn ? Colors.amber : const Color(0xFF242424),
                    boxShadow: _isTorchOn
                        ? [
                            BoxShadow(
                              color: Colors.amber.withOpacity(0.5),
                              blurRadius: 50,
                              spreadRadius: 15,
                            )
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: 2,
                            )
                          ],
                  ),
                  child: Icon(
                    Icons.power_settings_new_rounded,
                    size: 80,
                    color: _isTorchOn ? Colors.black87 : Colors.white54,
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Recognized speech feedback
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    _isListening ? 'Listening...' : 'Tap mic and speak',
                    style: TextStyle(
                      fontSize: 16,
                      color: _isListening ? Colors.amberAccent : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _lastRecognizedWords.isEmpty
                        ? 'Try saying:\n"Turn on the flashlight" or "Turn off the flashlight"'
                        : '"$_lastRecognizedWords"',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontStyle: FontStyle.italic,
                      color: _lastRecognizedWords.isEmpty
                          ? Colors.grey[600]
                          : Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Microphone Button
            FloatingActionButton(
              onPressed: _isListening ? _stopListening : _startListening,
              backgroundColor: _isListening ? Colors.redAccent : Colors.amber,
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

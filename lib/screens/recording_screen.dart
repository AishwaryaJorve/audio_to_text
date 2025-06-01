import 'package:flutter/material.dart';
import '../constants/icons/app_icons.dart';
import '../services/transcription_service.dart';
import '../services/audio_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:permission_handler/permission_handler.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final TranscriptionService _transcriptionService = TranscriptionService();
  final AudioService _audioService = AudioService();

  late TextEditingController _transcriptionController;

  String _transcribedText = '';
  String _currentAudioPath = '';
  int _audioDuration = 0;
  bool _isRecording = false;
  late stt.SpeechToText _speech;
  bool _isSpeechAvailable = false;

  @override
  void initState() {
    super.initState();
    _transcriptionController = TextEditingController();
    _initializeAudioService();
    _initializeSpeechToText();
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    super.dispose();
  }

  Future<void> _initializeAudioService() async {
    try {
      await _audioService.initialize();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize audio service: $e')),
      );
    }
  }

  Future<void> _initializeSpeechToText() async {
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      _speech = stt.SpeechToText();
      _isSpeechAvailable = await _speech.initialize(
        onStatus: (val) => print('Speech status: $val'),
        onError: (val) => print('Speech error: $val'),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission not granted')),
      );
    }
  }

  Future<void> _toggleRecording() async {
    if (!_isRecording) {
      try {
        final audioPath = await _audioService.startRecording((text) {
          setState(() {
            _transcribedText += ' $text';
            _transcriptionController.text = _transcribedText;
          });
        });

        if (_isSpeechAvailable) {
          _speech.listen(
            onResult: (result) {
              setState(() {
                _transcribedText += ' ${result.recognizedWords}';
                _transcriptionController.text = _transcribedText;
              });
            },
          );
        }

        setState(() {
          _isRecording = true;
          _currentAudioPath = audioPath;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    } else {
      try {
        await _audioService.stopRecording();
        if (_isSpeechAvailable && _speech.isListening) {
          await _speech.stop();
        }
        setState(() {
          _isRecording = false;
          _audioDuration = DateTime.now().millisecondsSinceEpoch;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to stop recording: $e')),
        );
      }
    }
  }

  Future<void> _saveTranscription() async {
    try {
      await _transcriptionService.saveTranscription(
        text: _transcribedText,
        audioPath: _currentAudioPath,
        duration: _audioDuration,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcription saved successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save transcription: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildUserInfoSection(),
            _buildRecordingVisualization(),
            _buildTranscriptionArea(),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptionArea() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Live Transcription:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: TextField(
                controller: _transcriptionController,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Transcription will appear here...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _transcribedText = value;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          FloatingActionButton(
            onPressed: _toggleRecording,
            child: Icon(_isRecording ? AppIcons.stop : AppIcons.mic),
          ),
          if (_transcribedText.isNotEmpty)
            FloatingActionButton(
              onPressed: _saveTranscription,
              child: const Icon(Icons.save),
            ),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateTime.now().toString().split('.')[0],
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _isRecording ? 'Recording in progress...' : 'Ready to record',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingVisualization() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          5,
          (index) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? Colors.red : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

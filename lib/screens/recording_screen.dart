import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/icons/app_icons.dart';
import '../services/transcription_service.dart';
import '../services/audio_service.dart';

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

  @override
  void initState() {
    super.initState();
    _transcriptionController = TextEditingController();
    _initializeServices();
  }

  @override
  void dispose() {
    _transcriptionController.dispose();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    try {
      // Request microphone permission
      var micStatus = await Permission.microphone.request();
      
      if (micStatus.isGranted) {
        // Initialize audio service
        await _audioService.initialize();
      } else {
        _showPermissionDeniedSnackBar();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to initialize audio service: $e');
    }
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_isRecording) {
        // Start recording
        setState(() {
          _transcribedText = '';
          _transcriptionController.clear();
          _isRecording = true;
        });

        // Start audio recording and speech recognition
        final audioPath = await _audioService.startRecording((text) {
          setState(() {
            // Append recognized text in real-time
            _transcribedText = text;
            _transcriptionController.text = _transcribedText.trim();
            
            // Move cursor to the end
            _transcriptionController.selection = TextSelection.fromPosition(
              TextPosition(offset: _transcriptionController.text.length),
            );
          });
        });

        // Update audio path and duration
        setState(() {
          _currentAudioPath = audioPath;
          _audioDuration = DateTime.now().millisecondsSinceEpoch;
        });
      } else {
        // Stop recording
        await _audioService.stopRecording();

        // Update state
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      // Handle any errors during recording
      _handleRecordingError(e);
    }
  }

  void _handleRecordingError(dynamic e) {
    setState(() {
      _isRecording = false;
    });
    _showErrorSnackBar('Recording error: $e');
  }

  void _showPermissionDeniedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone permission denied')),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
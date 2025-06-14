import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class AudioService {
  final Record _audioRecorder = Record();
  bool _isInitialized = false;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  Future<void> initialize() async {
    try {
      if (!_isInitialized) {
        // Initialize speech to text
        _isInitialized = await _speechToText.initialize(
          onStatus: (status) => print('Speech Recognition Status: $status'),
          onError: (error) => print('Speech Recognition Error: $error'),
        );
      }
    } catch (e) {
      print('Initialization Error: $e');
      rethrow;
    }
  }

  Future<String> startRecording(Function(String) onResult) async {
    if (!_isInitialized) {
      throw Exception('AudioService not initialized');
    }

    try {
      // Check microphone permission
      if (await _audioRecorder.hasPermission()) {
        // Get recording directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // Start audio recording with improved audio quality
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 296000, // Increased bitrate for better audio quality
          samplingRate: 60000, // Higher sampling rate
        );

        // Start continuous speech recognition with enhanced sensitivity
        await _speechToText.listen(
          onResult: (result) {
            // More aggressive recognition
            if (result.recognizedWords.isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          localeId: 'en_US', // Specify locale for better recognition
        );

        _isRecording = true;
        _currentRecordingPath = filePath;
        return filePath;
      } else {
        throw Exception('Microphone permission not granted');
      }
    } catch (e) {
      print('Recording Start Error: $e');
      _isRecording = false;
      rethrow;
    }
  }

  Future<void> stopRecording() async {
    try {
      // Stop audio recording
      await _audioRecorder.stop();
      
      // Stop speech recognition
      await stopSpeechRecognition();

      _isRecording = false;
    } catch (e) {
      print('Stop Recording Error: $e');
      _isRecording = false;
      rethrow;
    }
  }

  Future<void> stopSpeechRecognition() async {
    try {
      if (_speechToText.isListening) {
        await _speechToText.stop();
      }
    } catch (e) {
      print('Stop Speech Recognition Error: $e');
    }
  }

  void dispose() {
    try {
      // Stop any ongoing recording
      _audioRecorder.stop();
      
      // Cancel speech recognition
      _speechToText.cancel();
    } catch (e) {
      print('Error during AudioService disposal: $e');
    }
  }

  // Getter for recording state
  bool get isRecording => _isRecording;

  // Getter for current recording path
  String? get currentRecordingPath => _currentRecordingPath;

  Future<void> pauseRecording() async {
    try {
      if (_isRecording) {
        // Pause audio recording
        await _audioRecorder.pause();
        
        // Pause speech recognition (no direct pause, so we cancel)
        await _speechToText.cancel();
      }
    } catch (e) {
      print('Pause Recording Error: $e');
      rethrow;
    }
  }

  Future<void> resumeRecording() async {
    try {
      if (_isRecording) {
        // Resume audio recording
        await _audioRecorder.resume();
        
        // Resume speech recognition by starting to listen again
        await _speechToText.listen(
          onResult: (result) {
            // You may want to handle the result callback here as well
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          localeId: 'en_US',
        );
      }
    } catch (e) {
      print('Resume Recording Error: $e');
      rethrow;
    }
  }
}

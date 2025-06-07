import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class AudioService {
  final Record _audioRecorder = Record();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  Future<void> initialize() async {
    try {
      // Initialize speech to text
      await _speechToText.initialize(
        onStatus: (status) => print('Speech Recognition Status: $status'),
        onError: (error) => print('Speech Recognition Error: $error'),
      );
    } catch (e) {
      print('Initialization Error: $e');
      rethrow;
    }
  }

  Future<String> startRecording(Function(String) onResult) async {
    try {
      // Check microphone permission
      if (await _audioRecorder.hasPermission()) {
        // Get recording directory
        final directory = await getApplicationDocumentsDirectory();
        final filePath = '${directory.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // Start audio recording
        await _audioRecorder.start(
          path: filePath,
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          samplingRate: 44100,
        );

        // Start continuous speech recognition
        await _speechToText.listen(
          onResult: (result) {
            if (result.finalResult || result.recognizedWords.isNotEmpty) {
              onResult(result.recognizedWords);
            }
          },
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
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
}

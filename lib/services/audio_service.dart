import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AudioService {
  final Record _audioRecorder = Record();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (!_isInitialized) {
      _isInitialized = await _speechToText.initialize();
    }
  }

  Future<String> startRecording(Function(String) onResult) async {
    if (await _audioRecorder.hasPermission()) {
      // Get the application documents directory
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      
      // Start audio recording
      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        samplingRate: 44100,
      );

      // Start speech recognition using the correct method name 'listen'
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            onResult(result.recognizedWords);
          }
        },
        listenMode: stt.ListenMode.dictation,
      );

      return filePath;
    }
    throw Exception('Microphone permission not granted');
  }

  Future<void> stopRecording() async {
    await _audioRecorder.stop();
    await _speechToText.stop();
  }

  Future<bool> deleteRecording(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting recording: $e');
      return false;
    }
  }

  Future<bool> get isRecording => _audioRecorder.isRecording();
}
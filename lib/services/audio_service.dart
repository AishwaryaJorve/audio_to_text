import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;

class AudioService {
  final Record _audioRecorder = Record();
  bool _isInitialized = false;
  stt.SpeechToText _speechToText = stt.SpeechToText();
  
  bool _isRecording = false;
  String? _currentRecordingPath;

  Future<void> initialize() async {
    try {
      // Request microphone and storage permissions
      final micPermission = await Permission.microphone.request();
      final storagePermission = await Permission.storage.request();

      if (!micPermission.isGranted || !storagePermission.isGranted) {
        throw Exception('Microphone or Storage permission not granted');
      }

      if (!_isInitialized) {
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
      // Get dedicated recordings directory
      final recordingsDirectory = await _getRecordingsDirectory();
      
      // Generate unique filename with more entropy
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueId = DateTime.now().microsecondsSinceEpoch.toString();
      final fileName = 'recording_${timestamp}_$uniqueId.m4a';
      final filePath = '${recordingsDirectory.path}/$fileName';

      // Ensure directory exists
      await recordingsDirectory.create(recursive: true);

      // Start audio recording with enhanced configuration
      await _audioRecorder.start(
        path: filePath,
        encoder: AudioEncoder.aacLc, // High-quality AAC encoding
        bitRate: 256000, // Increased bit rate for better quality
        samplingRate: 44100, // Standard high-quality sampling rate
      );

      // Start speech recognition
      await _speechToText.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            onResult(result.recognizedWords);
          }
        },
        listenMode: stt.ListenMode.dictation,
        partialResults: true,
        cancelOnError: true,
        localeId: 'en_US',
      );

      _isRecording = true;
      _currentRecordingPath = filePath;

      // Log recording details
      print('🎙️ Recording Started');
      print('📁 Recording Path: $filePath');

      return filePath;
    } catch (e) {
      print('🚨 Recording Start Error: $e');
      _isRecording = false;
      rethrow;
    }
  }

  Future<String?> stopRecording() async {
    try {
      final recordedFilePath = await _audioRecorder.stop();
      
      if (recordedFilePath != null) {
        final recordedFile = File(recordedFilePath);
        
        // Validate file
        if (await recordedFile.exists()) {
          final fileSize = await recordedFile.length();
          print('🎵 Recorded Audio File Details:');
          print('📍 Path: $recordedFilePath');
          print('📦 File Size: $fileSize bytes');
          
          // Ensure minimum file size to prevent empty recordings
          if (fileSize > 1024) { // At least 1KB
            await stopSpeechRecognition();
            _isRecording = false;
            return recordedFilePath;
          } else {
            print('❌ Recording too small, deleting file');
            await recordedFile.delete();
          }
        }
      }
      
      await stopSpeechRecognition();
      _isRecording = false;
      return null;
    } catch (e) {
      print('🚨 Stop Recording Error: $e');
      _isRecording = false;
      rethrow;
    }
  }

  // Enhanced method to get recordings directory
  Future<Directory> _getRecordingsDirectory() async {
    try {
      Directory? directory;

      // Platform-specific storage selection with comprehensive logging
      if (Platform.isIOS) {
        // For iOS, use Documents Directory
        directory = await getApplicationDocumentsDirectory();
      } else if (Platform.isAndroid) {
        // For Android, use external storage
        directory = await getExternalStorageDirectory();
      }

      // Fallback to temporary directory if platform-specific fails
      directory ??= await getTemporaryDirectory();

      // Create a dedicated 'Recordings' subdirectory
      final recordingsDir = Directory('${directory.path}/AudioToTextRecordings');
      
      // Ensure directory exists and is accessible
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
      }

      // Log directory details
      print('🗂️ Recordings Directory:');
      print('📍 Path: ${recordingsDir.path}');
      print('✅ Directory Exists: ${await recordingsDir.exists()}');

      return recordingsDir;
    } catch (e) {
      print('🚨 Error getting recordings directory: $e');
      // Absolute fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      return tempDir;
    }
  }

  // New method to retrieve a specific recording
  Future<File?> getRecordingFile(String fileName) async {
    try {
      final recordingsDirectory = await _getRecordingsDirectory();
      final filePath = '${recordingsDirectory.path}/$fileName';
      
      final file = File(filePath);
      return await file.exists() ? file : null;
    } catch (e) {
      print('🚨 Error retrieving recording: $e');
      return null;
    }
  }

  // Method to list all recordings
  Future<List<File>> listRecordings() async {
    try {
      final recordingsDirectory = await _getRecordingsDirectory();
      
      // List all .m4a files in the recordings directory
      final recordings = recordingsDirectory
        .listSync()
        .where((file) => 
          file is File && 
          path.extension(file.path).toLowerCase() == '.m4a'
        )
        .cast<File>()
        .toList();

      print('🎵 Found ${recordings.length} recordings');
      return recordings;
    } catch (e) {
      print('🚨 Error listing recordings: $e');
      return [];
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

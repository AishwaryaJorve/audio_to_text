import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/transcription_model.dart';
import 'package:path/path.dart' as path;
import 'dart:math';

class TranscriptionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveTranscription({
    required String text,
    required String audioPath,
    required int duration,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Validate and prepare audio file
      final validatedAudioPath = await _validateAndPrepareAudioFile(audioPath);

      // Create a unique identifier for the transcription
      final transcriptionId = _generateUniqueId();

      // Prepare transcription model
      final transcription = TranscriptionModel(
        id: transcriptionId,
        userId: user.uid,
        text: text,
        createdAt: DateTime.now(),
        audioPath: validatedAudioPath,
        duration: duration,
      );

      // Save to Firestore with retry mechanism
      await _retryOperation(() async {
        await _firestore
            .collection('transcriptions')
            .doc(transcriptionId)
            .set(transcription.toMap());
      });

      // Log successful save
      print('🎉 Transcription Saved Successfully:');
      print('🆔 Transcription ID: $transcriptionId');
      print('🎵 Audio Path: $validatedAudioPath');
      print('📝 Transcription Text: $text');
    } on FirebaseException catch (e) {
      print('🚨 Firestore Error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('🚨 Unexpected error saving transcription: $e');
      rethrow;
    }
  }

  // Generate a unique, secure identifier
  String _generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomString = _generateRandomString(8);
    return 'transcription_${timestamp}_$randomString';
  }

  // Generate a random string for additional uniqueness
  String _generateRandomString(int length) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    return List.generate(length, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Enhanced audio file validation and preparation
  Future<String> _validateAndPrepareAudioFile(String originalPath) async {
    try {
      print('🔍 Starting audio file validation');
      print('🔹 Original path: $originalPath');

      // Comprehensive file existence check with multiple strategies
      final file = await _findExistingFile(originalPath);
      
      if (file == null) {
        print('❌ File not found through comprehensive search');
        
        // Log all possible search paths for debugging
        print('🌐 Possible Search Paths:');
        final possiblePaths = [
          originalPath,
          '/var/mobile/Containers/Data/Application/*/Documents/${path.basename(originalPath)}',
          '/var/mobile/Containers/Data/Application/*/Documents/AudioToTextRecordings/${path.basename(originalPath)}',
          '/var/mobile/Containers/Data/Application/*/Library/Caches/${path.basename(originalPath)}',
          '/var/mobile/Containers/Data/Application/*/Library/Caches/AudioToTextRecordings/${path.basename(originalPath)}'
        ];
        
        possiblePaths.forEach(print);
        
        throw FileSystemException('Audio file cannot be located', originalPath);
      }

      // Validate file size with detailed logging
      final fileSize = await file.length();
      print('📦 File Size: $fileSize bytes');
      
      if (fileSize == 0) {
        print('❌ Audio file is empty');
        throw FileSystemException('Audio file is empty', file.path);
      }

      // Copy to a secure, consistent location with enhanced logging
      final secureFilePath = await _copyToSecureLocation(file);
      
      print('✅ File validation successful');
      print('🔒 Secure file path: $secureFilePath');
      
      return secureFilePath;
    } catch (e) {
      print('🚨 Audio file validation error: $e');
      
      // Advanced recovery attempt with detailed logging
      try {
        print('🔄 Attempting advanced file recovery');
        final recoveredPath = await _advancedFileRecovery(originalPath);
        
        if (recoveredPath != null) {
          print('🎉 File recovered through advanced method');
          print('📍 Recovered Path: $recoveredPath');
          return recoveredPath;
        }
        
        print('❌ Advanced recovery failed');
      } catch (recoveryError) {
        print('🚨 Advanced recovery error: $recoveryError');
      }

      throw FileSystemException('Cannot validate audio file', originalPath);
    }
  }

  // Advanced file finding method
  Future<File?> _findExistingFile(String originalPath) async {
    try {
      print('🔍 Comprehensive File Search Started');
      print('🔹 Original Path: $originalPath');

      // Direct file check with comprehensive logging
      final directFile = File(originalPath);
      if (await directFile.exists()) {
        print('✅ File found directly: $originalPath');
        return directFile;
      }

      // Extract filename and potential variations
      final fileName = path.basename(originalPath);
      final fileNameWithoutExtension = path.basenameWithoutExtension(originalPath);

      // Enhanced logging for search strategy
      print('🔍 Searching for file: $fileName');
      print('🔍 Searching for filename without extension: $fileNameWithoutExtension');

      // Possible search directories with enhanced logging
      final searchDirectories = [
        await getApplicationDocumentsDirectory(),
        await getTemporaryDirectory(),
      ];

      // iOS-specific comprehensive search
      if (Platform.isIOS) {
        final appContainerPath = Directory('/var/mobile/Containers/Data/Application');
        if (await appContainerPath.exists()) {
          final containerDirs = await appContainerPath.list().toList();
          for (var containerDir in containerDirs) {
            if (containerDir is Directory) {
              searchDirectories.addAll([
                Directory('${containerDir.path}/Documents'),
                Directory('${containerDir.path}/Documents/AudioToTextRecordings'),
                Directory('${containerDir.path}/Library/Caches'),
                Directory('${containerDir.path}/Library/Caches/AudioToTextRecordings'),
              ]);
            }
          }
        }
      }

      // Log search directories
      print('🌐 Search Directories:');
      for (var dir in searchDirectories) {
        print('   - ${dir.path}');
      }

      // Comprehensive recursive search with detailed logging
      for (var directory in searchDirectories) {
        try {
          print('🔎 Searching in directory: ${directory.path}');
          
          final searchResults = await directory.list(recursive: true)
            .where((event) => 
              event is File && 
              (path.basename(event.path) == fileName || 
               path.basenameWithoutExtension(event.path) == fileNameWithoutExtension)
            )
            .toList();

          if (searchResults.isNotEmpty) {
            final recoveredFile = searchResults.first as File;
            print('🎉 File found in search: ${recoveredFile.path}');
            
            // Additional file validation
            final fileSize = await recoveredFile.length();
            print('📦 Recovered File Size: $fileSize bytes');
            
            return recoveredFile;
          }
        } catch (e) {
          print('❌ Search in directory ${directory.path} failed: $e');
        }
      }

      print('❌ No file found after comprehensive search');
      return null;
    } catch (e) {
      print('🚨 Comprehensive file search error: $e');
      return null;
    }
  }

  // Advanced file recovery method
  Future<String?> _advancedFileRecovery(String originalPath) async {
    try {
      // Extract key identifiers
      final fileName = path.basename(originalPath);
      final timestamp = fileName.replaceAll(RegExp(r'[^0-9]'), '');

      // Search strategies
      final recoveryStrategies = [
        // Strategy 1: Search with timestamp
        () async {
          final appDocs = await getApplicationDocumentsDirectory();
          final tempDir = await getTemporaryDirectory();
          
          final searchDirs = [appDocs, tempDir];
          
          for (var dir in searchDirs) {
            final matchingFiles = await dir.list(recursive: true)
              .where((event) => 
                event is File && 
                event.path.contains(timestamp)
              )
              .toList();
            
            if (matchingFiles.isNotEmpty) {
              return (matchingFiles.first as File).path;
            }
          }
          return null;
        },

        // Strategy 2: Broader pattern matching
        () async {
          final appDocs = await getApplicationDocumentsDirectory();
          final tempDir = await getTemporaryDirectory();
          
          final searchDirs = [appDocs, tempDir];
          
          for (var dir in searchDirs) {
            final matchingFiles = await dir.list(recursive: true)
              .where((event) => 
                event is File && 
                path.extension(event.path) == '.m4a' &&
                path.basename(event.path).contains('recording_')
              )
              .toList();
            
            if (matchingFiles.isNotEmpty) {
              return (matchingFiles.first as File).path;
            }
          }
          return null;
        }
      ];

      // Try each recovery strategy
      for (var strategy in recoveryStrategies) {
        final recoveredPath = await strategy();
        if (recoveredPath != null) {
          print('File recovered through strategy: $recoveredPath');
          return recoveredPath;
        }
      }

      return null;
    } catch (e) {
      print('Advanced file recovery error: $e');
      return null;
    }
  }

  // Copy file to a secure, consistent location
  Future<String> _copyToSecureLocation(File originalFile) async {
    try {
      // Get application documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      
      // Create a recordings subdirectory
      final recordingsDir = Directory('${documentsDir.path}/AudioToTextRecordings');
      await recordingsDir.create(recursive: true);

      // Generate a unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'recording_$timestamp.m4a';
      final newFilePath = '${recordingsDir.path}/$fileName';

      // Copy the file
      final copiedFile = await originalFile.copy(newFilePath);
      
      print('Audio file securely copied to: ${copiedFile.path}');
      return copiedFile.path;
    } catch (e) {
      print('Secure file copy error: $e');
      // Fallback to original file path
      return originalFile.path;
    }
  }

  // New method to capture full mobile storage path
  Future<String> _captureMobileStoragePath(String filePath) async {
    try {
      final file = File(filePath);
      
      if (!await file.exists()) {
        throw FileSystemException('File does not exist', filePath);
      }

      // Platform-specific path capturing
      if (Platform.isIOS) {
        // For iOS, use Documents Directory path
        final documentsDir = await getApplicationDocumentsDirectory();
        return _extractRelativePath(documentsDir.path, filePath);
      } else if (Platform.isAndroid) {
        // For Android, use External Storage Directory
        final externalDir = await getExternalStorageDirectory();
        return _extractRelativePath(externalDir?.path ?? '', filePath);
      }

      // Fallback to absolute path
      return filePath;
    } catch (e) {
      print('Error capturing mobile storage path: $e');
      return filePath;
    }
  }

  // Helper method to extract relative path
  String _extractRelativePath(String basePath, String fullPath) {
    // Remove base path to get relative path
    String relativePath = fullPath.replaceFirst(basePath, '').trim();
    
    // Ensure path starts with a separator
    if (!relativePath.startsWith('/')) {
      relativePath = '/$relativePath';
    }

    print('Base Path: $basePath');
    print('Full Path: $fullPath');
    print('Relative Path: $relativePath');

    return relativePath;
  }

  Future<String> _normalizeAudioFilePath(String originalPath) async {
    try {
      final originalFile = File(originalPath);
      
      // Extensive logging for debugging
      print('Original audio file path: $originalPath');
      print('Original file exists: ${await originalFile.exists()}');

      // If original file doesn't exist, throw a more informative exception
      if (!await originalFile.exists()) {
        throw FileSystemException('Audio file does not exist', originalPath);
      }

      // Get multiple storage directories
      final directories = await _getIOSStorageDirectories();
      
      // Create a unique filename with more entropy
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'recording_${timestamp}_${originalFile.uri.pathSegments.last}';

      // Try to save in multiple locations
      String? savedFilePath;
      for (var directory in directories) {
        try {
          final newFilePath = '${directory.path}/$fileName';
          
          // Ensure the directory exists
          await directory.create(recursive: true);

          // Copy the file to the directory
          final copiedFile = await originalFile.copy(newFilePath);
          
          print('Audio file successfully copied to: ${copiedFile.path}');
          
          // Set the first successful copy as the saved path
          savedFilePath ??= copiedFile.path;
        } catch (e) {
          print('Error copying to directory ${directory.path}: $e');
        }
      }

      // If no successful copy, fallback to original path
      return savedFilePath ?? originalPath;
    } catch (e) {
      print('Critical error normalizing audio file path: $e');
      
      // If any step fails, return the original path as a fallback
      return originalPath;
    }
  }

  // New method to get iOS-specific storage directories
  Future<List<Directory>> _getIOSStorageDirectories() async {
    try {
      final directories = <Directory>[];

      // Application Documents Directory (Primary)
      final documentsDir = await getApplicationDocumentsDirectory();
      directories.add(documentsDir);

      // Temporary Directory (Secondary)
      final tempDir = await getTemporaryDirectory();
      directories.add(tempDir);

      // Optional: Add more iOS-specific directories if needed
      // For example, you might want to use NSFileManager in Swift for more locations

      return directories;
    } catch (e) {
      print('Error getting storage directories: $e');
      // Fallback to documents directory if all else fails
      final documentsDir = await getApplicationDocumentsDirectory();
      return [documentsDir];
    }
  }

  // Enhanced file validation method
  Future<bool> _validateAudioFile(String filePath) async {
    try {
      final file = File(filePath);
      
      // Check file existence
      if (!await file.exists()) {
        print('Audio file does not exist: $filePath');
        return false;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize == 0) {
        print('Audio file is empty: $filePath');
        return false;
      }

      // Optional: Add more validation (e.g., file type, duration)
      return true;
    } catch (e) {
      print('Audio file validation error: $e');
      return false;
    }
  }

  // Retry mechanism for transient errors
  Future<T> _retryOperation<T>(Future<T> Function() operation, {int maxAttempts = 3}) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        if (attempts >= maxAttempts) rethrow;
        
        // Exponential backoff
        await Future.delayed(Duration(seconds: attempts * 2));
      }
    }
  }

  Stream<List<TranscriptionModel>> getUserTranscriptions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('transcriptions')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TranscriptionModel.fromFirestore(doc, null))
            .toList())
        .handleError((error) {
      print('Error fetching transcriptions: $error');
      return <TranscriptionModel>[];
    });
  }

  Future<void> deleteTranscription(String transcriptionId) async {
    try {
      // First, get the transcription to retrieve the audio path
      final docSnapshot = await _firestore
          .collection('transcriptions')
          .doc(transcriptionId)
          .get();
      
      if (!docSnapshot.exists) {
        print('❌ No transcription found with ID: $transcriptionId');
        return;
      }

      // Delete the audio file if it exists
      final audioPath = docSnapshot.data()?['audioPath'];
      if (audioPath != null) {
        final audioFile = File(audioPath);
        if (await audioFile.exists()) {
          await audioFile.delete();
          print('🗑️ Deleted Audio File: $audioPath');
        }
      }

      // Delete the transcription from Firestore
      await _firestore
          .collection('transcriptions')
          .doc(transcriptionId)
          .delete();

      print('🎉 Transcription Deleted Successfully:');
      print('🆔 Transcription ID: $transcriptionId');
    } catch (e) {
      print('🚨 Error deleting transcription: $e');
      rethrow;
    }
  }

  // Enhanced method to retrieve transcription audio
  Future<File?> getTranscriptionAudio(String transcriptionId) async {
    try {
      // Fetch transcription document
      final docSnapshot = await _firestore
          .collection('transcriptions')
          .doc(transcriptionId)
          .get();
      
      if (!docSnapshot.exists) {
        print('❌ No transcription found with ID: $transcriptionId');
        return null;
      }

      // Extract audio path
      final audioPath = docSnapshot.data()?['audioPath'];
      if (audioPath == null) {
        print('❌ No audio path found for transcription: $transcriptionId');
        return null;
      }

      // Check file existence
      final audioFile = File(audioPath);
      if (!await audioFile.exists()) {
        print('❌ Audio file does not exist: $audioPath');
        return null;
      }

      print('🎵 Retrieved Audio File:');
      print('📍 Path: $audioPath');
      print('📦 File Size: ${await audioFile.length()} bytes');

      return audioFile;
    } catch (e) {
      print('🚨 Error retrieving transcription audio: $e');
      return null;
    }
  }

  // Method to list user's transcriptions with audio files
  Future<List<TranscriptionModel>> getUserTranscriptionsWithAudio() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Fetch user transcriptions
      final querySnapshot = await _firestore
          .collection('transcriptions')
          .where('userId', isEqualTo: user.uid)
          .get();

      // Convert to transcription models and filter valid audio files
      final transcriptions = await Future.wait(
        querySnapshot.docs.map((doc) async {
          final transcription = TranscriptionModel.fromFirestore(doc, null);
          
          // Validate audio file
          final audioFile = File(transcription.audioPath);
          if (await audioFile.exists()) {
            return transcription;
          }
          return null;
        })
      );

      // Remove null entries (invalid audio files)
      final validTranscriptions = transcriptions.whereType<TranscriptionModel>().toList();

      print('🎵 User Transcriptions:');
      print('📊 Total Transcriptions: ${validTranscriptions.length}');

      return validTranscriptions;
    } catch (e) {
      print('🚨 Error fetching user transcriptions: $e');
      return [];
    }
  }
} 
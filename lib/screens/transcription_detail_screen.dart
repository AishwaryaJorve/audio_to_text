import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/transcription_model.dart';
import '../services/transcription_service.dart';

class TranscriptionDetailScreen extends StatefulWidget {
  final TranscriptionModel transcription;

  const TranscriptionDetailScreen({
    Key? key, 
    required this.transcription
  }) : super(key: key);

  @override
  _TranscriptionDetailScreenState createState() => _TranscriptionDetailScreenState();
}

class _TranscriptionDetailScreenState extends State<TranscriptionDetailScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
    _prepareAudioFile();
  }

  void _initAudioPlayer() {
    // Listen to audio player states
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
      });
    });

    // Listen to audio duration
    _audioPlayer.onDurationChanged.listen((newDuration) {
      setState(() {
        _duration = newDuration;
      });
    });

    // Listen to audio position
    _audioPlayer.onPositionChanged.listen((newPosition) {
      setState(() {
        _position = newPosition;
      });
    });
  }

  Future<void> _prepareAudioFile() async {
    try {
      // Extensive logging for debugging
      print('Attempting to prepare audio file: ${widget.transcription.audioPath}');
      print('Current working directory: ${Directory.current.path}');

      // Multiple strategies to locate the audio file
      final possiblePaths = await _generatePossibleAudioPaths();

      // Try each possible path
      for (var path in possiblePaths) {
        print('Checking path: $path');
        
        // Use glob-like pattern matching for iOS paths
        final matchingFiles = await _findMatchingFiles(path);
        
        if (matchingFiles.isNotEmpty) {
          setState(() {
            _localFilePath = matchingFiles.first;
          });
          print('Audio file successfully located at: ${_localFilePath}');
          return;
        }
      }

      // If no file found, perform an extensive search
      final searchResult = await _performExtensiveFileSearch();
      if (searchResult != null) {
        setState(() {
          _localFilePath = searchResult;
        });
        return;
      }

      // Log detailed error information
      print('Audio File Location Failure Details:');
      print('Original Path: ${widget.transcription.audioPath}');
      print('Possible Paths Checked: $possiblePaths');

      // Show a comprehensive error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Audio file could not be located. Please check your recordings.'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _prepareAudioFile,
          ),
        ),
      );
    } catch (e) {
      print('Critical error preparing audio file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unexpected error accessing audio file: $e'),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Generate multiple possible paths for the audio file
  Future<List<String>> _generatePossibleAudioPaths() async {
    final transcriptionPath = widget.transcription.audioPath;
    final paths = <String>[];

    try {
      // 1. Original path from transcription (full path)
      paths.add(transcriptionPath);

      // Extract filename and potential variations
      final fileName = transcriptionPath.split('/').last;
      final fileNameWithoutExtension = fileName.split('.').first;

      // 2. Application Documents Directory
      final documentsDir = await getApplicationDocumentsDirectory();
      paths.addAll([
        '${documentsDir.path}/$fileName',
        '${documentsDir.path}/AudioToTextRecordings/$fileName',
        '${documentsDir.path}/$fileNameWithoutExtension.m4a',
        '${documentsDir.path}/AudioToTextRecordings/$fileNameWithoutExtension.m4a',
      ]);

      // 3. Temporary Directory
      final tempDir = await getTemporaryDirectory();
      paths.addAll([
        '${tempDir.path}/$fileName',
        '${tempDir.path}/AudioToTextRecordings/$fileName',
        '${tempDir.path}/$fileNameWithoutExtension.m4a',
        '${tempDir.path}/AudioToTextRecordings/$fileNameWithoutExtension.m4a',
      ]);

      // 4. Platform-specific additional paths for iOS
      if (Platform.isIOS) {
        // iOS specific paths based on the log
        final appContainerPath = '/var/mobile/Containers/Data/Application';
        paths.addAll([
          '$appContainerPath/*/Documents/$fileName',
          '$appContainerPath/*/Documents/AudioToTextRecordings/$fileName',
          '$appContainerPath/*/Library/Caches/$fileName',
          '$appContainerPath/*/Library/Caches/AudioToTextRecordings/$fileName',
        ]);
      }

      // Remove any duplicate paths
      return paths.toSet().toList();
    } catch (e) {
      print('Error generating possible audio paths: $e');
      return [transcriptionPath];
    }
  }

  // Perform an extensive file search across directories
  Future<String?> _performExtensiveFileSearch() async {
    try {
      final fileName = widget.transcription.audioPath.split('/').last;
      final fileNameWithoutExtension = fileName.split('.').first;
      
      // Directories to search
      final searchDirectories = [
        await getApplicationDocumentsDirectory(),
        await getTemporaryDirectory(),
      ];

      // Additional iOS-specific search paths
      if (Platform.isIOS) {
        final appContainerPath = Directory('/var/mobile/Containers/Data/Application');
        if (await appContainerPath.exists()) {
          // Perform a more comprehensive search
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

      // Comprehensive search strategy
      for (var directory in searchDirectories) {
        try {
          final searchResults = await directory.list(recursive: true)
            .where((event) => 
              event is File && 
              (event.path.contains(fileName) || 
               event.path.contains(fileNameWithoutExtension))
            )
            .toList();

          if (searchResults.isNotEmpty) {
            final recoveredFile = searchResults.first as File;
            print('Recovered audio file: ${recoveredFile.path}');
            return recoveredFile.path;
          }
        } catch (e) {
          print('Search in directory ${directory.path} failed: $e');
        }
      }

      return null;
    } catch (e) {
      print('Extensive file search error: $e');
      return null;
    }
  }

  // Helper method to find matching files with glob-like pattern
  Future<List<String>> _findMatchingFiles(String pathPattern) async {
    try {
      // Remove wildcard patterns
      final cleanPath = pathPattern.replaceAll(RegExp(r'\*+'), '');
      
      // Check if the path is a valid file path
      final file = File(cleanPath);
      if (await file.exists()) {
        return [cleanPath];
      }

      // If not a direct file path, search in directories
      final directory = Directory(path.dirname(cleanPath));
      if (await directory.exists()) {
        final fileName = path.basename(cleanPath);
        final matchingFiles = await directory.list()
          .where((event) => 
            event is File && 
            path.basename(event.path).contains(fileName)
          )
          .map((event) => event.path)
          .toList();

        return matchingFiles;
      }

      return [];
    } catch (e) {
      print('Error finding matching files: $e');
      return [];
    }
  }

  Future<void> _playPauseAudio() async {
    if (_localFilePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No audio file available')),
      );
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        // Check if file exists before playing
        final file = File(_localFilePath!);
        if (await file.exists()) {
          await _audioPlayer.play(DeviceFileSource(_localFilePath!));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Audio file not found')),
          );
        }
      }
    } catch (e) {
      print('Audio playback error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  Future<void> _deleteTranscription() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transcription'),
        content: const Text('Are you sure you want to delete this transcription?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      final transcriptionService = TranscriptionService();
      await transcriptionService.deleteTranscription(widget.transcription.id);
      
      // Delete the audio file if it exists
      if (_localFilePath != null) {
        try {
          final file = File(_localFilePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error deleting audio file: $e');
        }
      }
      
      if (mounted) {
        Navigator.of(context).pop(); // Go back to previous screen
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final transcription = widget.transcription;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Transcription Details', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteTranscription,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date and Time Header
            Text(
              '${transcription.createdAt.day} ${_getMonthName(transcription.createdAt.month)} ${transcription.createdAt.year}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 16),

            // Audio Player Section
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Audio Recording',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                          onPressed: _playPauseAudio,
                        ),
                        Expanded(
                          child: Slider(
                            value: _position.inMilliseconds.toDouble(),
                            max: _duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              _audioPlayer.seek(Duration(milliseconds: value.toInt()));
                            },
                          ),
                        ),
                        Text(
                          '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Transcription Text Section
            Text(
              'Transcription',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor, width: 1),
              ),
              child: Text(
                transcription.text,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
} 
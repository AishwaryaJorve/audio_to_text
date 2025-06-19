import 'dart:async';
import 'dart:math';

import 'package:audio_to_text/shared/widgets/recording_header.dart';

import '../providers/warning_message_box.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants/icons/app_icons.dart';
import '../services/transcription_service.dart' as service;
import '../services/audio_service.dart';

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({Key? key}) : super(key: key);

  @override
  _RecordingScreenState createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  // Remove these variables as they're related to pause functionality
  int get _audioDuration => DateTime.now().millisecondsSinceEpoch;

  // Keep essential variables
  final service.TranscriptionService _transcriptionService = service.TranscriptionService();
  final AudioService _audioService = AudioService();
  late TextEditingController _editingController;
  final ScrollController _scrollController = ScrollController();
  
  String _transcribedText = '';
  String _currentAudioPath = '';
  bool _isRecording = false;
  bool _showWarning = false;
  bool _isEditing = false;
  String _recordingDuration = '0:00';
  List<double> _soundLevels = List.filled(10, 0.3);
  Timer? _timer;
  Timer? _animationTimer;
  int _totalSeconds = 0;
  bool _showSaveConfirmation = false;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController();
    _initializeServices();
  }

  @override
  void dispose() {
    _editingController.dispose();
    _stopTimer();
    _audioService.dispose();
    _scrollController.dispose();
    _animationTimer?.cancel();
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

  //  method to handle timer
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _totalSeconds++; // Increment total seconds
        _recordingDuration = _formatDuration(_totalSeconds);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _startRecording() async {
    if (_transcribedText.isNotEmpty) {
      setState(() => _showSaveConfirmation = true);
      return;
    }

    try {
      var micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        setState(() => _showWarning = true);
        return;
      }

      setState(() {
        _isRecording = true;
      });

      _startTimer();

      final audioPath = await _audioService.startRecording((text) {
        if (text.isNotEmpty && text.trim() != '') {
          setState(() {
              _transcribedText = text.trim();
           
            
            if (_scrollController.hasClients) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                );
              });
            }
          });
        }
      });

      setState(() {
        _currentAudioPath = audioPath;
      });
    } catch (e) {
      _handleRecordingError(e);
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _audioService.stopRecording();
      _timer?.cancel();
      _animationTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _soundLevels = List.filled(10, 0.3);
        // Don't reset _recordingDuration here
      });
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

  // Add method to handle stop functionality
  void _handleStop() async {
    if (_isRecording) {
      await _audioService.stopRecording();
      _timer?.cancel();
      _animationTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _soundLevels = List.filled(10, 0.3);
      });
    }
  }

  // Update _handleEdit method
  void _handleEdit() {
    if (!_isRecording && _transcribedText.isNotEmpty) {
      setState(() {
        _isEditing = true;
        _editingController.text = _transcribedText;
      });
    }
  }

  // Update save functionality in text widget
  void _handleSave() {
    setState(() {
      _transcribedText = _editingController.text.trim();
      _isEditing = false;
    });
    FocusScope.of(context).unfocus();
  }

  // Update the transcribed text display widget
  Widget _buildTranscribedTextWidget() {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!, width: 1),
      ),
      child: _isEditing
          ? Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => FocusScope.of(context).unfocus(),
                      child: const Text(
                        'Done',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: TextField(
                    controller: _editingController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Edit transcribed text...',
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => setState(() {
                          _isEditing = false;
                          FocusScope.of(context).unfocus();
                        }),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                      TextButton(
                        onPressed: _handleSave,
                        child: const Text(
                          'Save',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              child: Text(
                _transcribedText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
    );
  }


  // Update the build method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF23272F),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      RecordingHeader(
                        transcribedText: _transcribedText,
                        audioPath: _currentAudioPath,
                        audioDuration: DateTime.now().millisecondsSinceEpoch,
                        recordingDuration: _recordingDuration,
                        onDelete: () {
                          setState(() {
                            _transcribedText = '';
                            _currentAudioPath = '';
                          });
                        },
                        onDurationReset: (duration) {
                          setState(() {
                            _recordingDuration = duration;
                          });
                        },
                      ),
                      const SizedBox(height: 20), // Add some spacing

                      // Transcribed text or editing area
                      if (_transcribedText.isNotEmpty) _buildTranscribedTextWidget(),

                      // Warning Message Box
                      if (_showWarning) 
                        WarningMessageBox(
                          warningType: WarningType.noSound,
                          isVisible: _showWarning,
                          onClose: () => setState(() => _showWarning = false),
                          onAction: () => setState(() => _showWarning = false),
                          onDismiss: () => setState(() => _showWarning = false),
                        ),

                        if (_showSaveConfirmation)
              WarningMessageBox(
                warningType: WarningType.saveConfirmation,
                isVisible: _showSaveConfirmation,
                onClose: () {
                  setState(() => _showSaveConfirmation = false);
                },
                onAction: () {
                  // Call same save method as header
                  final transcriptionService = service.TranscriptionService();
                  transcriptionService.saveTranscription(
                    text: _transcribedText,
                    audioPath: _currentAudioPath,
                    duration: _audioDuration,
                  ).then((_) {
                    setState(() {
                      _showSaveConfirmation = false;
                      _recordingDuration = '0:00';
                      _totalSeconds = 0;
                      _transcribedText = '';
                      _currentAudioPath = '';
                    });
                    _startRecording();
                  });
                },
                onDismiss: () {
                  setState(() {
                    _showSaveConfirmation = false;
                    _transcribedText = '';
                    _currentAudioPath = '';
                    _recordingDuration = '0:00';
                    _totalSeconds = 0;
                  });
                  _startRecording();
                },
              ),
                    ],
                  ),
                ),
              
              ),
            ),
            
            // Recording visualization moved here
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.red : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: List.generate(
                        10,
                        (index) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: 24 * _soundLevels[index],
                            decoration: BoxDecoration(
                              gradient: _isRecording
                                  ? LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        Colors.blue.withOpacity(0.3),
                                        Colors.blue.withOpacity(_soundLevels[index]),
                                      ],
                                    )
                                  : null,
                              color: _isRecording ? null : Colors.grey[800],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _recordingDuration,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Bottom controls
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  // Update bottom controls widget
  Widget _buildBottomControls() {
    bool editEnabled = !_isRecording && _transcribedText.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isRecording ? Icons.stop : Icons.mic,
              color: Colors.white,
            ),
            onPressed: _isRecording ? _stopRecording : _startRecording,
          ),
          IconButton(
            icon: Icon(
              Icons.edit_note,
              color: editEnabled ? Colors.white : Colors.grey[800],
            ),
            style: IconButton.styleFrom(
              disabledBackgroundColor: Colors.transparent,
              foregroundColor: editEnabled ? Colors.white : Colors.grey[800],
            ),
            onPressed: editEnabled ? _handleEdit : null,
          ),
        ],
      ),
    );
  }
}
import 'dart:async';
import 'dart:math';

import '../providers/warning_message_box.dart';
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

  //  to store transcribed text
  String _transcribedText = '';

  String _currentAudioPath = '';
  int _audioDuration = 0;
  bool _isRecording = false;

  // Add new state variable for warning visibility
  bool _showWarning = false;

  // Add these new variables
  String _recordingDuration = '0:00';
  Timer? _timer;
  int _secondsElapsed = 0;

  // Add this controller as a class variable at the top of _RecordingScreenState
  final ScrollController _scrollController = ScrollController();

  // Add these variables to your _RecordingScreenState class
  List<double> _soundLevels = List.filled(10, 0.3);
  Timer? _animationTimer;

  // Add new state variables
  bool _isEditing = false;
  bool _isPaused = false;
  late TextEditingController _editingController;

  // Add this for tracking total recording time
  int _totalSeconds = 0;

  // Add these variables in _RecordingScreenState
  String _oldTranscribedText = '';
  String _newTranscribedText = '';

  @override
  void initState() {
    super.initState();
    _transcriptionController = TextEditingController();
    _editingController = TextEditingController();
    _initializeServices();
  }

  @override
  void dispose() {
    _editingController.dispose();
    _stopTimer();
    _transcriptionController.dispose();
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

  // Add this method to animate sound levels
  void _startSoundAnimation() {
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_isRecording) {
        setState(() {
          for (var i = 0; i < _soundLevels.length; i++) {
            // Generate random heights between 0.3 and 1.0
            _soundLevels[i] = 0.3 + (0.7 * Random().nextDouble());
          }
        });
      }
    });
  }

  Future<void> _toggleRecording() async {
    try {
      if (!_isRecording) {
        var micStatus = await Permission.microphone.status;
        if (!micStatus.isGranted) {
          setState(() => _showWarning = true);
          return;
        }

        setState(() {
          _isRecording = true;
          _oldTranscribedText = _transcribedText; // Store existing text
          _newTranscribedText = ''; // Reset new text
        });

        _startTimer();
        _startSoundAnimation();

        final audioPath = await _audioService.startRecording((text) {
          if (text.isNotEmpty && text.trim() != '') {
            setState(() {
              _newTranscribedText = text.trim();
              // Combine old and new text
              _transcribedText = _oldTranscribedText.isEmpty 
                  ? _newTranscribedText 
                  : '$_oldTranscribedText. $_newTranscribedText';

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
      } else {
        // Stop recording
        await _audioService.stopRecording();
        _stopTimer();
        _animationTimer?.cancel(); // Add this line
        
        // Update state
        setState(() {
          _isRecording = false;
          _secondsElapsed = 0;
          _recordingDuration = '0:00';
          _soundLevels = List.filled(10, 0.3); // Reset sound levels
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

  // Update the handlePause method
  void _handlePause() async {
    if (_isRecording) {
      setState(() {
        _isPaused = !_isPaused;
      });
      
      if (_isPaused) {
        _timer?.cancel();
        await _audioService.pauseRecording();
        _animationTimer?.cancel();
        // Store current text as old text when pausing
        _oldTranscribedText = _transcribedText;
      } else {
        _startTimer();
        _startSoundAnimation();
        await _audioService.resumeRecording();
        // Start fresh recording for new text
        await _restartRecording();
      }
    }
  }

  // Update the restartRecording method
  Future<void> _restartRecording() async {
    try {
      final audioPath = await _audioService.startRecording((text) {
        if (text.isNotEmpty && text.trim().isNotEmpty) {
          setState(() {
            _newTranscribedText = text.trim();
            // Combine old and new text
            _transcribedText = _oldTranscribedText.isEmpty 
                ? _newTranscribedText 
                : '$_oldTranscribedText. $_newTranscribedText';

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
      print('Error restarting recording: $e');
      _handleRecordingError(e);
    }
  }

  // Add method to handle stop functionality
  void _handleStop() async {
    if (_isRecording) {
      await _audioService.stopRecording();
      _stopTimer();
      _animationTimer?.cancel();
      
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _oldTranscribedText = _transcribedText; // Store final text
        _newTranscribedText = '';
        _secondsElapsed = 0;
        _recordingDuration = '0:00';
        _soundLevels = List.filled(10, 0.3);
      });
    }
  }

  // Add method to handle edit functionality
  void _handleEdit() {
    final wasRecording = _isRecording && !_isPaused;
    if (wasRecording) {
      _handlePause(); // Pause recording while editing
    }
    
    setState(() {
      _isEditing = true;
      _editingController.text = _transcribedText;
    });
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
                // Add toolbar for keyboard dismissal
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus(); // Dismiss keyboard
                      },
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
                // Move buttons to bottom and ensure they're always visible
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
                        onPressed: () {
                          final previousText = _transcribedText;
                          setState(() {
                            _transcribedText = _editingController.text.trim();
                            _isEditing = false;
                          });
                          
                          // If we were recording and paused, resume recording
                          if (_isRecording && _isPaused) {
                            Future.delayed(const Duration(milliseconds: 100), () {
                              _handlePause(); // This will trigger resume through _restartRecording
                            });
                          }
                          
                          FocusScope.of(context).unfocus();
                        },
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

  // Update the header section
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Note',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz, color: Colors.white),
          onPressed: () {},
        ),
      ],
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      _buildHeader(),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Thu, 12/06 · 10:35PM',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.access_time, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '0:00',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.person, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Aishwarya Jorve',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // Add some spacing

                      // Transcribed text or editing area
                      if (_transcribedText.isNotEmpty)
                        Container(
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
                                    // Add toolbar for keyboard dismissal
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: () {
                                            FocusScope.of(context).unfocus(); // Dismiss keyboard
                                          },
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
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                        maxLines: null,
                                        keyboardType: TextInputType.multiline,
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          hintText: 'Edit transcribed text...',
                                          hintStyle: TextStyle(color: Colors.grey),
                                        ),
                                      ),
                                    ),
                                    // Move buttons to bottom and ensure they're always visible
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
                                            onPressed: () {
                                              final previousText = _transcribedText;
                                              setState(() {
                                                _transcribedText = _editingController.text.trim();
                                                _isEditing = false;
                                              });
                                              
                                              // If we were recording and paused, resume recording
                                              if (_isRecording && _isPaused) {
                                                Future.delayed(const Duration(milliseconds: 100), () {
                                                  _handlePause(); // This will trigger resume through _restartRecording
                                                });
                                              }
                                              
                                              FocusScope.of(context).unfocus();
                                            },
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
                        ),

                      // Warning Message Box
                      if (_showWarning) 
                        WarningMessageBox(
                          warningType: WarningType.noSound,
                          isVisible: _showWarning,
                          onClose: () => setState(() => _showWarning = false),
                          onAction: () => setState(() => _showWarning = false),
                          onDismiss: () => setState(() => _showWarning = false),
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

  // Update the bottom controls widget
  Widget _buildBottomControls() {
    // First determine if edit should be enabled
    bool editEnabled = !_isRecording && _transcribedText.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(
              _isRecording 
                  ? (_isPaused ? Icons.mic : Icons.pause)
                  : Icons.mic,
              color: Colors.white,
            ),
            onPressed: _isRecording ? _handlePause : _toggleRecording,
          ),
          IconButton(
            icon: const Icon(Icons.stop, color: Colors.white),
            onPressed: _handleStop,
          ),
          IconButton(
            icon: Icon(
              Icons.edit_note,
              // Make disabled state very clear with a darker gray
              color: editEnabled ? Colors.white : Colors.grey[800],
            ),
            // Use disabled state styling
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
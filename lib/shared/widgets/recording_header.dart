import 'package:audio_to_text/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../services/transcription_service.dart';

class RecordingHeader extends StatelessWidget {
  final String transcribedText;
  final String audioPath;
  final int audioDuration;
  final String recordingDuration;
  final VoidCallback? onDelete;
  final Function(String)? onDurationReset; // Add callback for duration reset

  const RecordingHeader({
    Key? key,
    required this.transcribedText,
    required this.audioPath,
    required this.audioDuration,
    required this.recordingDuration,
    this.onDelete,
    this.onDurationReset, // Add to constructor
  }) : super(key: key);

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final hour = now.hour > 12 ? now.hour - 12 : now.hour;
    final minute = now.minute.toString().padLeft(2, '0');
    final ampm = now.hour >= 12 ? 'PM' : 'AM';
    return 'Thu, $month/$day · $hour:$minute$ampm';
  }

  Future<void> _saveTranscription(BuildContext context) async {
    try {
      if (transcribedText.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nothing to save - no transcribed text')),
        );
        return;
      }

      final transcriptionService = TranscriptionService();
      await transcriptionService.saveTranscription(
        text: transcribedText,
        audioPath: audioPath,
        duration: audioDuration,
      );

      // Reset duration only after successful save
      onDurationReset?.call('0:00');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transcription saved successfully')),
        );
        
        // Replace Navigator.pop with navigation to HomeScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save transcription: $e')),
        );
      }
      print('Save error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: Colors.white),
              onSelected: (value) async {  // Make this async
                switch (value) {
                  case 'save':
                    await _saveTranscription(context);  // Wait for save to complete
                    break;
                  case 'delete':
                    onDelete?.call();
                    onDurationReset?.call('0:00');
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'save',
                  child: Row(
                    children: [
                      Icon(Icons.save, size: 20),
                      SizedBox(width: 8),
                      Text('Save'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              _getCurrentTimestamp(),
              style: TextStyle(color: Colors.grey[400]),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.access_time, color: Colors.grey, size: 16),
            const SizedBox(width: 4),
            Text(
              recordingDuration,
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
      ],
    );
  }
}
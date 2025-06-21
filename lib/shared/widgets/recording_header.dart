import 'package:audio_to_text/screens/home_screen.dart';
import 'package:flutter/material.dart';
import '../../services/transcription_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    // Display user's display name, or email, or 'User' if both are null
                    user?.displayName ?? user?.email ?? 'User',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_horiz, 
                  color: theme.colorScheme.onBackground,  // This will ensure visibility in both modes
                ),
                onSelected: (value) async {
                  switch (value) {
                    case 'save':
                      await _saveTranscription(context);
                      break;
                    case 'delete':
                      onDelete?.call();
                      onDurationReset?.call('0:00');
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'save',
                    child: Row(
                      children: [
                        Icon(Icons.save, size: 20, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text('Save', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: theme.colorScheme.onSurface),
                        const SizedBox(width: 8),
                        Text('Delete', style: theme.textTheme.bodyMedium),
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
              Icon(Icons.calendar_today, 
                color: theme.colorScheme.onBackground.withOpacity(0.6), 
                size: 16
              ),
              const SizedBox(width: 4),
              Text(
                _getCurrentTimestamp(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.access_time, 
                color: theme.colorScheme.onBackground.withOpacity(0.6), 
                size: 16
              ),
              const SizedBox(width: 4),
              Text(
                recordingDuration,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.person, 
                color: theme.colorScheme.onBackground.withOpacity(0.6), 
                size: 16
              ),
              const SizedBox(width: 4),
              Text(
                // Display user's display name, or email, or 'User' if both are null
                user?.displayName ?? user?.email ?? 'User',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
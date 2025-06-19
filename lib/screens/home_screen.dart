import 'package:flutter/material.dart';
import '../shared/widgets/bottom_navigation.dart';
import '../services/transcription_service.dart';
import '../models/transcription_model.dart';
import 'account_screen.dart';
import 'recording_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final TranscriptionService _transcriptionService = TranscriptionService();
  String _searchQuery = '';

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const RecordingScreen();
      case 2:
        return const AccountScreen();
      default:
        return _buildHomeContent();
    }
  }

  String _formatDuration(int milliseconds) {
    final seconds = milliseconds ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildHomeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Home',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.expand_more),
                onPressed: () {
                  // Handle dropdown
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TranscriptionModel>>(
            stream: _transcriptionService.getUserTranscriptions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final transcriptions = snapshot.data ?? [];
              if (transcriptions.isEmpty) {
                return const Center(child: Text('No transcriptions found'));
              }

              // Group transcriptions by date
              final groupedTranscriptions = <String, List<TranscriptionModel>>{};
              for (var transcription in transcriptions) {
                final date = _formatDate(transcription.createdAt);
                if (!groupedTranscriptions.containsKey(date)) {
                  groupedTranscriptions[date] = [];
                }
                groupedTranscriptions[date]!.add(transcription);
              }

              return ListView.builder(
                itemCount: groupedTranscriptions.length,
                itemBuilder: (context, index) {
                  final date = groupedTranscriptions.keys.elementAt(index);
                  final dateTranscriptions = groupedTranscriptions[date]!;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          date,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...dateTranscriptions.map((transcription) => _buildTranscriptionCard(transcription)),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final transcriptionDate = DateTime(date.year, date.month, date.day);

    if (transcriptionDate == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (transcriptionDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${_getDayName(date.weekday)} ${date.day} ${_getMonthName(date.month)}';
    }
  }

  String _getDayName(int day) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[day - 1];
  }

  String _getMonthName(int month) {
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 
                   'July', 'August', 'September', 'October', 'November', 'December'];
    return months[month - 1];
  }

  Widget _buildTranscriptionCard(TranscriptionModel transcription) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.pink[100],
                  child: const Text('A', style: TextStyle(color: Colors.white)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Note',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${_formatTime(transcription.createdAt)} · ${_formatDuration(transcription.duration)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour > 12 ? time.hour - 12 : time.hour}:${time.minute.toString().padLeft(2, '0')}${time.hour >= 12 ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _getCurrentScreen(),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
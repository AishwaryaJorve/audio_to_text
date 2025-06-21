import 'package:cloud_firestore/cloud_firestore.dart';

class TranscriptionModel {
  final String id;
  final String userId;
  final String text;
  final DateTime createdAt;
  final String audioPath;
  final int duration;

  TranscriptionModel({
    required this.id,
    required this.userId,
    required this.text,
    required this.createdAt,
    required this.audioPath,
    required this.duration,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'text': text,
      'createdAt': createdAt,
      'audioPath': audioPath,
      'duration': duration,
    };
  }

  factory TranscriptionModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
    SnapshotOptions? options,
  ) {
    final data = snapshot.data() ?? {};
    return TranscriptionModel(
      id: data['id'] ?? snapshot.id,
      userId: data['userId'] ?? '',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] is Timestamp) 
        ? (data['createdAt'] as Timestamp).toDate() 
        : DateTime.now(),
      audioPath: data['audioPath'] ?? '',
      duration: data['duration'] ?? 0,
    );
  }

  bool isValid() {
    return id.isNotEmpty && 
           userId.isNotEmpty && 
           text.isNotEmpty && 
           audioPath.isNotEmpty && 
           duration > 0;
  }

  String get formattedDate {
    return '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}';
  }

  String get audioFileName {
    return audioPath.split('/').last;
  }
} 
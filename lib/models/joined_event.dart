// lib/models/joined_event.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class JoinedEvent {
  String id; // Document ID of the joined event entry
  String eventId;
  String userId;
  DateTime joinedAt;

  JoinedEvent({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.joinedAt,
  });

  factory JoinedEvent.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return JoinedEvent(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      userId: data['userId'] ?? '',
      joinedAt: (data['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'eventId': eventId,
      'userId': userId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }
}

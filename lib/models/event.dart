import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String title;
  String description;
  String locationName;
  double latitude;
  double longitude;
  // For now, attendees will be empty. You can add List<String> attendeeUids later.
  // List<String> attendees;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    // this.attendees = const [],
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      locationName: data['locationName'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      // attendees: List<String>.from(data['attendees'] ?? []),
    );
  }

  // Method to convert Event object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      // 'attendees': attendees,
      'timestamp': FieldValue.serverTimestamp(), // Optional: adds creation time
    };
  }
}

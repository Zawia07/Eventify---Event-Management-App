import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String title;
  String description;
  String? locationName; // <--- Make nullable
  double? latitude; // <--- Make nullable
  double? longitude; // <--- Make nullable

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.locationName, // <--- No longer required
    this.latitude, // <--- No longer required
    this.longitude, // <--- No longer required
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      locationName: data['locationName'], // Will be null if not in Firestore
      latitude: (data['latitude'] as num?)
          ?.toDouble(), // Handle num? type from Firestore
      longitude: (data['longitude'] as num?)
          ?.toDouble(), // Handle num? type from Firestore
    );
  }

  // Method to convert Event object to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'locationName': locationName, // Will save null if null
      'latitude': latitude, // Will save null if null
      'longitude': longitude, // Will save null if null
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

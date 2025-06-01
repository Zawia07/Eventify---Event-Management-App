import 'package:cloud_firestore/cloud_firestore.dart';

class Event {
  String id;
  String title;
  String description;
  String? locationName;
  double? latitude;
  double? longitude;
  String? joinCode;
  String? imageUrl; // <--- NEW FIELD: URL of the event image

  Event({
    required this.id,
    required this.title,
    required this.description,
    this.locationName,
    this.latitude,
    this.longitude,
    this.joinCode,
    this.imageUrl, // <--- Add to constructor
  });

  // Factory constructor to create an Event from a Firestore DocumentSnapshot
  factory Event.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      locationName: data['locationName'],
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      joinCode: data['joinCode'],
      imageUrl: data['imageUrl'], // <--- Read imageUrl from Firestore
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
      'joinCode': joinCode,
      'imageUrl': imageUrl, // <--- Write imageUrl to Firestore
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventify2/models/event.dart';

class FirebaseService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');

  // Add a new event to Firestore
  Future<void> addEvent(Event event) async {
    await _eventsCollection.add(event.toFirestore());
  }

  // Get a stream of all events from Firestore (real-time updates)
  Stream<List<Event>> getEvents() {
    return _eventsCollection
        .orderBy('timestamp', descending: true) // Order by creation time
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        });
  }

  // You can add more methods here like updateEvent, deleteEvent later
}

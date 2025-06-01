import 'dart:io'; // Required for File
import 'dart:typed_data'; // <--- NEW IMPORT for Uint8List
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventify2/models/event.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class FirebaseService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');
  final Uuid _uuid = const Uuid();

  Future<void> addEvent(Event event) async {
    if (event.joinCode == null || event.joinCode!.isEmpty) {
      event.joinCode = _uuid.v4().substring(0, 8).toUpperCase();
    }
    await _eventsCollection.add(event.toFirestore());
  }

  Future<void> updateEvent(Event event) async {
    if (event.id.isEmpty) {
      throw Exception('Event ID is required to update an event.');
    }
    await _eventsCollection.doc(event.id).update(event.toFirestore());
  }

  Stream<List<Event>> getEvents() {
    return _eventsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        });
  }

  // Original method for native platforms (takes File)
  Future<String?> uploadEventImage(File imageFile) async {
    try {
      final fileName = _uuid.v4();
      final storageRef = FirebaseStorage.instance.ref().child(
        'event_images/$fileName.jpg',
      );
      UploadTask uploadTask = storageRef.putFile(imageFile); // Uses putFile
      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (File): $e');
      return null;
    }
  }

  // <--- NEW METHOD: Upload Image from Bytes (for web)
  Future<String?> uploadEventImageBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      final fileExtension = filename
          .split('.')
          .last; // Get original file extension
      final fileName = _uuid.v4();
      final storageRef = FirebaseStorage.instance.ref().child(
        'event_images/$fileName.$fileExtension',
      );

      UploadTask uploadTask = storageRef.putData(
        imageBytes,
      ); // Uses putData for bytes
      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (Bytes): $e');
      return null;
    }
  }
  // NEW METHOD END --->

  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }
}

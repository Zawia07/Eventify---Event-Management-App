// lib/services/firebase_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventify2/models/event.dart';
import 'package:eventify2/models/joined_event.dart'; // <--- NEW IMPORT
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');
  // NEW: Collection for tracking joined events
  final CollectionReference _joinedEventsCollection = FirebaseFirestore.instance
      .collection('joined_events'); // <--- NEW COLLECTION REFERENCE

  final Uuid _uuid = const Uuid();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const String _imageStorageBucketName = 'eventify3-7cffd-images';

  static const String _userIdKey = 'user_id';

  Future<String> getOrCreateUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString(_userIdKey);

    if (userId == null || userId.isEmpty) {
      userId = _uuid.v4();
      await prefs.setString(_userIdKey, userId);
      debugPrint('Generated new user ID: $userId');
    } else {
      debugPrint('Retrieved existing user ID: $userId');
    }
    return userId;
  }

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

  // NEW: Get all events for the user to view (same as event manager, but potentially with 'join' status)
  Stream<List<Event>> getAllEventsForUser() {
    return _eventsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        });
  }

  // NEW: Join an event
  Future<void> joinEvent(String eventId, String userId) async {
    // Check if already joined to prevent duplicates
    final existingJoin = await _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existingJoin.docs.isEmpty) {
      await _joinedEventsCollection.add({
        'eventId': eventId,
        'userId': userId,
        'joinedAt': FieldValue.serverTimestamp(),
      });
      debugPrint('User $userId joined event $eventId');
    } else {
      debugPrint('User $userId already joined event $eventId');
    }
  }

  // NEW: Check if a user has joined a specific event
  Future<bool> hasUserJoinedEvent(String eventId, String userId) async {
    if (userId.isEmpty) return false; // Cannot check if userId is empty
    final querySnapshot = await _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  // NEW: Get events joined by a specific user
  Stream<List<JoinedEvent>> getJoinedEventsByUser(String userId) {
    return _joinedEventsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinedEvent.fromFirestore(doc))
              .toList();
        });
  }

  // NEW: Get an event by its join code
  Future<Event?> getEventByJoinCode(String joinCode) async {
    final querySnapshot = await _eventsCollection
        .where('joinCode', isEqualTo: joinCode.toUpperCase())
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return Event.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // NEW: Get stream of people who joined a specific event (for event manager)
  Stream<List<JoinedEvent>> getJoinStatusForEvent(String eventId) {
    return _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('joinedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinedEvent.fromFirestore(doc))
              .toList();
        });
  }

  Reference _getStorageRefForCustomBucket(
    String fileName,
    String fileExtension,
  ) {
    return _storage
        .refFromURL('gs://$_imageStorageBucketName')
        .child('event_images/$fileName.$fileExtension');
  }

  Future<String?> uploadEventImage(File imageFile) async {
    try {
      final fileName = _uuid.v4();
      final fileExtension = imageFile.path.split('.').last;
      final storageRef = _getStorageRefForCustomBucket(fileName, fileExtension);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (File): $e');
      return null;
    }
  }

  Future<String?> uploadEventImageBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    try {
      String fileExtension = 'png';
      if (filename.contains('.')) {
        fileExtension = filename.split('.').last;
      }
      final fileName = _uuid.v4();
      final storageRef = _getStorageRefForCustomBucket(fileName, fileExtension);

      UploadTask uploadTask = storageRef.putData(imageBytes);
      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (Bytes): $e');
      return null;
    }
  }

  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }

  // New: Method to delete all join records for a deleted event (cleanup)
  Future<void> deleteAllJoinRecordsForEvent(String eventId) async {
    final querySnapshot = await _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .get();
    for (DocumentSnapshot doc in querySnapshot.docs) {
      await doc.reference.delete();
    }
    debugPrint('Deleted all join records for event $eventId');
  }
}

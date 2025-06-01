// lib/services/firebase_service.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eventify2/models/event.dart';
import 'package:eventify2/models/joined_event.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseService {
  final CollectionReference _eventsCollection = FirebaseFirestore.instance
      .collection('events');
  final CollectionReference _joinedEventsCollection = FirebaseFirestore.instance
      .collection('joined_events');

  final Uuid _uuid = const Uuid();
  // Use the default Firebase Storage instance, which points to your project's default bucket.
  final FirebaseStorage _storage = FirebaseStorage.instance;

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

  Stream<List<Event>> getAllEventsForUser() {
    return _eventsCollection
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
        });
  }

  Future<void> joinEvent(String eventId, String userId) async {
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

  Future<bool> hasUserJoinedEvent(String eventId, String userId) async {
    if (userId.isEmpty) return false;
    final querySnapshot = await _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return querySnapshot.docs.isNotEmpty;
  }

  Stream<List<JoinedEvent>> getJoinedEventsByUser(String userId) {
    return _joinedEventsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('joinedAt', descending: false) // To match your existing index
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinedEvent.fromFirestore(doc))
              .toList();
        });
  }

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

  Stream<List<JoinedEvent>> getJoinStatusForEvent(String eventId) {
    return _joinedEventsCollection
        .where('eventId', isEqualTo: eventId)
        .orderBy('joinedAt', descending: false) // Changed to ascending, check if index needed
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => JoinedEvent.fromFirestore(doc))
              .toList();
        });
  }

  Reference _getStorageRef(String fileName, String fileExtension) {
    // Points to the default bucket associated with your Firebase project
    return _storage.ref().child('event_images/$fileName.$fileExtension');
  }

  Future<String?> uploadEventImage(File imageFile) async {
    // Kept for completeness, though bytes are preferred for web
    try {
      final fileName = _uuid.v4();
      final fileExtension = imageFile.path.split('.').last;
      final storageRef = _getStorageRef(
        fileName,
        fileExtension,
      ); 

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading image (File): $e');
      return null;
    }
  }

  // --- METHOD WITH DETAILED LOGGING ---
  Future<String?> uploadEventImageBytes(
    Uint8List imageBytes,
    String filename,
  ) async {
    String? downloadUrl; // Declare outside try to ensure it's in scope for return
    try {
      String fileExtension = 'png'; // Default extension
      if (filename.contains('.')) {
        fileExtension = filename.split('.').last;
        if (fileExtension.isEmpty) fileExtension = 'png'; // Ensure valid extension
      }
      final fileName = _uuid.v4();
      final storagePath = 'event_images/$fileName.$fileExtension'; // For logging path
      final storageRef = _getStorageRef(fileName, fileExtension);
      debugPrint('[FirebaseService] Attempting to upload to: ${storageRef.fullPath}');

      UploadTask uploadTask = storageRef.putData(imageBytes);
      debugPrint('[FirebaseService] Upload task created. Awaiting completion...');

      TaskSnapshot snapshot = await uploadTask;
      debugPrint('[FirebaseService] Upload task completed. State: ${snapshot.state}');
      debugPrint('[FirebaseService] Bytes Transferred: ${snapshot.bytesTransferred}/${snapshot.totalBytes}');
      
      if (snapshot.state == TaskState.success) {
        debugPrint('[FirebaseService] Upload successful. Attempting to get download URL...');
        downloadUrl = await snapshot.ref.getDownloadURL(); // Assign to outer variable
        debugPrint('[FirebaseService] Successfully got download URL: $downloadUrl');
        return downloadUrl; // Explicitly return here if successful
      } else {
        debugPrint('[FirebaseService] Upload task did not succeed. State: ${snapshot.state}');
        // Attempt to get metadata for more info if upload failed but task "completed"
        try {
          FullMetadata metadata = await storageRef.getMetadata();
          debugPrint('[FirebaseService] Metadata for failed/paused upload path ${storageRef.fullPath}: ${metadata.size} bytes, type: ${metadata.contentType}');
        } catch (metaError) {
          debugPrint('[FirebaseService] Could not get metadata for ${storageRef.fullPath} after non-success state: $metaError');
        }
        return null; // Return null if not successful
      }
    } catch (e, s) { // Added stack trace variable 's'
      debugPrint('[FirebaseService] Error in uploadEventImageBytes: $e');
      debugPrint('[FirebaseService] Stack trace: $s'); // Print stack trace
      return null; 
    }
  }
  // --- END METHOD WITH DETAILED LOGGING ---

  Future<void> deleteEvent(String eventId) async {
    await _eventsCollection.doc(eventId).delete();
  }

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
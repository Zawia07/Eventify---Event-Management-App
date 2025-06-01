// lib/pages/joined_events_page.dart
import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart';
import 'package:eventify2/models/event.dart';
import 'package:eventify2/models/joined_event.dart';

class JoinedEventsPage extends StatefulWidget {
  const JoinedEventsPage({super.key});

  @override
  State<JoinedEventsPage> createState() => _JoinedEventsPageState();
}

class _JoinedEventsPageState extends State<JoinedEventsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  late Future<String> _userIdFuture;

  @override
  void initState() {
    super.initState();
    _userIdFuture = _firebaseService.getOrCreateUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Joined Events'), centerTitle: true),
      body: FutureBuilder<String>(
        future: _userIdFuture,
        builder: (context, userIdSnapshot) {
          if (userIdSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (userIdSnapshot.hasError) {
            return Center(
              child: Text('Error getting user ID: ${userIdSnapshot.error}'),
            );
          }
          if (!userIdSnapshot.hasData || userIdSnapshot.data!.isEmpty) {
            return const Center(child: Text('Could not get user ID.'));
          }

          final currentUserId = userIdSnapshot.data!;

          return StreamBuilder<List<JoinedEvent>>(
            stream: _firebaseService.getJoinedEventsByUser(currentUserId),
            builder: (context, joinedEventsSnapshot) {
              if (joinedEventsSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (joinedEventsSnapshot.hasError) {
                return Center(
                  child: Text('Error: ${joinedEventsSnapshot.error}'),
                );
              }
              if (!joinedEventsSnapshot.hasData ||
                  joinedEventsSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text('You have not joined any events yet.'),
                );
              }

              final joinedEvents = joinedEventsSnapshot.data!;

              // Fetch actual event details for each joined event
              return ListView.builder(
                itemCount: joinedEvents.length,
                itemBuilder: (context, index) {
                  final joinedEvent = joinedEvents[index];
                  return FutureBuilder<Event?>(
                    future: _firebaseService.getEvents().first.then((events) {
                      // Find the actual Event object by eventId from the full list
                      return events.firstWhere(
                        (event) => event.id == joinedEvent.eventId,
                        orElse: () => Event(
                          id: 'deleted',
                          title: 'Event Not Found',
                          description: 'This event may have been deleted.',
                        ), // Placeholder for deleted events
                      );
                    }),
                    builder: (context, eventSnapshot) {
                      if (eventSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Card(
                          margin: EdgeInsets.all(8.0),
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: LinearProgressIndicator(),
                          ),
                        );
                      }
                      if (eventSnapshot.hasError ||
                          eventSnapshot.data == null ||
                          eventSnapshot.data!.id == 'deleted') {
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          elevation: 2.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'Event details not available or event deleted for joined event ID: ${joinedEvent.eventId}',
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }

                      final event = eventSnapshot.data!;
                      return Card(
                        margin: const EdgeInsets.all(8.0),
                        elevation: 4.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (event.imageUrl != null &&
                                  event.imageUrl!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.network(
                                    event.imageUrl!,
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[300],
                                        child: const Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: 50,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 8),
                              Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                event.description,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              if (event.locationName != null &&
                                  event.locationName!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 18),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        'Location: ${event.locationName}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              if (event.joinCode != null &&
                                  event.joinCode!.isNotEmpty)
                                Row(
                                  children: [
                                    const Icon(Icons.vpn_key, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Join Code: ${event.joinCode}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontStyle: FontStyle.italic,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Text(
                                'Joined On: ${joinedEvent.joinedAt.toLocal().toString().split('.')[0]}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

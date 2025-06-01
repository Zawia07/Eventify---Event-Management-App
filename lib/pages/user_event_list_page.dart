// lib/pages/user_event_list_page.dart
import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart';
import 'package:eventify2/models/event.dart';

class UserEventListPage extends StatefulWidget {
  const UserEventListPage({super.key});

  @override
  State<UserEventListPage> createState() => _UserEventListPageState();
}

class _UserEventListPageState extends State<UserEventListPage> {
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
      appBar: AppBar(title: const Text('All Events'), centerTitle: true),
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

          return StreamBuilder<List<Event>>(
            stream: _firebaseService.getAllEventsForUser(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No events available.'));
              }

              final events = snapshot.data!;
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
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
                          Align(
                            alignment: Alignment.bottomRight,
                            child: FutureBuilder<bool>(
                              future: _firebaseService.hasUserJoinedEvent(
                                event.id,
                                currentUserId,
                              ),
                              builder: (context, joinedSnapshot) {
                                if (joinedSnapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                }
                                final hasJoined = joinedSnapshot.data ?? false;
                                return ElevatedButton.icon(
                                  onPressed: hasJoined
                                      ? null // Disable if already joined
                                      : () async {
                                          try {
                                            await _firebaseService.joinEvent(
                                              event.id,
                                              currentUserId,
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Joined event successfully!',
                                                  ),
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            debugPrint(
                                              'Error joining event: $e',
                                            );
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to join event: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  icon: Icon(
                                    hasJoined
                                        ? Icons.check_circle
                                        : Icons.person_add,
                                  ),
                                  label: Text(
                                    hasJoined ? 'Joined' : 'Join Event',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: hasJoined
                                        ? Colors.grey
                                        : Theme.of(context).primaryColor,
                                  ),
                                );
                              },
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
      ),
    );
  }
}

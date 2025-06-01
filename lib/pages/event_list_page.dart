// lib/pages/event_list_page.dart
import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart';
import 'package:eventify2/models/event.dart';
import 'package:eventify2/models/joined_event.dart'; // <--- NEW IMPORT
import 'package:eventify2/pages/manage_event_page.dart';

class EventListPage extends StatelessWidget {
  const EventListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseService firebaseService = FirebaseService();

    return Scaffold(
      appBar: AppBar(title: const Text('Created Events'), centerTitle: true),
      body: StreamBuilder<List<Event>>(
        stream: firebaseService.getEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No events created yet.'));
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
                      // Display Image if available
                      if (event.imageUrl != null && event.imageUrl!.isNotEmpty)
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
                      if (event.joinCode != null && event.joinCode!.isNotEmpty)
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
                      const SizedBox(height: 8), // Spacing before join status
                      // NEW: Display Join Status
                      StreamBuilder<List<JoinedEvent>>(
                        stream: firebaseService.getJoinStatusForEvent(event.id),
                        builder: (context, joinStatusSnapshot) {
                          if (joinStatusSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Text('Join Status: Loading...');
                          }
                          if (joinStatusSnapshot.hasError) {
                            return Text(
                              'Join Status Error: ${joinStatusSnapshot.error}',
                            );
                          }
                          final joinedCount =
                              joinStatusSnapshot.data?.length ?? 0;
                          return Row(
                            children: [
                              const Icon(
                                Icons.people,
                                size: 18,
                                color: Colors.blueAccent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Joined: $joinedCount ${joinedCount == 1 ? 'person' : 'people'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      Align(
                        alignment: Alignment.bottomRight,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              tooltip: 'Edit Event',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ManageEventPage(eventToEdit: event),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              tooltip: 'Delete Event',
                              onPressed: () async {
                                bool? confirmDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Event'),
                                    content: const Text(
                                      'Are you sure you want to delete this event? This will also delete all join records for it.', // Updated text
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(true),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmDelete == true) {
                                  try {
                                    // NEW: Delete associated join records first
                                    await firebaseService
                                        .deleteAllJoinRecordsForEvent(event.id);
                                    await firebaseService.deleteEvent(event.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Event and its join records deleted.',
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('Error deleting event: $e');
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to delete event: $e',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ManageEventPage()),
          );
        },
        tooltip: 'Create New Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}

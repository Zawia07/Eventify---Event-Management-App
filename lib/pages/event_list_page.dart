import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart'; // <--- CHANGE THIS LINE
import 'package:eventify2/models/event.dart'; // <--- CHANGE THIS LINE
import 'package:eventify2/pages/create_event_page.dart';

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
                      // You can add a GoogleMap widget here to display the location
                      // using event.latitude and event.longitude if you want.
                      // For a simple list, displaying text is sufficient for now.
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
            MaterialPageRoute(builder: (context) => const CreateEventPage()),
          );
        },
        tooltip: 'Create New Event',
        child: const Icon(Icons.add),
      ),
    );
  }
}

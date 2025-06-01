// lib/pages/join_event_by_code_page.dart
import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart';
import 'package:eventify2/models/event.dart';

class JoinEventByCodePage extends StatefulWidget {
  const JoinEventByCodePage({super.key});

  @override
  State<JoinEventByCodePage> createState() => _JoinEventByCodePageState();
}

class _JoinEventByCodePageState extends State<JoinEventByCodePage> {
  final TextEditingController _joinCodeController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  Event? _foundEvent;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _firebaseService.getOrCreateUserId().then((userId) {
      setState(() {
        _currentUserId = userId;
      });
    });
  }

  @override
  void dispose() {
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _searchAndJoinEvent() async {
    final joinCode = _joinCodeController.text.trim();
    if (joinCode.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a join code.')),
        );
      }
      return;
    }

    setState(() {
      _foundEvent = null; // Clear previous search results
    });

    try {
      final event = await _firebaseService.getEventByJoinCode(joinCode);
      if (mounted) {
        if (event != null) {
          setState(() {
            _foundEvent = event;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Event found!')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No event found with that code.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error searching for event: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching for event: $e')),
        );
      }
    }
  }

  Future<void> _confirmJoinEvent() async {
    if (_foundEvent == null || _currentUserId == null) return;

    try {
      final hasJoined = await _firebaseService.hasUserJoinedEvent(
        _foundEvent!.id,
        _currentUserId!,
      );
      if (mounted) {
        if (hasJoined) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already joined this event.'),
            ),
          );
        } else {
          await _firebaseService.joinEvent(_foundEvent!.id, _currentUserId!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Successfully joined the event!')),
            );
            // Optionally navigate to joined events page or clear form
            _joinCodeController.clear();
            setState(() {
              _foundEvent = null;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error confirming join: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to join event: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Join Event by Code'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _joinCodeController,
              decoration: const InputDecoration(
                labelText: 'Enter Event Join Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              textCapitalization:
                  TextCapitalization.characters, // Join codes are uppercase
              onFieldSubmitted: (value) => _searchAndJoinEvent(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchAndJoinEvent,
              icon: const Icon(Icons.search),
              label: const Text('Search Event'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 20),
            if (_foundEvent != null)
              Card(
                elevation: 4.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Found Event: ${_foundEvent!.title}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _foundEvent!.description,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _confirmJoinEvent,
                        icon: const Icon(Icons.person_add),
                        label: const Text('Confirm Join'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          textStyle: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (_foundEvent == null && _joinCodeController.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Enter a code and search to find an event.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

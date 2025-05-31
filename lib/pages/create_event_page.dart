import 'package:flutter/material.dart';
import 'package:eventify2/services/firebase_services.dart'; // Ensure 'eventify2'
import 'package:eventify2/models/event.dart'; // Ensure 'eventify2'
import 'package:google_places_flutter/google_places_flutter.dart'; // Primary autocomplete widget
import 'package:google_places_flutter/model/prediction.dart'; // The Prediction model we want to use

// Corrected import for google_maps_webservice:
// We use 'as gms_places' for general prefixing, AND 'hide Prediction'
// to explicitly tell Dart NOT to import the 'Prediction' class from this package.
import 'package:google_maps_webservice/places.dart'
    as gms_places
    hide Prediction;

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key});

  @override
  State<CreateEventPage> createState() => _CreateEventPageState();
}

class _CreateEventPageState extends State<CreateEventPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationTextController = TextEditingController();

  String _selectedLocationName = '';
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;

  final FirebaseService _firebaseService = FirebaseService();

  static const String googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationTextController.dispose();
    super.dispose();
  }

  Future<void> _createEvent() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedLocationName.isEmpty ||
          (_selectedLatitude == 0.0 && _selectedLongitude == 0.0)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a valid event location.'),
            ),
          );
        }
        return;
      }

      final newEvent = Event(
        id: '',
        title: _titleController.text,
        description: _descriptionController.text,
        locationName: _selectedLocationName,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      try {
        await _firebaseService.addEvent(newEvent);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        debugPrint('Failed to create event: $e');
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Failed to create event: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Event'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Event Information',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter event information';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Google Places Autocomplete for Location
              GooglePlaceAutoCompleteTextField(
                textEditingController: _locationTextController,
                googleAPIKey: googleMapsApiKey,
                inputDecoration: const InputDecoration(
                  labelText: 'Event Location',
                  hintText: 'Search for a place',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                debounceTime: 400,
                countries: const ["US"],
                itemClick: (Prediction prediction) async {
                  // This 'Prediction' is now unambiguously from google_places_flutter
                  _locationTextController.text = prediction.description ?? '';
                  _locationTextController
                      .selection = TextSelection.fromPosition(
                    TextPosition(offset: _locationTextController.text.length),
                  );

                  final places = gms_places.GoogleMapsPlaces(
                    apiKey: googleMapsApiKey,
                  );
                  try {
                    if (prediction.placeId != null) {
                      gms_places.PlacesDetailsResponse detail = await places
                          .getDetailsByPlaceId(prediction.placeId!);
                      if (detail.result != null &&
                          detail.result!.geometry != null) {
                        setState(() {
                          _selectedLocationName =
                              detail.result!.name ??
                              prediction.description ??
                              '';
                          _selectedLatitude =
                              detail.result!.geometry!.location.lat;
                          _selectedLongitude =
                              detail.result!.geometry!.location.lng;
                        });
                      } else {
                        debugPrint(
                          'No geometry or result found for place ID: ${prediction.placeId}',
                        );
                      }
                    }
                  } catch (e) {
                    debugPrint(
                      'Error fetching place details with google_maps_webservice: $e',
                    );
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not get full location details. Please ensure API Key is correct and Places API is enabled.',
                          ),
                        ),
                      );
                    }
                  } finally {
                    places.dispose();
                  }
                },
              ),
              if (_selectedLocationName.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'Selected: $_selectedLocationName (Lat: ${_selectedLatitude.toStringAsFixed(4)}, Lng: ${_selectedLongitude.toStringAsFixed(4)})',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _createEvent,
                icon: const Icon(Icons.add_circle),
                label: const Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

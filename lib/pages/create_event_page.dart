import 'package:flutter/material.dart';
import 'package:eventify/services/firebase_services.dart';
import 'package:eventify/models/event.dart';
import 'package:google_places_flutter/google_places_flutter.dart'; // For GooglePlaceAutoCompleteTextField
import 'package:google_places_flutter/model/prediction.dart'; // For Prediction model
import 'package:google_maps_webservice/places.dart'; // <--- THIS IS THE CORRECT IMPORT for PlaceDetails and GoogleMapsPlaces

class CreateEventPage extends StatefulWidget {
  const CreateEventPage({super.key}); // Linter fix: use_super_parameters

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

  // Linter fix: constant_identifier_names (camelCase)
  static const String googleMapsApiKey =
      "YOUR_GOOGLE_MAPS_API_KEY"; // Changed from GOOGLE_MAPS_API_KEY

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
        // Linter fix: use_build_context_synchronously (guard usage)
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
        id: '', // Firestore will generate the ID
        title: _titleController.text,
        description: _descriptionController.text,
        locationName: _selectedLocationName,
        latitude: _selectedLatitude,
        longitude: _selectedLongitude,
      );

      try {
        await _firebaseService.addEvent(newEvent);
        // Linter fix: use_build_context_synchronously (guard usage)
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Event created successfully!')),
          );
          Navigator.pop(context); // Go back to the previous page (Event List)
        }
      } catch (e) {
        // Linter fix: avoid_print (use debugPrint for dev logging)
        debugPrint('Failed to create event: $e');
        // Linter fix: use_build_context_synchronously (guard usage)
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
                  _locationTextController.text = prediction.description ?? '';
                  _locationTextController
                      .selection = TextSelection.fromPosition(
                    TextPosition(offset: _locationTextController.text.length),
                  );

                  // *** THIS IS THE CRUCIAL SECTION TO ENSURE IT'S CORRECT ***
                  // Use GoogleMapsPlaces from google_maps_webservice to fetch details
                  final places = GoogleMapsPlaces(apiKey: googleMapsApiKey);
                  try {
                    if (prediction.placeId != null) {
                      // Fetch full place details using the placeId
                      PlacesDetailsResponse detail = await places
                          .getDetailsByPlaceId(prediction.placeId!);
                      if (detail.result.geometry != null) {
                        setState(() {
                          _selectedLocationName =
                              detail.result.name ??
                              prediction.description ??
                              '';
                          _selectedLatitude =
                              detail.result.geometry!.location.lat;
                          _selectedLongitude =
                              detail.result.geometry!.location.lng;
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
                    places
                        .dispose(); // Important: Dispose of the Places client when done
                  }
                  // *** END OF CRUCIAL SECTION ***
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

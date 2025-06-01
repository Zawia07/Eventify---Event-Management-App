// lib/pages/manage_event_page.dart

import 'dart:io'; // Not used if consistently on web, but good for potential native
import 'dart:typed_data';
import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart' show kIsWeb; // kIsWeb not directly used in this simplified version
import 'package:eventify2/services/firebase_services.dart';
import 'package:eventify2/models/event.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:google_maps_webservice/places.dart'
    as gms_places
    hide Prediction;
import 'package:image_picker/image_picker.dart';

class ManageEventPage extends StatefulWidget {
  final Event? eventToEdit;

  const ManageEventPage({super.key, this.eventToEdit});

  @override
  State<ManageEventPage> createState() => _ManageEventPageState();
}

class _ManageEventPageState extends State<ManageEventPage> {
  final _formKey = GlobalKey<FormState>();
  // Ensure distinct controllers for each text input
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationTextController =
      TextEditingController(); // For Google Places

  String _selectedLocationName = '';
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String? _eventJoinCode;

  Uint8List? _pickedImageBytes;
  String? _currentImageUrl;

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  // IMPORTANT: REPLACE THIS WITH YOUR ACTUAL GOOGLE MAPS PLATFORM API KEY
  // Ensure this key has "Places API" and "Maps JavaScript API" enabled and appropriate restrictions.
  static const String googleMapsApiKey = "YOUR_ACTUAL_GOOGLE_MAPS_API_KEY_HERE";

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text =
          widget.eventToEdit!.description; // Initialize description
      _selectedLocationName = widget.eventToEdit!.locationName ?? '';
      _locationTextController.text =
          _selectedLocationName; // Initialize location text
      _selectedLatitude = widget.eventToEdit!.latitude ?? 0.0;
      _selectedLongitude = widget.eventToEdit!.longitude ?? 0.0;
      _eventJoinCode = widget.eventToEdit!.joinCode;
      _currentImageUrl = widget.eventToEdit!.imageUrl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationTextController.dispose(); // Dispose location controller
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List? bytes = await image.readAsBytes();
        if (bytes == null || bytes.isEmpty) {
          throw Exception('Image bytes could not be read.');
        }
        setState(() {
          _pickedImageBytes = bytes;
          _currentImageUrl = null;
        });
      }
    } catch (e) {
      debugPrint('Error picking or reading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load selected image: $e')),
        );
      }
      setState(() {
        _pickedImageBytes = null;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      Event event;
      String? finalImageUrl = _currentImageUrl;

      if (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty) {
        debugPrint('Attempting to upload new image...');
        try {
          finalImageUrl = await _firebaseService.uploadEventImageBytes(
            _pickedImageBytes!,
            'event_image_${DateTime.now().millisecondsSinceEpoch}.png',
          );
          debugPrint('Upload result URL: $finalImageUrl');
          if (finalImageUrl == null) {
            // Explicit check for null after upload attempt
            throw Exception('Image upload returned null URL.');
          }
        } catch (e) {
          debugPrint('Error during image upload or getting URL: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to upload image or get URL: $e')),
            );
          }
          return;
        }
      }

      if (widget.eventToEdit == null) {
        event = Event(
          id: '',
          title: _titleController.text,
          description: _descriptionController.text,
          locationName: _selectedLocationName.isNotEmpty
              ? _selectedLocationName
              : null,
          latitude: _selectedLatitude != 0.0 ? _selectedLatitude : null,
          longitude: _selectedLongitude != 0.0 ? _selectedLongitude : null,
          imageUrl: finalImageUrl,
        );
        try {
          await _firebaseService.addEvent(event);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event created successfully!')),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint('Failed to create event: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to create event: $e')),
            );
          }
        }
      } else {
        event = Event(
          id: widget.eventToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          locationName: _selectedLocationName.isNotEmpty
              ? _selectedLocationName
              : null,
          latitude: _selectedLatitude != 0.0 ? _selectedLatitude : null,
          longitude: _selectedLongitude != 0.0 ? _selectedLongitude : null,
          imageUrl: finalImageUrl,
          joinCode: widget.eventToEdit!.joinCode,
        );
        try {
          await _firebaseService.updateEvent(event);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event updated successfully!')),
            );
            Navigator.pop(context);
          }
        } catch (e) {
          debugPrint('Failed to update event: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to update event: $e')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String buttonText = widget.eventToEdit == null
        ? 'Create Event'
        : 'Update Event';
    final String appBarTitle = widget.eventToEdit == null
        ? 'Create New Event'
        : 'Edit Event';

    return Scaffold(
      appBar: AppBar(title: Text(appBarTitle), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController, // Correct controller
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.event),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter a title';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController, // Correct controller
                decoration: const InputDecoration(
                  labelText: 'Event Information',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.info),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'Please enter event information';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _pickedImageBytes != null
                      ? Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Center(
                            child: Text('Failed to load selected image.'),
                          ),
                        )
                      : _currentImageUrl != null
                      ? Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => const Center(
                            child: Text('Failed to load existing image.'),
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo,
                              size: 50,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Tap to add Event Image (Optional)',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              if (widget.eventToEdit != null && _eventJoinCode != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Join Code:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    SelectableText(
                      _eventJoinCode!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              GooglePlaceAutoCompleteTextField(
                textEditingController:
                    _locationTextController, // Correct controller
                googleAPIKey: googleMapsApiKey,
                inputDecoration: const InputDecoration(
                  labelText: 'Event Location (Optional)',
                  hintText: 'Search for a place',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                debounceTime: 400,
                countries: const ["US"], // Example, adjust as needed
                itemClick: (Prediction prediction) async {
                  _locationTextController.text = prediction.description ?? '';
                  _locationTextController
                      .selection = TextSelection.fromPosition(
                    TextPosition(offset: _locationTextController.text.length),
                  );

                  final places = gms_places.GoogleMapsPlaces(
                    apiKey: googleMapsApiKey,
                  );
                  try {
                    final detail = await places.getDetailsByPlaceId(
                      prediction.placeId!,
                    );
                    if (detail.result?.geometry?.location != null) {
                      setState(() {
                        _selectedLocationName =
                            detail.result!.name ?? prediction.description ?? '';
                        _selectedLatitude =
                            detail.result!.geometry!.location.lat;
                        _selectedLongitude =
                            detail.result!.geometry!.location.lng;
                      });
                    } else {
                      debugPrint(
                        'No geometry found for place ID: ${prediction.placeId}',
                      );
                      setState(() {
                        _selectedLocationName = '';
                        _selectedLatitude = 0.0;
                        _selectedLongitude = 0.0;
                      });
                    }
                  } catch (e) {
                    debugPrint('Error fetching place details: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Could not get full location details. Try searching again.',
                          ),
                        ),
                      );
                    }
                    setState(() {
                      _selectedLocationName = '';
                      _selectedLatitude = 0.0;
                      _selectedLongitude = 0.0;
                    });
                  } finally {
                    places.dispose();
                  }
                },
                // Optional: Handle error from the autocomplete field itself
                // getPlaceDetailWithLatLng: (Prediction prediction) { /* ... */ },
                // isLatLngRequired: true,
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
                onPressed: _saveEvent,
                icon: Icon(
                  widget.eventToEdit == null ? Icons.add_circle : Icons.save,
                ),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              if (widget.eventToEdit != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      // ... (delete event logic - unchanged)
                    },
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Delete Event'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// lib/pages/manage_event_page.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationTextController = TextEditingController();

  String _selectedLocationName = '';
  double _selectedLatitude = 0.0;
  double _selectedLongitude = 0.0;
  String? _eventJoinCode;

  // Stores bytes for web display AND upload for new image
  Uint8List? _pickedImageBytes;
  String? _currentImageUrl; // For existing image URL

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  // IMPORTANT: Replace with your actual Google Maps API Key for location services
  static const String googleMapsApiKey = "YOUR_GOOGLE_MAPS_API_KEY";

  @override
  void initState() {
    super.initState();
    if (widget.eventToEdit != null) {
      _titleController.text = widget.eventToEdit!.title;
      _descriptionController.text = widget.eventToEdit!.description;
      _selectedLocationName = widget.eventToEdit!.locationName ?? '';
      _locationTextController.text = _selectedLocationName;
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
    _locationTextController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final Uint8List? bytes = await image.readAsBytes(); // Read bytes ONCE

        if (bytes == null || bytes.isEmpty) {
          throw Exception('Image bytes could not be read.');
        }

        setState(() {
          _pickedImageBytes = bytes; // Store bytes for display and upload
          _currentImageUrl =
              null; // Clear existing URL if a new image is picked
        });
      } else {
        debugPrint('No image picked by user.');
      }
    } catch (e) {
      debugPrint('Error picking or reading image for display/upload: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load selected image for display: $e'),
          ),
        );
      }
      setState(() {
        // Clear selected image state on error
        _pickedImageBytes = null;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      Event event;
      String? finalImageUrl = _currentImageUrl; // Start with existing URL

      // Only attempt to upload a new image if _pickedImageBytes are available
      if (_pickedImageBytes != null && _pickedImageBytes!.isNotEmpty) {
        debugPrint('Attempting to upload new image...');
        try {
          finalImageUrl = await _firebaseService.uploadEventImageBytes(
            _pickedImageBytes!, // Use the already-read bytes
            'event_image_${DateTime.now().millisecondsSinceEpoch}.png', // Provide a filename for the bytes upload
          );
          debugPrint('Upload result URL: $finalImageUrl');
        } catch (e) {
          debugPrint('Error during image upload in _saveEvent: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please try again.'),
              ),
            );
          }
          return; // Stop if image upload fails
        }

        if (finalImageUrl == null) {
          debugPrint('Image upload returned null URL.');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Failed to get image URL after upload. Please try again.',
                ),
              ),
            );
          }
          return;
        }
      } else {
        debugPrint('No new image picked, retaining existing URL or null.');
      }

      if (widget.eventToEdit == null) {
        // Create new event
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
        // Update existing event
        event = Event(
          id: widget.eventToEdit!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          locationName: _selectedLocationName.isNotEmpty
              ? _selectedLocationName
              : null,
          latitude: _selectedLatitude != 0.0 ? _selectedLatitude : null,
          longitude: _selectedLongitude != 0.0 ? _selectedLongitude : null,
          imageUrl: finalImageUrl, // Use the new or existing URL
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
              // Image Picker Section (Platform-adaptive display)
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
                  child:
                      _pickedImageBytes !=
                          null // Always check bytes first for display
                      ? Image.memory(
                          _pickedImageBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Error loading picked image (memory): $error',
                            );
                            return const Center(
                              child: Text('Failed to load selected image.'),
                            );
                          },
                        )
                      : _currentImageUrl !=
                            null // Fallback to existing URL
                      ? Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            debugPrint(
                              'Error loading existing image (URL: $_currentImageUrl): $error',
                            );
                            return const Center(
                              child: Text('Failed to load existing image.'),
                            );
                          },
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
              // Display Join Code if in edit mode
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
              // Google Places Autocomplete for Location
              GooglePlaceAutoCompleteTextField(
                textEditingController: _locationTextController,
                googleAPIKey: googleMapsApiKey,
                inputDecoration: const InputDecoration(
                  labelText: 'Event Location (Optional)',
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
                        'No geometry or result found for place ID: ${prediction.placeId}',
                      );
                      setState(() {
                        _selectedLocationName = '';
                        _selectedLatitude = 0.0;
                        _selectedLongitude = 0.0;
                      });
                    }
                  } catch (e) {
                    debugPrint(
                      'Error fetching place details with google_maps_webservice: $e',
                    );
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
                      bool? confirmDelete = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Event'),
                          content: const Text(
                            'Are you sure you want to delete this event? This action cannot be undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.red,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirmDelete == true &&
                          widget.eventToEdit != null &&
                          mounted) {
                        try {
                          await _firebaseService.deleteEvent(
                            widget.eventToEdit!.id,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Event deleted successfully!'),
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          debugPrint('Failed to delete event: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete event: $e'),
                              ),
                            );
                          }
                        }
                      }
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

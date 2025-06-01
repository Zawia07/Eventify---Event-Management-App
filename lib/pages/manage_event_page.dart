// lib/pages/manage_event_page.dart

import 'dart:io'; // For File, used conditionally for native platforms
import 'dart:typed_data'; // For Uint8List, used for web image data
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // <--- NEW IMPORT for platform check
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

  XFile?
  _pickedImageXFile; // <--- CHANGED TYPE to XFile? for universal handling
  String? _currentImageUrl;

  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImageXFile = image; // Store the XFile directly
        _currentImageUrl = null; // Clear existing URL if a new image is picked
      });
    }
  }

  Future<void> _saveEvent() async {
    if (_formKey.currentState!.validate()) {
      Event event;
      String? finalImageUrl =
          _currentImageUrl; // Start with the existing image URL

      // --- START OF PLATFORM-SPECIFIC IMAGE UPLOAD LOGIC ---
      if (_pickedImageXFile != null) {
        if (kIsWeb) {
          // For web, read the image bytes and use the new uploadEventImageBytes method
          Uint8List bytes = await _pickedImageXFile!.readAsBytes();
          finalImageUrl = await _firebaseService.uploadEventImageBytes(
            bytes,
            _pickedImageXFile!.name,
          );
        } else {
          // For native, use the existing uploadEventImage method with a File object
          finalImageUrl = await _firebaseService.uploadEventImage(
            File(_pickedImageXFile!.path),
          );
        }

        if (finalImageUrl == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to upload image. Please try again.'),
              ),
            );
          }
          return; // Stop if image upload fails
        }
      }
      // --- END OF PLATFORM-SPECIFIC IMAGE UPLOAD LOGIC ---

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
          imageUrl: finalImageUrl, // Pass the uploaded image URL
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
          imageUrl: finalImageUrl, // Pass the new/updated image URL
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
                  child: _pickedImageXFile != null
                      ? kIsWeb // <--- Conditional display for web
                            ? Image.network(
                                _pickedImageXFile!
                                    .path, // On web, XFile.path is a blob URL
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'Failed to load selected image (web).',
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                // For native platforms
                                File(_pickedImageXFile!.path),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'Failed to load selected image (native).',
                                    ),
                                  );
                                },
                              )
                      : _currentImageUrl !=
                            null // Fallback to network image if editing and no new image picked
                      ? Image.network(
                          _currentImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
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

// lib/ui/screens/add_spot_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sway/blocs/spots/spots_bloc.dart';
import 'package:sway/config/constants.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/ui/widgets/custom_button.dart';

class AddSpotScreen extends StatefulWidget {
  const AddSpotScreen({Key? key}) : super(key: key);

  @override
  _AddSpotScreenState createState() => _AddSpotScreenState();
}

class _AddSpotScreenState extends State<AddSpotScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _distanceController = TextEditingController();

  List<TreeType> _selectedTreeTypes = [];
  Amenities _amenities = Amenities();
  List<File> _photos = [];
  bool _isPrivate = false;

  LatLng _selectedLocation = LatLng(
    MapConstants.defaultLatitude,
    MapConstants.defaultLongitude,
  );

  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isUsingCurrentLocation = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();

    // Add initial marker
    _updateMarkers(_selectedLocation);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _distanceController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isUsingCurrentLocation = true;
    });

    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        final location = LatLng(position.latitude, position.longitude);

        setState(() {
          _selectedLocation = location;
          _isUsingCurrentLocation = false;
        });

        _updateMarkers(location);
        _animateToLocation(location);
      } else {
        setState(() {
          _isUsingCurrentLocation = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location permission denied')),
        );
      }
    } catch (e) {
      setState(() {
        _isUsingCurrentLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    }
  }

  void _updateMarkers(LatLng location) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: MarkerId('selected_location'),
          position: location,
          draggable: true,
          onDragEnd: (newPosition) {
            setState(() {
              _selectedLocation = newPosition;
            });
          },
        ),
      );
    });
  }

  void _animateToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(location, MapConstants.defaultZoom),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _animateToLocation(_selectedLocation);
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
    });
    _updateMarkers(location);
  }

  void _toggleTreeType(TreeType treeType) {
    setState(() {
      if (_selectedTreeTypes.contains(treeType)) {
        _selectedTreeTypes.remove(treeType);
      } else {
        _selectedTreeTypes.add(treeType);
      }
    });
  }

  void _pickImages() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();

    if (pickedFiles.isNotEmpty) {
      setState(() {
        _photos.addAll(pickedFiles.map((file) => File(file.path)).toList());
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  void _takePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _photos.add(File(pickedFile.path));
      });
    }
  }

  void _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTreeTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one tree type')),
      );
      return;
    }

    if (_photos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final coordinates = Coordinates(
        latitude: _selectedLocation.latitude,
        longitude: _selectedLocation.longitude,
      );

      double? distance;
      if (_distanceController.text.isNotEmpty) {
        distance = double.tryParse(_distanceController.text);
      }

      context.read<SpotsBloc>().add(
            CreateSpot(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              coordinates: coordinates,
              treeTypes: _selectedTreeTypes,
              distanceBetweenTrees: distance,
              amenities: _amenities,
              isPrivate: _isPrivate,
              photos: _photos,
            ),
          );

      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create spot: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Hammock Spot'),
      ),
      body: BlocListener<SpotsBloc, SpotsState>(
        listener: (context, state) {
          if (state is SpotCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Spot created successfully!')),
            );
            Navigator.of(context).pop();
          } else if (state is SpotsError) {
            setState(() {
              _isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.all(16),
            children: [
              // Basic information
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              SizedBox(height: 16),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Spot Name *',
                  hintText: 'Enter a descriptive name for this spot',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),

              SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText:
                      'Describe the spot, views, and any tips for visitors',
                ),
              ),

              SizedBox(height: 24),

              // Location
              Text(
                'Location',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              // Map
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      GoogleMap(
                        onMapCreated: _onMapCreated,
                        initialCameraPosition: CameraPosition(
                          target: _selectedLocation,
                          zoom: 14,
                        ),
                        markers: _markers,
                        onTap: _onMapTap,
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                      ),
                      if (_isUsingCurrentLocation)
                        Center(
                          child: CircularProgressIndicator(),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: FloatingActionButton(
                          mini: true,
                          onPressed: _getCurrentLocation,
                          child: Icon(Icons.my_location),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 8),

              // Coordinates display
              Text(
                'Latitude: ${_selectedLocation.latitude.toStringAsFixed(6)}, Longitude: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                style: TextStyle(
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.7),
                  fontSize: 14,
                ),
              ),

              SizedBox(height: 24),

              // Tree information
              Text(
                'Tree Information',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              // Tree types
              Text(
                'Tree Types *',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TreeType.values.map((treeType) {
                  final isSelected = _selectedTreeTypes.contains(treeType);
                  return FilterChip(
                    label:
                        Text(treeType.toString().split('.').last.capitalize()),
                    selected: isSelected,
                    onSelected: (_) => _toggleTreeType(treeType),
                    selectedColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),

              SizedBox(height: 16),

              // Distance between trees
              TextFormField(
                controller: _distanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Distance Between Trees (meters)',
                  hintText: 'Enter approximate distance',
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final distance = double.tryParse(value);
                    if (distance == null || distance <= 0) {
                      return 'Please enter a valid distance';
                    }
                  }
                  return null;
                },
              ),

              SizedBox(height: 24),

              // Amenities
              Text(
                'Amenities',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              // Amenities checkboxes
              CheckboxListTile(
                title: Text('Restrooms Nearby'),
                value: _amenities.restrooms,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: value ?? false,
                      waterSource: _amenities.waterSource,
                      shade: _amenities.shade,
                      parking: _amenities.parking,
                      foodNearby: _amenities.foodNearby,
                      swimming: _amenities.swimming,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text('Water Source'),
                value: _amenities.waterSource,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: _amenities.restrooms,
                      waterSource: value ?? false,
                      shade: _amenities.shade,
                      parking: _amenities.parking,
                      foodNearby: _amenities.foodNearby,
                      swimming: _amenities.swimming,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text('Natural Shade'),
                value: _amenities.shade,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: _amenities.restrooms,
                      waterSource: _amenities.waterSource,
                      shade: value ?? false,
                      parking: _amenities.parking,
                      foodNearby: _amenities.foodNearby,
                      swimming: _amenities.swimming,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text('Parking Available'),
                value: _amenities.parking,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: _amenities.restrooms,
                      waterSource: _amenities.waterSource,
                      shade: _amenities.shade,
                      parking: value ?? false,
                      foodNearby: _amenities.foodNearby,
                      swimming: _amenities.swimming,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text('Food Nearby'),
                value: _amenities.foodNearby,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: _amenities.restrooms,
                      waterSource: _amenities.waterSource,
                      shade: _amenities.shade,
                      parking: _amenities.parking,
                      foodNearby: value ?? false,
                      swimming: _amenities.swimming,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              CheckboxListTile(
                title: Text('Swimming Available'),
                value: _amenities.swimming,
                onChanged: (value) {
                  setState(() {
                    _amenities = Amenities(
                      restrooms: _amenities.restrooms,
                      waterSource: _amenities.waterSource,
                      shade: _amenities.shade,
                      parking: _amenities.parking,
                      foodNearby: _amenities.foodNearby,
                      swimming: value ?? false,
                    );
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
              ),

              SizedBox(height: 24),

              // Privacy
              Text(
                'Privacy',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              SizedBox(height: 8),

              SwitchListTile(
                title: Text('This spot is on private property'),
                subtitle: Text(
                  'Please ensure you have permission to access and recommend this location',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.7),
                  ),
                ),
                value: _isPrivate,
                onChanged: (value) {
                  setState(() {
                    _isPrivate = value;
                  });
                },
              ),

              SizedBox(height: 24),

              // Photos
              Text(
                'Photos *',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      label: 'Take Photo',
                      icon: Icons.camera_alt,
                      onPressed: _takePicture,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CustomButton(
                      label: 'Browse Gallery',
                      icon: Icons.photo_library,
                      onPressed: _pickImages,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 16),

              // Selected photos
              if (_photos.isNotEmpty) ...[
                Text(
                  'Selected Photos (${_photos.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _photos.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.5),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _photos[index],
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removePhoto(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ] else
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_a_photo,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add at least one photo',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(height: 32),

              // Submit button
              CustomButton(
                label: 'Add Hammock Spot',
                isLoading: _isLoading,
                onPressed: _submitForm,
              ),

              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// Extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}

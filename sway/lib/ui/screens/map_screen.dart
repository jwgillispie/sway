// lib/ui/screens/map_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sway/ui/widgets/filter_sheet.dart';
import 'package:sway/ui/widgets/spots_info_sheet.dart';
import '../../blocs/spots/spots_bloc.dart';
import '../../data/models/hammock_spot.dart';


class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng _currentPosition = const LatLng(35.9375, 14.3754); // Default to Malta center
  bool _isLoading = true;
  HammockSpot? _selectedSpot;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    
    // Load initial spots
    context.read<SpotsBloc>().add(LoadSpots());
  }

  Future<void> _getCurrentLocation() async {
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
        );
        
        setState(() {
          _currentPosition = LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_currentPosition, 14)
        );
        
        // Load spots near current location
        context.read<SpotsBloc>().add(LoadSpots(
          lat: position.latitude,
          lng: position.longitude,
          radius: 5000, // 5km radius
        ));
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not get current location: $e'))
        );
      }
    } else {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied'))
      );
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    
    if (!_isLoading) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentPosition, 14)
      );
    }
  }

  void _updateMarkers(List<HammockSpot> spots) {
    final newMarkers = spots.map((spot) {
      return Marker(
        markerId: MarkerId(spot.id ?? 'new-${DateTime.now().millisecondsSinceEpoch}'),
        position: LatLng(
          spot.coordinates.latitude,
          spot.coordinates.longitude
        ),
        infoWindow: InfoWindow(title: spot.name),
        onTap: () {
          setState(() {
            _selectedSpot = spot;
          });
          
          _showSpotDetails(spot);
        },
      );
    }).toSet();
    
    setState(() {
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  void _showSpotDetails(HammockSpot spot) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SpotInfoSheet(spot: spot),
    );
  }

  void _showFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        onApplyFilters: (filters) {
          context.read<SpotsBloc>().add(LoadSpots(
            lat: _currentPosition.latitude,
            lng: _currentPosition.longitude,
            radius: filters.radius,
            treeType: filters.treeType,
            minRating: filters.minRating,
            hasAmenity: filters.amenities,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<SpotsBloc, SpotsState>(
        listener: (context, state) {
          if (state is SpotsLoaded) {
            _updateMarkers(state.spots);
          } else if (state is SpotsError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message))
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentPosition,
                  zoom: 13,
                ),
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                markers: _markers,
                onTap: (_) {
                  setState(() {
                    _selectedSpot = null;
                  });
                },
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
              if (state is SpotsLoading && !_isLoading)
                const Positioned(
                  top: 50,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: 50,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: "btn1",
                      onPressed: _getCurrentLocation,
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      heroTag: "btn2",
                      onPressed: _showFilters,
                      child: const Icon(Icons.filter_list),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/add-spot');
        },
        label: const Text('Add Spot'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
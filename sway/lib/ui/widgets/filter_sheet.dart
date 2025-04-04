// lib/ui/widgets/filter_sheet.dart
import 'package:flutter/material.dart';
import 'package:sway/data/models/hammock_spot.dart';
import 'package:sway/ui/widgets/custom_button.dart';
import 'package:sway/config/constants.dart';

class FilterSheet extends StatefulWidget {
  final Function(FilterOptions) onApplyFilters;

  const FilterSheet({
    Key? key,
    required this.onApplyFilters,
  }) : super(key: key);

  @override
  _FilterSheetState createState() => _FilterSheetState();
}

class FilterOptions {
  final double radius;
  final String? treeType;
  final double? minRating;
  final List<String>? amenities;

  FilterOptions({
    this.radius = 5000.0,
    this.treeType,
    this.minRating,
    this.amenities,
  });
}

class _FilterSheetState extends State<FilterSheet> {
  double _radius = 5000.0; // Default 5km
  TreeType? _selectedTreeType;
  double _minRating = 0.0;
  final Map<String, bool> _selectedAmenities = {
    'restrooms': false,
    'water_source': false,
    'shade': false,
    'parking': false,
    'food_nearby': false,
    'swimming': false,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle and title
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Filter Spots',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),

          // Filter options
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search radius
                  Text(
                    'Search Radius',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _radius,
                          min: 1000.0,
                          max: 20000.0,
                          divisions: 19,
                          label: '${(_radius / 1000).toStringAsFixed(1)} km',
                          onChanged: (value) {
                            setState(() {
                              _radius = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        '${(_radius / 1000).toStringAsFixed(1)} km',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Tree types
                  Text(
                    'Tree Type',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text('Any'),
                        selected: _selectedTreeType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedTreeType = null;
                          });
                        },
                      ),
                      ...TreeType.values.map((type) {
                        return FilterChip(
                          label: Text(_getTreeTypeName(type)),
                          selected: _selectedTreeType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTreeType = selected ? type : null;
                            });
                          },
                        );
                      }).toList(),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Minimum rating
                  Text(
                    'Minimum Rating',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _minRating,
                          min: 0.0,
                          max: 5.0,
                          divisions: 10,
                          label: _minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _minRating = value;
                            });
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Text(
                        _minRating == 0 ? 'Any' : _minRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Amenities
                  Text(
                    'Amenities',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  CheckboxListTile(
                    title: Text('Restrooms Nearby'),
                    value: _selectedAmenities['restrooms'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['restrooms'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  
                  CheckboxListTile(
                    title: Text('Water Source'),
                    value: _selectedAmenities['water_source'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['water_source'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  
                  CheckboxListTile(
                    title: Text('Natural Shade'),
                    value: _selectedAmenities['shade'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['shade'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  
                  CheckboxListTile(
                    title: Text('Parking Available'),
                    value: _selectedAmenities['parking'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['parking'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  
                  CheckboxListTile(
                    title: Text('Food Nearby'),
                    value: _selectedAmenities['food_nearby'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['food_nearby'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                  
                  CheckboxListTile(
                    title: Text('Swimming Available'),
                    value: _selectedAmenities['swimming'],
                    onChanged: (value) {
                      setState(() {
                        _selectedAmenities['swimming'] = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
          
          // Buttons
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    label: 'Reset',
                    isOutlined: true,
                    onPressed: _resetFilters,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    label: 'Apply',
                    onPressed: _applyFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _resetFilters() {
    setState(() {
      _radius = 5000.0;
      _selectedTreeType = null;
      _minRating = 0.0;
      
      for (var key in _selectedAmenities.keys) {
        _selectedAmenities[key] = false;
      }
    });
  }
  
  void _applyFilters() {
    // Get selected amenities
    final selectedAmenities = <String>[];
    _selectedAmenities.forEach((key, value) {
      if (value) {
        selectedAmenities.add(key);
      }
    });
    
    final filterOptions = FilterOptions(
      radius: _radius,
      treeType: _selectedTreeType != null ? _selectedTreeType.toString().split('.').last : null,
      minRating: _minRating > 0 ? _minRating : null,
      amenities: selectedAmenities.isNotEmpty ? selectedAmenities : null,
    );
    
    widget.onApplyFilters(filterOptions);
    Navigator.of(context).pop();
  }
  
  String _getTreeTypeName(TreeType type) {
    final name = type.toString().split('.').last;
    return name.substring(0, 1).toUpperCase() + name.substring(1);
  }
}
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/restaurant_repository.dart';
import '../../domain/models/restaurant.dart';
import '../../../settings/data/localization/app_localizations.dart';

class RestaurantFormPage extends ConsumerStatefulWidget {
  final Restaurant? restaurant;

  const RestaurantFormPage({Key? key, this.restaurant}) : super(key: key);

  @override
  ConsumerState<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends ConsumerState<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cuisineController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _capacityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _currentOccupancyController = TextEditingController();
  final _waitTimeController = TextEditingController();
  bool _isActive = true;
  bool _hasVacancy = true;
  bool _isLoading = false;
  String _selectedCuisine = 'Italian';
  Map<String, Map<String, String>> _businessHours = {
    'Monday': {'openTime': '09:00', 'closeTime': '17:00', 'isOpen': 'true'},
    'Tuesday': {'openTime': '09:00', 'closeTime': '17:00', 'isOpen': 'true'},
    'Wednesday': {'openTime': '09:00', 'closeTime': '17:00', 'isOpen': 'true'},
    'Thursday': {'openTime': '09:00', 'closeTime': '17:00', 'isOpen': 'true'},
    'Friday': {'openTime': '09:00', 'closeTime': '17:00', 'isOpen': 'true'},
    'Saturday': {'openTime': '10:00', 'closeTime': '15:00', 'isOpen': 'true'},
    'Sunday': {'openTime': '10:00', 'closeTime': '15:00', 'isOpen': 'false'},
  };

  final List<String> _cuisineTypes = [
    'Italian',
    'Chinese',
    'Japanese',
    'Mexican',
    'Indian',
    'Thai',
    'French',
    'American',
    'Mediterranean',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.restaurant != null) {
      _nameController.text = widget.restaurant!.name;
      _cuisineController.text = widget.restaurant!.cuisine;
      _addressController.text = widget.restaurant!.address;
      _phoneController.text = widget.restaurant!.phoneNumber;
      _emailController.text = widget.restaurant!.email;
      _capacityController.text = widget.restaurant!.capacity.toString();
      _imageUrlController.text = widget.restaurant!.imageUrl ?? '';
      _currentOccupancyController.text = widget.restaurant!.currentOccupancy.toString();
      _waitTimeController.text = widget.restaurant!.waitTime.toString();
      _isActive = widget.restaurant!.isActive;
      _hasVacancy = widget.restaurant!.hasVacancy;
      _selectedCuisine = widget.restaurant!.cuisine;

      // Populate business hours if available
      widget.restaurant!.businessHours.schedule.forEach((day, hours) {
        _businessHours[day] = {
          'openTime': hours.openTime ?? '09:00',
          'closeTime': hours.closeTime ?? '17:00',
          'isOpen': hours.isOpen.toString(),
        };
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cuisineController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _capacityController.dispose();
    _imageUrlController.dispose();
    _currentOccupancyController.dispose();
    _waitTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    final isNewRestaurant = widget.restaurant == null;
    final title = isNewRestaurant 
        ? translations.translate('add_restaurant') 
        : translations.translate('edit_restaurant');
        
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: translations.translate('restaurant_name'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translations.translate('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCuisine,
                      decoration: InputDecoration(
                        labelText: translations.translate('cuisine'),
                        border: const OutlineInputBorder(),
                      ),
                      items: _cuisineTypes
                          .map((cuisine) => DropdownMenuItem(
                                value: cuisine,
                                child: Text(cuisine),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCuisine = value!;
                          _cuisineController.text = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: translations.translate('address'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translations.translate('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: translations.translate('phone_number'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translations.translate('required_field');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translations.translate('required_field');
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                          return translations.translate('invalid_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _capacityController,
                      decoration: InputDecoration(
                        labelText: translations.translate('capacity'),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translations.translate('required_field');
                        }
                        if (int.tryParse(value) == null) {
                          return translations.translate('invalid_number');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: 'Image URL',
                        hintText: 'https://example.com/image.jpg',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: Text(translations.translate('is_active')),
                      value: _isActive,
                      onChanged: (newValue) {
                        setState(() {
                          _isActive = newValue;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: Text(translations.translate('opening_hours')),
                      children: _buildBusinessHoursFields(translations),
                    ),
                    const SizedBox(height: 16),
                    ExpansionTile(
                      title: const Text('Vacancy Information'),
                      initiallyExpanded: true,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SwitchListTile(
                                title: const Text('Has Vacancy'),
                                subtitle: const Text('Toggle if restaurant currently has seating available'),
                                value: _hasVacancy,
                                onChanged: (newValue) {
                                  setState(() {
                                    _hasVacancy = newValue;
                                  });
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _currentOccupancyController,
                                decoration: const InputDecoration(
                                  labelText: 'Current Occupancy',
                                  hintText: 'Number of current guests',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _waitTimeController,
                                decoration: const InputDecoration(
                                  labelText: 'Wait Time (minutes)',
                                  hintText: 'Estimated wait time for a table',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Current capacity usage: ${_calculateOccupancyPercentage()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(translations.translate('cancel')),
                        ),
                        ElevatedButton(
                          onPressed: _saveRestaurant,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(translations.translate('save')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  List<Widget> _buildBusinessHoursFields(AppLocalizations translations) {
    return _businessHours.entries.map((entry) {
      final day = entry.key;
      final hours = entry.value;
      final isOpen = hours['isOpen'] == 'true';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(day),
            ),
            Switch(
              value: isOpen,
              onChanged: (newValue) {
                setState(() {
                  _businessHours[day]!['isOpen'] = newValue.toString();
                });
              },
            ),
            if (isOpen) ...[
              Expanded(
                child: TextFormField(
                  initialValue: hours['openTime'],
                  decoration: InputDecoration(
                    labelText: 'Open',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _businessHours[day]!['openTime'] = value;
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: hours['closeTime'],
                  decoration: InputDecoration(
                    labelText: 'Close',
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    _businessHours[day]!['closeTime'] = value;
                  },
                ),
              ),
            ] else
              const Expanded(
                child: Text('Closed', textAlign: TextAlign.center),
              ),
          ],
        ),
      );
    }).toList();
  }

  String _calculateOccupancyPercentage() {
    final capacity = int.tryParse(_capacityController.text) ?? 0;
    if (capacity == 0) return '0';
    
    final occupancy = int.tryParse(_currentOccupancyController.text) ?? 0;
    final percentage = (occupancy / capacity * 100).toStringAsFixed(1);
    return percentage;
  }

  Future<void> _saveRestaurant() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      // Convert business hours to the required format
      final businessHoursSchedule = <String, DayHours>{};

      _businessHours.forEach((day, hours) {
        businessHoursSchedule[day] = DayHours(
          isOpen: hours['isOpen'] == 'true',
          openTime: hours['openTime'],
          closeTime: hours['closeTime'],
        );
      });

      // Create opening hours map
      final openingHours = <String, String>{};
      _businessHours.forEach((day, hours) {
        if (hours['isOpen'] == 'true') {
          openingHours[day] = '${hours['openTime']}-${hours['closeTime']}';
        } else {
          openingHours[day] = 'Closed';
        }
      });

      final restaurant = Restaurant(
        id: widget.restaurant?.id ?? '',
        name: _nameController.text.trim(),
        cuisine: _cuisineController.text.trim(),
        address: _addressController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        capacity: int.tryParse(_capacityController.text.trim()) ?? 0,
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        isActive: _isActive,
        currentOccupancy: int.tryParse(_currentOccupancyController.text.trim()) ?? 0,
        hasVacancy: _hasVacancy,
        waitTime: int.tryParse(_waitTimeController.text.trim()) ?? 0,
        businessHours: BusinessHours(schedule: businessHoursSchedule),
        createdAt: widget.restaurant?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
        openingHours: openingHours,
      );

      final repository = ref.read(restaurantRepositoryProvider);

      if (widget.restaurant == null) {
        await repository.createRestaurant(restaurant);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant created successfully')),
          );
          Navigator.of(context).pop();
        }
      } else {
        await repository.updateRestaurant(restaurant);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Restaurant updated successfully')),
          );
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
} 
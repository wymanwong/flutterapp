import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/loading_overlay.dart';
import '../../domain/models/restaurant.dart';
import '../providers/restaurant_provider.dart';

class RestaurantFormPage extends ConsumerStatefulWidget {
  final String? restaurantId;

  const RestaurantFormPage({
    super.key,
    this.restaurantId,
  });

  @override
  ConsumerState<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends ConsumerState<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _capacityController = TextEditingController();
  final List<String> _selectedCuisineTypes = [];
  final Map<String, TextEditingController> _openingHoursControllers = {};
  final Map<String, TextEditingController> _pricingControllers = {};
  final List<String> _selectedAmenities = [];
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    // Initialize opening hours controllers
    for (final day in [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ]) {
      _openingHoursControllers[day] = TextEditingController();
      _pricingControllers[day] = TextEditingController();
    }

    if (widget.restaurantId != null) {
      _loadRestaurant();
    }
  }

  Future<void> _loadRestaurant() async {
    final restaurantAsync = ref.read(restaurantProvider(widget.restaurantId!));
    final restaurant = await restaurantAsync.value;
    if (restaurant != null) {
      setState(() {
        _nameController.text = restaurant.name;
        _descriptionController.text = restaurant.description;
        _addressController.text = restaurant.address;
        _phoneController.text = restaurant.phone;
        _emailController.text = restaurant.email;
        _imageUrlController.text = restaurant.imageUrl;
        _capacityController.text = restaurant.capacity.toString();
        _selectedCuisineTypes.addAll(restaurant.cuisineTypes);
        _selectedAmenities.addAll(restaurant.amenities);
        _isActive = restaurant.isActive;

        for (final entry in restaurant.openingHours.entries) {
          _openingHoursControllers[entry.key]?.text = entry.value;
        }

        for (final entry in restaurant.pricing.entries) {
          _pricingControllers[entry.key]?.text = entry.value;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _imageUrlController.dispose();
    _capacityController.dispose();
    for (final controller in _openingHoursControllers.values) {
      controller.dispose();
    }
    for (final controller in _pricingControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final restaurant = Restaurant(
      id: widget.restaurantId ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
      capacity: int.parse(_capacityController.text),
      cuisineTypes: _selectedCuisineTypes,
      openingHours: Map.fromEntries(
        _openingHoursControllers.entries.map(
          (entry) => MapEntry(entry.key, entry.value.text.trim()),
        ),
      ),
      pricing: Map.fromEntries(
        _pricingControllers.entries.map(
          (entry) => MapEntry(entry.key, entry.value.text.trim()),
        ),
      ),
      amenities: _selectedAmenities,
      isActive: _isActive,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      if (widget.restaurantId != null) {
        await ref.read(restaurantsProvider.notifier).updateRestaurant(restaurant);
      } else {
        await ref.read(restaurantsProvider.notifier).createRestaurant(restaurant);
      }
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurantsState = ref.watch(restaurantsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.restaurantId != null ? 'Edit Restaurant' : 'Add Restaurant'),
      ),
      body: LoadingOverlay(
        isLoading: restaurantsState.isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an image URL';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityController,
                  decoration: const InputDecoration(
                    labelText: 'Capacity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a capacity';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildCuisineTypesSection(),
                const SizedBox(height: 16),
                _buildOpeningHoursSection(),
                const SizedBox(height: 16),
                _buildPricingSection(),
                const SizedBox(height: 16),
                _buildAmenitiesSection(),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    widget.restaurantId != null ? 'Update Restaurant' : 'Add Restaurant',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCuisineTypesSection() {
    final cuisineTypes = [
      'Italian',
      'Japanese',
      'Chinese',
      'Mexican',
      'Indian',
      'Thai',
      'American',
      'Mediterranean',
      'French',
      'Spanish',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cuisine Types',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cuisineTypes.map((type) {
            return FilterChip(
              label: Text(type),
              selected: _selectedCuisineTypes.contains(type),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCuisineTypes.add(type);
                  } else {
                    _selectedCuisineTypes.remove(type);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildOpeningHoursSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Opening Hours',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._openingHoursControllers.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter opening hours';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pricing',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ..._pricingControllers.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TextFormField(
              controller: entry.value,
              decoration: InputDecoration(
                labelText: entry.key,
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter pricing';
                }
                return null;
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    final amenities = [
      'Wi-Fi',
      'Parking',
      'Outdoor Seating',
      'Bar',
      'Takeout',
      'Delivery',
      'Reservations',
      'Wheelchair Accessible',
      'Live Music',
      'Private Events',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amenities',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((amenity) {
            return FilterChip(
              label: Text(amenity),
              selected: _selectedAmenities.contains(amenity),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedAmenities.add(amenity);
                  } else {
                    _selectedAmenities.remove(amenity);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }
} 
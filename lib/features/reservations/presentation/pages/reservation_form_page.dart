import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../domain/models/reservation.dart';
import '../../../../features/restaurant/data/repositories/restaurant_repository.dart';
import '../../../../features/restaurant/domain/models/restaurant.dart';
import 'dart:developer' as dev;

class ReservationFormPage extends ConsumerStatefulWidget {
  final Reservation? reservation;

  const ReservationFormPage({super.key, this.reservation});

  @override
  ConsumerState<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends ConsumerState<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  final _specialRequestsController = TextEditingController();
  
  String? _selectedRestaurantId;
  int _numberOfGuests = 2;
  DateTime _reservationDate = DateTime.now().add(const Duration(hours: 2));
  TimeOfDay _reservationTime = TimeOfDay.now();
  bool _isLoading = false;
  ReservationStatus _status = ReservationStatus.pending;
  
  final _dateFormat = DateFormat('MMM d, yyyy');
  final _timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    
    // If editing an existing reservation, load its data
    if (widget.reservation != null) {
      _selectedRestaurantId = widget.reservation!.restaurantId;
      _numberOfGuests = widget.reservation!.numberOfGuests;
      _reservationDate = widget.reservation!.dateTime;
      _reservationTime = TimeOfDay(
        hour: widget.reservation!.dateTime.hour,
        minute: widget.reservation!.dateTime.minute
      );
      _specialRequestsController.text = widget.reservation!.specialRequests;
      _status = widget.reservation!.status;
      
      // Set the time display using the actual reservation time
      _timeController.text = DateFormat('h:mm a').format(widget.reservation!.dateTime);
    } else {
      // For new reservations, initialize with current time + 2 hours
      final initialTime = DateTime.now().add(const Duration(hours: 2));
      _reservationDate = initialTime;
      _reservationTime = TimeOfDay(
        hour: initialTime.hour,
        minute: initialTime.minute
      );
    }
    
    // Set initial values for date field
    _dateController.text = _dateFormat.format(_reservationDate);
    
    // Only set time field if it hasn't been set by edit mode
    if (_timeController.text.isEmpty) {
      final datetime = DateTime(
        _reservationDate.year,
        _reservationDate.month,
        _reservationDate.day,
        _reservationTime.hour,
        _reservationTime.minute,
      );
      _timeController.text = DateFormat('h:mm a').format(datetime);
    }
    
    dev.log('Initial time set to: ${_timeController.text} (hour: ${_reservationTime.hour})');
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _reservationDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null && picked != _reservationDate) {
      setState(() {
        _reservationDate = picked;
        _dateController.text = _dateFormat.format(_reservationDate);
      });
    }
  }

  Future<void> _selectTime() async {
    dev.log('Opening time picker with current time: ${_reservationTime.hour}:${_reservationTime.minute}');
    
    final picked = await showTimePicker(
      context: context,
      initialTime: _reservationTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _reservationTime) {
      setState(() {
        _reservationTime = picked;
        dev.log('New time picked - hour: ${picked.hour}, minute: ${picked.minute}');
        
        // Create a DateTime with the selected time for display
        final datetime = DateTime(
          _reservationDate.year,
          _reservationDate.month,
          _reservationDate.day,
          picked.hour,
          picked.minute,
        );
        _timeController.text = DateFormat('h:mm a').format(datetime);
        dev.log('Updated time display to: ${_timeController.text}');
      });
    }
  }

  DateTime _combineDateTimeFields() {
    // TimeOfDay.hour already gives us the correct 24-hour format
    final combined = DateTime(
      _reservationDate.year,
      _reservationDate.month,
      _reservationDate.day,
      _reservationTime.hour,
      _reservationTime.minute,
    );
    dev.log('Combined datetime: $combined, Hour: ${_reservationTime.hour}');
    return combined;
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() != true) return;
    if (_selectedRestaurantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a restaurant')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final dateTime = _combineDateTimeFields();
      final now = DateTime.now();
      
      if (widget.reservation == null) {
        // Creating new reservation
        final reservation = Reservation(
          id: '',
          restaurantId: _selectedRestaurantId!,
          userId: 'user123', // In a real app, get this from authentication
          dateTime: dateTime,
          numberOfGuests: _numberOfGuests,
          specialRequests: _specialRequestsController.text.trim(),
          status: _status,
          createdAt: now,
          updatedAt: now,
        );
        
        final reservationId = await ref
            .read(reservationRepositoryProvider)
            .createReservation(reservation);
            
        if (reservationId != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation created successfully')),
          );
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to create reservation')),
          );
        }
      } else {
        // Updating existing reservation
        final updatedReservation = widget.reservation!.copyWith(
          restaurantId: _selectedRestaurantId,
          dateTime: dateTime,
          numberOfGuests: _numberOfGuests,
          specialRequests: _specialRequestsController.text.trim(),
          status: _status,
        );
        
        final success = await ref
            .read(reservationRepositoryProvider)
            .updateReservation(updatedReservation);
            
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reservation updated successfully')),
          );
          Navigator.of(context).pop();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update reservation')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Stream of restaurants to populate dropdown
    final restaurantsStream = ref.watch(restaurantRepositoryProvider).getRestaurants();
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reservation == null 
            ? 'New Reservation' 
            : 'Edit Reservation'),
        actions: [
          if (widget.reservation != null)
            PopupMenuButton<ReservationStatus>(
              onSelected: (status) {
                setState(() {
                  _status = status;
                });
              },
              itemBuilder: (context) => ReservationStatus.values
                  .map((status) => PopupMenuItem(
                        value: status,
                        child: Text(status.name),
                      ))
                  .toList(),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Chip(
                  label: Text(_status.name),
                  backgroundColor: _getStatusColor(_status).withOpacity(0.2),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StreamBuilder<List<Restaurant>>(
                stream: restaurantsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator();
                  }
                  
                  final restaurants = snapshot.data ?? [];
                  if (restaurants.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No restaurants available. Please add a restaurant first.'),
                      ),
                    );
                  }

                  // If no restaurant selected yet, select the first one
                  if (_selectedRestaurantId == null && restaurants.isNotEmpty) {
                    _selectedRestaurantId = restaurants.first.id;
                  }
                  
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Restaurant',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: _selectedRestaurantId,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Select a restaurant',
                            ),
                            items: restaurants.map((restaurant) {
                              return DropdownMenuItem<String>(
                                value: restaurant.id,
                                child: Text(restaurant.name),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedRestaurantId = value;
                              });
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a restaurant';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 16),
              
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reservation Details',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _dateController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Date',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.calendar_today),
                              ),
                              onTap: _selectDate,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _timeController,
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Time',
                                border: OutlineInputBorder(),
                                suffixIcon: Icon(Icons.access_time),
                              ),
                              onTap: _selectTime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a time';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Number of Guests'),
                          const SizedBox(height: 8),
                          SegmentedButton<int>(
                            segments: List.generate(
                              10,
                              (index) => ButtonSegment<int>(
                                value: index + 1,
                                label: Text('${index + 1}'),
                              ),
                            ),
                            selected: {_numberOfGuests},
                            onSelectionChanged: (values) {
                              if (values.isNotEmpty) {
                                setState(() {
                                  _numberOfGuests = values.first;
                                });
                              }
                            },
                            showSelectedIcon: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _specialRequestsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Special Requests (optional)',
                          border: OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitForm,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.reservation == null ? 'Create Reservation' : 'Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.pending:
        return Colors.orange;
      case ReservationStatus.confirmed:
        return Colors.green;
      case ReservationStatus.cancelled:
        return Colors.red;
      case ReservationStatus.completed:
        return Colors.blue;
      case ReservationStatus.noShow:
        return Colors.purple;
    }
  }
} 
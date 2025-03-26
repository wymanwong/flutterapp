import 'package:flutter/material.dart';
import '../../../settings/data/localization/app_localizations.dart';

class PreferenceSelector extends StatefulWidget {
  final List<String> options;
  final String title;
  final List<String> selectedValues;
  final Function(List<String>) onChanged;

  const PreferenceSelector({
    Key? key,
    required this.options,
    required this.selectedValues,
    required this.onChanged,
    this.title = 'Select Preferences',
  }) : super(key: key);

  @override
  State<PreferenceSelector> createState() => _PreferenceSelectorState();
}

class _PreferenceSelectorState extends State<PreferenceSelector> {
  late List<String> _selectedValues;

  @override
  void initState() {
    super.initState();
    _selectedValues = List.from(widget.selectedValues);
  }

  @override
  void didUpdateWidget(PreferenceSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedValues != widget.selectedValues) {
      _selectedValues = List.from(widget.selectedValues);
    }
  }

  void _toggleOption(String option) {
    setState(() {
      if (_selectedValues.contains(option)) {
        _selectedValues.remove(option);
      } else {
        _selectedValues.add(option);
      }
      widget.onChanged(_selectedValues);
    });
  }

  @override
  Widget build(BuildContext context) {
    final translations = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.options.map((option) {
            final isSelected = _selectedValues.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => _toggleOption(option),
              backgroundColor: isSelected ? Theme.of(context).colorScheme.primaryContainer : null,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              showCheckmark: true,
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        if (_selectedValues.isNotEmpty)
          ElevatedButton(
            onPressed: () {
              setState(() {
                _selectedValues.clear();
                widget.onChanged(_selectedValues);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade100,
              foregroundColor: Colors.red.shade900,
              elevation: 0,
            ),
            child: Text(translations.translate('clear_all')),
          ),
      ],
    );
  }
} 
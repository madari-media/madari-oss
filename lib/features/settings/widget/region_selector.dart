import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RegionSelector extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const RegionSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<RegionSelector> createState() => _RegionSelectorState();
}

class _RegionSelectorState extends State<RegionSelector> {
  Map<String, String> _regions = {};
  String? _selectedRegion;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialValue;
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/regions.json');
      final Map<String, dynamic> jsonMap = json.decode(jsonString);
      setState(() {
        _regions = Map<String, String>.from(jsonMap);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading regions: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: _selectedRegion,
      decoration: InputDecoration(
        labelText: 'Region',
        prefixIcon: const Icon(Icons.location_on_outlined),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor:
            Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      ),
      items: _regions.entries.map((entry) {
        return DropdownMenuItem<String>(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList()
        ..sort(
          (a, b) => (a.child as Text).data!.compareTo((b.child as Text).data!),
        ),
      onChanged: (String? value) {
        setState(() => _selectedRegion = value);
        widget.onChanged(value);
      },
      hint: const Text('Select your region'),
      validator: (value) => value == null ? 'Please select a region' : null,
      isExpanded: true,
    );
  }
}

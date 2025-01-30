import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageSelector extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onChanged;

  const LanguageSelector({
    super.key,
    this.initialValue,
    required this.onChanged,
  });

  @override
  State<LanguageSelector> createState() => _LanguageSelectorState();
}

class _LanguageSelectorState extends State<LanguageSelector> {
  List<Map<String, dynamic>> _languages = [];
  String? _selectedLanguage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.initialValue;
    _loadLanguages();
  }

  Future<void> _loadLanguages() async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/tmdb_language.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      setState(() {
        _languages = List<Map<String, dynamic>>.from(jsonList);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading languages: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DropdownButtonFormField<String>(
      value: _selectedLanguage,
      decoration: InputDecoration(
        labelText: 'Language',
        prefixIcon: const Icon(Icons.language),
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
      items: _languages.map((language) {
        return DropdownMenuItem<String>(
          value: language['iso_639_1'],
          child: Text(language['english_name']),
        );
      }).toList()
        ..sort((a, b) =>
            (a.child as Text).data!.compareTo((b.child as Text).data!)),
      onChanged: (String? value) {
        setState(() => _selectedLanguage = value);
        widget.onChanged(value);
      },
      hint: const Text('Select your language'),
      validator: (value) => value == null ? 'Please select a language' : null,
      isExpanded: true,
    );
  }
}

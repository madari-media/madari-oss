import 'package:flutter/material.dart';

class SearchableLanguageDropdown extends StatefulWidget {
  final Map<String, String> languages;
  final String value;
  final String label;
  final ValueChanged<String> onChanged;

  const SearchableLanguageDropdown({
    super.key,
    required this.languages,
    required this.value,
    required this.label,
    required this.onChanged,
  });

  @override
  State<SearchableLanguageDropdown> createState() =>
      _SearchableLanguageDropdownState();
}

class _SearchableLanguageDropdownState
    extends State<SearchableLanguageDropdown> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isOpen = false;
  List<MapEntry<String, String>> _filteredLanguages = [];

  @override
  void initState() {
    super.initState();
    _filteredLanguages = widget.languages.entries.toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _filterLanguages(String query) {
    setState(() {
      _filteredLanguages = widget.languages.entries
          .where((entry) =>
              entry.value.toLowerCase().contains(query.toLowerCase()) ||
              entry.key.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _closeDropdown() {
    setState(() {
      _isOpen = false;
      _searchController.clear();
      _filteredLanguages = widget.languages.entries.toList();
    });
  }

  void _toggleDropdown() {
    setState(() {
      _isOpen = !_isOpen;
      if (!_isOpen) {
        _searchController.clear();
        _filteredLanguages = widget.languages.entries.toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleDropdown,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label,
              border: const OutlineInputBorder(),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              suffixIcon: Icon(
                _isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              ),
            ),
            child: Text(
              widget.languages[widget.value] ?? 'Select language',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        if (_isOpen)
          Card(
            elevation: 8,
            margin: const EdgeInsets.only(top: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search language...',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filterLanguages('');
                              },
                            )
                          : null,
                    ),
                    onChanged: _filterLanguages,
                  ),
                ),
                SizedBox(
                  height: 250,
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    itemCount: _filteredLanguages.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredLanguages[index];
                      final isSelected = entry.key == widget.value;

                      return ListTile(
                        dense: true,
                        title: Text(entry.value),
                        subtitle: Text(entry.key),
                        selected: isSelected,
                        tileColor: isSelected
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        onTap: () {
                          widget.onChanged(entry.key);
                          _closeDropdown();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

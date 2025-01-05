import 'package:flutter/material.dart';
import 'package:madari_client/features/connection/services/stremio_service.dart';

import '../../service/base_connection_service.dart';

typedef FilterCallback = void Function(List<ConnectionFilterItem> item);

class InlineFilters extends StatefulWidget {
  final List<ConnectionFilter<dynamic>> filters;
  final FilterCallback filterCallback;

  const InlineFilters({
    super.key,
    required this.filters,
    required this.filterCallback,
  });

  @override
  State<InlineFilters> createState() => _InlineFiltersState();
}

class _InlineFiltersState extends State<InlineFilters> {
  final Map<String, dynamic> _selectedValues = {};

  List<ConnectionFilterItem> generateFilterItem() {
    final List<ConnectionFilterItem> items = [];

    for (final item in _selectedValues.keys) {
      items.add(
        ConnectionFilterItem(title: item, value: _selectedValues[item]!),
      );
    }

    return items;
  }

  onChange() {
    widget.filterCallback(generateFilterItem());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: widget.filters
            .where((filter) => filter.type == ConnectionFilterType.options)
            .map((filter) {
          final isSelected = _selectedValues.containsKey(filter.title);

          return Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: InputChip(
                label: Text(
                  (isSelected ? _selectedValues[filter.title] : filter.title)
                      .toString()
                      .capitalize(),
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color,
                  ),
                ),
                selected: isSelected,
                onPressed: () {
                  if (isSelected) {
                    setState(() {
                      _selectedValues.remove(filter.title);
                    });

                    onChange();
                  } else {
                    _showOptionsDialog(filter);
                  }
                },
                deleteIcon: isSelected
                    ? const Icon(
                        Icons.close,
                      )
                    : null,
                onDeleted: isSelected
                    ? () {
                        setState(() {
                          _selectedValues.remove(filter.title);

                          onChange();
                        });
                      }
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showOptionsDialog(ConnectionFilter<dynamic> filter) async {
    final selectedValue = await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(filter.title),
          children: (filter.values ?? []).map((value) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, value);
              },
              child: Text(value.toString()),
            );
          }).toList(),
        );
      },
    );

    if (selectedValue != null) {
      setState(() {
        _selectedValues[filter.title] = selectedValue;
      });

      onChange();
    }
  }
}

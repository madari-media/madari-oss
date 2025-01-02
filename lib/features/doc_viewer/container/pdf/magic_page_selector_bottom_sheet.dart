import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:pocketbase/pocketbase.dart';

class MagicPageSelectorBottomSheet extends StatelessWidget {
  final RecordModel item;
  final PdfViewerController controller;

  const MagicPageSelectorBottomSheet({
    super.key,
    required this.item,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select 📃"),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.file_present),
            title: const Text('Current Page'),
            subtitle: Text('Page ${controller.pageNumber}'),
            onTap: () {
              Navigator.pop(context, [controller.pageNumber!]);
            },
          ),
          ListTile(
            leading: const Icon(Icons.filter_frames),
            title: const Text('Page Range'),
            subtitle: const Text('Select a range of pages'),
            onTap: () async {
              final RangeValues? result = await showDialog<RangeValues>(
                context: context,
                builder: (BuildContext context) {
                  return PageRangeDialog(
                    maxPages: controller.pageCount,
                  );
                },
              );

              if (result != null) {
                final List<int> pages = List.generate(
                  (result.end - result.start + 1).toInt(),
                  (index) => index + result.start.toInt(),
                );
                if (context.mounted) Navigator.pop(context, pages);
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.all_inclusive),
            title: const Text('All Pages'),
            subtitle: Text('Total ${controller.pageCount} pages'),
            onTap: () {
              final List<int> allPages = List.generate(
                controller.pageCount,
                (index) => index + 1,
              );
              Navigator.pop(context, allPages);
            },
          ),
        ],
      ),
    );
  }
}

// Additional dialog for page range selection
class PageRangeDialog extends StatefulWidget {
  final int maxPages;

  const PageRangeDialog({
    super.key,
    required this.maxPages,
  });

  @override
  State<PageRangeDialog> createState() => _PageRangeDialogState();
}

class _PageRangeDialogState extends State<PageRangeDialog> {
  late RangeValues _currentRangeValues;

  @override
  void initState() {
    super.initState();
    _currentRangeValues = RangeValues(1, widget.maxPages.toDouble());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Page Range'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RangeSlider(
            values: _currentRangeValues,
            min: 1,
            max: widget.maxPages.toDouble(),
            divisions: widget.maxPages - 1,
            labels: RangeLabels(
              _currentRangeValues.start.round().toString(),
              _currentRangeValues.end.round().toString(),
            ),
            onChanged: (RangeValues values) {
              setState(() {
                _currentRangeValues = values;
              });
            },
          ),
          Text(
            'Pages ${_currentRangeValues.start.round()} to ${_currentRangeValues.end.round()}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _currentRangeValues),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

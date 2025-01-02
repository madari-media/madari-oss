import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:madari_client/engine/engine.dart';
import 'package:madari_client/utils/ocr_file.dart';

class ChatAction extends StatefulWidget {
  final void Function({
    String? actionId,
    Map<String, String>? files,
  }) onClose;
  final String? actionId;

  const ChatAction({
    super.key,
    required this.onClose,
    this.actionId,
  });

  @override
  State<ChatAction> createState() => _ChatActionState();
}

class _ChatActionState extends State<ChatAction> {
  final List<Map<String, String>> _commandItems = [
    {
      'id': 'file-upload',
      'title': 'Upload File',
      'description': 'Share a document or image',
    },
  ];
  String? content;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    AppEngine.engine.pb
        .collection("ai_action")
        .getList(perPage: 50)
        .then((docs) {
      if (!mounted) {
        return;
      }

      for (final item in docs.items) {
        _commandItems.add({
          'id': item.id,
          'title': item.getStringValue("title"),
          'description': item.getStringValue("description"),
        });
      }

      setState(() {
        _isLoading = false;
      });
    }).catchError((err) {
      setState(() {
        _isLoading = false;
      });
    });
  }

  void attachItem() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: [
        "pdf",
        "png",
        "bpm",
        "jpeg",
        "jpg",
      ],
    );

    if ((result?.count ?? 0) == 0) {
      widget.onClose();
      return;
    }

    final images = await ocrFiles(result!.files);
    Map<String, String> files = {};

    for (final (index, image) in images.indexed) {
      files[result.files[index].name] = image;
    }

    widget.onClose(
      files: files,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Material(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.grey.withOpacity(0.2),
            ),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: _commandItems.length + (_isLoading ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _commandItems.length) {
                return Container(
                  padding: const EdgeInsets.only(
                    bottom: 24,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final item = _commandItems[index];
              return ListTile(
                selected: item['id'] == widget.actionId,
                leading: Icon(
                  item['id'] == 'file-upload'
                      ? Icons.file_present
                      : Icons.chat_bubble_outline,
                ),
                title: Text(item['title'] ?? ''),
                subtitle: Text(
                  item['description'] ?? '',
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  if (item['id'] == 'file-upload') {
                    return attachItem();
                  }

                  widget.onClose(
                    actionId: item['id'],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

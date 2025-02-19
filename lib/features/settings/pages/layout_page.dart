import 'package:cached_query/cached_query.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:madari_client/features/home/pages/home_page.dart';
import 'package:madari_client/features/widgetter/plugins/stremio/utils/size.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../pocketbase/service/pocketbase.service.dart';
import '../../widgetter/plugin_base.dart';
import '../../widgetter/service/home_layout_service.dart';
import '../../widgetter/types/widget_gallery.dart';

final _logger = Logger('LayoutPage');

class LayoutPage extends StatefulWidget {
  const LayoutPage({
    super.key,
  });

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> with TickerProviderStateMixin {
  final List<PresetWidgetConfig> widgets = [];
  final List<LayoutWidgetConfig> layoutWidgets = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();
  bool isDragging = false;
  double dragHeight = 320;
  final double _minCellWidth = 150;
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  final appProfile = AppPocketBaseService.instance.engine.profileService;

  Query<List<RecordModel>>? query;

  @override
  void initState() {
    super.initState();
    _logger.info('Initializing LayoutPage');

    (() async {
      final query = await AppPocketBaseService.instance.engine.profileService
          .getCurrentProfile();

      this.query = Query(
        key: "home_layout${query!.id}",
        queryFn: () async {
          return await AppPocketBaseService.instance.pb
              .collection('home_layout')
              .getFullList(
                sort: 'order',
                filter:
                    'profiles = \'${(await appProfile.getCurrentProfile())!.id}\'',
              );
        },
      );

      setState(() {});
    })();

    loadData();
  }

  void _showError(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: loadData,
        ),
      ),
    );
  }

  void _showSuccess(String message) {
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> loadData() async {
    try {
      setState(() => _isLoading = true);
      final result = PluginRegistry.instance.getAvailablePlugins();
      final presets = await Future.wait(
        result.map((item) => item.presets()),
      );
      widgets.clear();
      for (var value in presets) {
        widgets.addAll(value);
      }

      final layoutItems = await HomeLayoutService.instance.loadLayoutWidgets();
      layoutWidgets.clear();
      layoutWidgets.addAll(layoutItems);

      _logger.info(
        'Loaded ${widgets.length} preset widgets and ${layoutWidgets.length} layout widgets',
      );

      setState(() {});
    } catch (e) {
      _logger.severe('Error loading data', e);
      _showError('Failed to load widgets. Please check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addWidget(PresetWidgetConfig preset) async {
    try {
      _logger.info('Adding widget ${preset.title}');

      final userId = AppPocketBaseService.instance.pb.authStore.record!.id;
      final newWidget = LayoutWidgetConfig.fromPreset(
        preset,
        userId,
        layoutWidgets.length,
      );

      final success = await HomeLayoutService.instance.saveLayoutWidget(
        newWidget,
      );

      query?.refetch();

      if (success) {
        await loadData();
        _showSuccess('Added ${preset.title} widget');
      } else {
        _showError('Failed to add widget. Please try again.');
      }
    } catch (e) {
      _logger.severe('Error adding widget', e);
      _showError('Failed to add widget. Please check your connection.');
    }
  }

  Future<void> _removeWidget(LayoutWidgetConfig widget) async {
    try {
      _logger.info('Removing widget ${widget.id}');
      final success =
          await HomeLayoutService.instance.deleteLayoutWidget(widget.id);
      if (success) {
        setState(() {
          layoutWidgets.remove(widget);
        });
        await HomeLayoutService.instance.updateLayoutOrder(layoutWidgets);
        query?.refetch();
        _showSuccess('Removed widget successfully');
      } else {
        _showError('Failed to remove widget. Please try again.');
      }
    } catch (e) {
      _logger.severe('Error removing widget', e);
      _showError('Failed to remove widget. Please check your connection.');
    }
  }

  Future<void> _addAllWidgets() async {
    try {
      _logger.info('Adding all widgets');

      final userId = AppPocketBaseService.instance.pb.authStore.record!.id;
      int successCount = 0;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      for (var preset in widgets) {
        final newWidget = LayoutWidgetConfig.fromPreset(
          preset,
          userId,
          layoutWidgets.length + successCount,
        );

        final success =
            await HomeLayoutService.instance.saveLayoutWidget(newWidget);

        query?.refetch();
        if (success) {
          successCount++;
        }
      }

      Navigator.of(context).pop();

      if (successCount > 0) {
        await loadData();
        _showSuccess('Added $successCount widgets successfully');
      } else {
        _showError('Failed to add widgets. Please try again.');
      }
    } catch (e) {
      Navigator.of(context).pop();
      _logger.severe('Error adding all widgets', e);
      _showError('Failed to add widgets. Please check your connection.');
    }
  }

  Future<void> _reorderWidgets(int oldIndex, int newIndex) async {
    try {
      _logger.info('Reordering widget from $oldIndex to $newIndex');
      setState(() {
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }
        final item = layoutWidgets.removeAt(oldIndex);
        layoutWidgets.insert(newIndex, item);
      });

      final success =
          await HomeLayoutService.instance.updateLayoutOrder(layoutWidgets);
      query?.refetch();
      if (!success) {
        _showError('Failed to save new order. Please try again.');
      }
    } catch (e) {
      _logger.severe('Error reordering widgets', e);
      _showError('Failed to reorder widgets. Please check your connection.');
    }
  }

  Widget _buildListItem(LayoutWidgetConfig widget, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      key: ValueKey(widget.id),
      child: Dismissible(
        key: ValueKey(widget.id),
        direction: DismissDirection.endToStart,
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        onDismissed: (direction) => _removeWidget(widget),
        child: InkWell(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.widgets_outlined,
                      size: 22,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (widget.config.containsKey("description"))
                        Text(
                          widget.config['description'],
                          style: Theme.of(context).textTheme.titleSmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: ReorderableDragStartListener(
                    index: index,
                    child: Icon(
                      Icons.drag_handle,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWidgetPreview(PresetWidgetConfig widget) {
    final preview = Card(
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 1.5,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withAlpha(200),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.widgets_outlined,
                        size: 22,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(180),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          widget.description,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Tooltip(
      message: 'Drag to add ${widget.title}',
      child: LongPressDraggable<PresetWidgetConfig>(
        data: widget,
        delay: const Duration(milliseconds: 150),
        feedback: Material(
          elevation: 8,
          child: SizedBox(
            width: _minCellWidth,
            child: preview,
          ),
        ),
        child: GestureDetector(
          onTap: () => _addWidget(widget),
          child: preview,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ScaffoldMessenger(
      key: _scaffoldKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Home Layout'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh widgets',
              onPressed: loadData,
            ),
            IconButton(
              icon: const Icon(Icons.preview),
              tooltip: 'Preview',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (context) => const HomePage(),
                );
              },
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: DragTarget<PresetWidgetConfig>(
                onAcceptWithDetails: (item) => _addWidget(item.data),
                builder: (context, candidateData, rejectedData) {
                  return layoutWidgets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.drag_indicator,
                                size: 48,
                                color:
                                    theme.colorScheme.onSurface.withAlpha(100),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Drag widgets here or tap to add them',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(150),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ReorderableListView.builder(
                          scrollController: _scrollController,
                          itemCount: layoutWidgets.length,
                          itemBuilder: (context, index) =>
                              _buildListItem(layoutWidgets[index], index),
                          onReorder: _reorderWidgets,
                          buildDefaultDragHandles: false,
                        );
                },
              ),
            ),
            GestureDetector(
              onVerticalDragUpdate: _handleDragUpdate,
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2.5),
                ),
                margin: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
            Container(
              height: dragHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(
                          'Available Widgets',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(200),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${widgets.length})',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(150),
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () {
                            _addAllWidgets();
                          },
                          icon: const Text("Add all to Home"),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount:
                            StremioCardSize.getSize(context).columns,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                      ),
                      itemCount: widgets.length,
                      itemBuilder: (context, index) {
                        final item = widgets[index];
                        return _buildWidgetPreview(item);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    setState(() {
      dragHeight = (dragHeight - details.delta.dy).clamp(200.0, 600.0);
    });
  }
}

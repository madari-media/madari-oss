import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

import '../../../engine/engine.dart';
import '../container/collection_list_item_list.dart';

class CollectionListModel {
  final String id;
  final String collectionId;
  final String name;
  final String? description;
  final int order;
  final String? background;
  final DateTime created;
  final DateTime updated;
  final String userId;
  final bool isPublic;

  CollectionListModel({
    required this.id,
    required this.collectionId,
    required this.name,
    this.description,
    required this.order,
    this.background,
    required this.created,
    required this.updated,
    required this.userId,
    required this.isPublic,
  });

  factory CollectionListModel.fromRecord(RecordModel record) {
    return CollectionListModel(
      id: record.id,
      collectionId: record.collectionId,
      name: record.data['name'],
      description: record.data['description'],
      order: record.data['order'],
      background: record.data['background'],
      created: DateTime.parse(record.get("created")),
      updated: DateTime.parse(record.get("updated")),
      userId: record.data['user'],
      isPublic: record.data['isPublic'],
    );
  }
}

class CollectionCard extends StatefulWidget {
  final CollectionListModel collection;
  final double width;

  const CollectionCard({
    super.key,
    required this.collection,
    this.width = 480,
  });

  @override
  State<CollectionCard> createState() => _CollectionCardState();
}

class _CollectionCardState extends State<CollectionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: widget.width,
          height: widget.width * .6,
          margin: const EdgeInsets.all(12),
          child: Card(
            elevation: 8,
            shadowColor: Colors.black26,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image or Gradient
                _buildBackground(),

                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Spacer(),
                      // Collection Name
                      Text(
                        widget.collection.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              offset: Offset(1, 1),
                              blurRadius: 3,
                              color: Colors.black45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      if (widget.collection.description != null)
                        Text(
                          widget.collection.description!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black45,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 16),
                      // Metadata Row
                      Row(
                        children: [
                          _buildMetadataChip(
                            Icons.calendar_today,
                            _formatDate(widget.collection.updated),
                          ),
                          const Spacer(),
                          _buildInteractionButton(),
                        ],
                      ),
                    ],
                  ),
                ),

                // Optional: Add a subtle overlay pattern
                CustomPaint(
                  painter: PatternPainter(),
                ),

                // Material Ink Effect for Ripple
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (ctx) => CollectionListItemsScreen(
                            listId: widget.collection.id,
                            title: widget.collection.name,
                            isPublic: widget.collection.isPublic,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (widget.collection.background != null) {
      return Hero(
        tag: 'collection-${widget.collection.id}',
        child: Image.network(
          '${AppEngine.engine.pb.baseURL}/api/files/${widget.collection.collectionId}/${widget.collection.id}/${widget.collection.background}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildFallbackBackground(),
        ),
      );
    }
    return _buildFallbackBackground();
  }

  Widget _buildFallbackBackground() {
    // Generate a unique but consistent color based on collection ID
    final color = Color(
      (widget.collection.id.hashCode & 0xFFFFFF) | 0xFF000000,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            Color.lerp(color, Colors.white, 0.2)!,
          ],
        ),
      ),
      child: const Icon(
        Icons.collections,
        size: 80,
        color: Colors.white24,
      ),
    );
  }

  Widget _buildMetadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: const Icon(Icons.arrow_forward, color: Colors.black87),
        visualDensity: VisualDensity.compact,
        onPressed: () {
          // Handle interaction
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Custom Pattern Painter for subtle overlay
class PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (var i = 0; i < size.width; i += 20) {
      for (var j = 0; j < size.height; j += 20) {
        canvas.drawCircle(Offset(i.toDouble(), j.toDouble()), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

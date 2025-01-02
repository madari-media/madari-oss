class PlaylistItem {
  final String id;
  final String collectionId;
  final String collectionName;
  final String playlistId;
  final String libraryId;
  final Map<String, dynamic> item;
  final String itemId;
  final DateTime created;
  final DateTime updated;

  PlaylistItem({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.playlistId,
    required this.libraryId,
    required this.item,
    required this.itemId,
    required this.created,
    required this.updated,
  });

  factory PlaylistItem.fromJson(Map<String, dynamic> json) {
    return PlaylistItem(
      id: json['id'],
      collectionId: json['collectionId'],
      collectionName: json['collectionName'],
      playlistId: json['playlist'],
      libraryId: json['library'],
      item: json['item'],
      itemId: json['item_id'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collectionId': collectionId,
    'collectionName': collectionName,
    'playlist': playlistId,
    'library': libraryId,
    'item': item,
    'item_id': itemId,
    'created': created.toIso8601String(),
    'updated': updated.toIso8601String(),
  };
}

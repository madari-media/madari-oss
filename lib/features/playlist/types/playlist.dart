class Playlist {
  final String id;
  final String collectionId;
  final String collectionName;
  final String name;
  final String userId;
  final DateTime created;
  final DateTime updated;

  Playlist({
    required this.id,
    required this.collectionId,
    required this.collectionName,
    required this.name,
    required this.userId,
    required this.created,
    required this.updated,
  });

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'],
      collectionId: json['collectionId'],
      collectionName: json['collectionName'],
      name: json['name'],
      userId: json['user'],
      created: DateTime.parse(json['created']),
      updated: DateTime.parse(json['updated']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'collectionId': collectionId,
    'collectionName': collectionName,
    'name': name,
    'user': userId,
    'created': created.toIso8601String(),
    'updated': updated.toIso8601String(),
  };
}

class CollectionItemModel {
  final String id;
  final String name;
  String? file;
  final String listId;
  final String userId;
  final dynamic content;
  final String type;
  final DateTime created;
  final DateTime updated;

  CollectionItemModel({
    required this.id,
    required this.name,
    this.file,
    required this.listId,
    required this.userId,
    this.content,
    required this.type,
    required this.created,
    required this.updated,
  });

  factory CollectionItemModel.fromJson(Map<String, dynamic> json) {
    try {
      return CollectionItemModel(
        id: json['id'],
        name: json['name'],
        file: json['file'],
        listId: json['list'],
        userId: json['user'],
        content: json['content'],
        type: json['type'],
        created: DateTime.parse(json['created']),
        updated: DateTime.parse(json['updated']),
      );
    } catch (e, stack) {
      print(e);
      print(stack);
      rethrow;
    }
  }
}

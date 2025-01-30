class HomeLayoutModel {
  final String id;
  final Map<String, dynamic> config;
  final int order;
  final String type;
  final String pluginId;

  HomeLayoutModel({
    required this.id,
    required this.config,
    required this.order,
    required this.type,
    required this.pluginId,
  });

  factory HomeLayoutModel.fromJson(Map<String, dynamic> json) {
    return HomeLayoutModel(
      id: json['id'] as String,
      config: json['config'] as Map<String, dynamic>,
      order: json['order'] as int,
      type: json['type'] as String,
      pluginId: json['plugin_id'] as String,
    );
  }

  toJson() {
    return {
      "id": id,
      "config": config,
      "order": order,
      "type": type,
      "pluginId": pluginId,
    };
  }
}

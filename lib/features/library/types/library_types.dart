import 'dart:convert';

import 'package:madari_client/features/settings/service/selected_profile.dart';

import '../../pocketbase/service/pocketbase.service.dart';

class ListModel {
  final String id;
  final String name;
  final String description;
  final int order;
  final bool sync;
  final String? traktListId;

  ListModel({
    required this.id,
    required this.name,
    required this.description,
    required this.order,
    required this.sync,
    this.traktListId,
  });

  factory ListModel.fromJson(Map<String, dynamic> json) {
    return ListModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      order: json['order'],
      sync: json['sync'],
      traktListId: json['trakt_list_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'order': order,
      'sync': sync,
      'trakt_list_id': traktListId,
    };
  }

  ListModel copyWith({
    String? name,
    String? description,
    int? order,
    bool? sync,
    String? traktListId,
  }) {
    return ListModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      order: order ?? this.order,
      sync: sync ?? this.sync,
      traktListId: traktListId ?? this.traktListId,
    );
  }
}

class ListItemModel {
  final String id;
  final String type;
  final String imdbId;
  final Map<String, dynamic> ids;
  final String title;
  final String description;
  final String poster;
  final double rating;

  ListItemModel({
    required this.id,
    required this.type,
    required this.imdbId,
    required this.ids,
    required this.title,
    required this.description,
    required this.poster,
    required this.rating,
  });

  factory ListItemModel.fromJson(Map<String, dynamic> json) {
    return ListItemModel(
      id: json['id'],
      type: json['type'],
      imdbId: json['imdb_id'],
      ids: json['ids'] is String ? jsonDecode(json['ids']) : json['ids'],
      title: json['title'],
      description: json['description'],
      poster: json['poster'],
      rating: (json['rating'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'imdb_id': imdbId,
      'ids': ids is String ? ids : jsonEncode(ids),
      'title': title,
      'description': description,
      'poster': poster,
      'rating': rating,
    };
  }
}

class CreateListRequest {
  final String name;
  final String description;

  CreateListRequest({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'order': 0,
      'sync': false,
      'user': AppPocketBaseService.instance.pb.authStore.record!.id,
      'account_profile': SelectedProfileService.instance.selectedProfileId,
    };
  }
}

class UpdateListRequest {
  final String name;
  final String description;

  UpdateListRequest({
    required this.name,
    required this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
    };
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:json_annotation/json_annotation.dart';
import 'package:madari_client/features/pocketbase/service/pocketbase.service.dart';
import 'package:madari_client/features/settings/service/selected_profile.dart';
import 'package:url_launcher/url_launcher_string.dart';

part 'zeku_service.g.dart';

@JsonSerializable()
class ZekuServiceItem {
  final String name;
  final String logo;
  final String website;
  final bool enabled;

  ZekuServiceItem({
    required this.name,
    required this.logo,
    required this.website,
    required this.enabled,
  });

  factory ZekuServiceItem.fromJson(Map<String, dynamic> json) {
    return _$ZekuServiceItemFromJson(json);
  }

  Map<String, dynamic> toJson() => _$ZekuServiceItemToJson(this);
}

class ZekuService {
  static final ZekuService _instance = ZekuService._internal();
  final pocketbase = AppPocketBaseService.instance.pb;
  final String endpoint =
      kDebugMode ? 'http://100.64.0.1:3001' : 'https://zeku.madari.media';

  authenticate() async {
    final result = await http.get(
      Uri.parse(
        "$endpoint/${SelectedProfileService.instance.selectedProfileId}/session",
      ),
      headers: {
        "Authorization":
            "Bearer ${AppPocketBaseService.instance.pb.authStore.token}",
      },
    );

    final res = jsonDecode(result.body);

    final id = res["data"]["id"];

    await launchUrlString(
      "$endpoint/$id/trakt/auth",
    );
  }

  disconnect() async {}

  factory ZekuService() {
    return _instance;
  }

  ZekuService._internal();

  static ZekuService get instance => _instance;

  final List<ZekuServiceItem> _services = [];

  Future<List<ZekuServiceItem>> getServices() async {
    try {
      final result = await http.get(
        Uri.parse(
          "$endpoint/${SelectedProfileService.instance.selectedProfileId}/services",
        ),
        headers: {
          "Authorization":
              "Bearer ${AppPocketBaseService.instance.pb.authStore.token}",
        },
      );

      final bodyParsed = jsonDecode(result.body);

      final List<ZekuServiceItem> returnValue = [];

      for (final item in bodyParsed["data"]) {
        returnValue.add(ZekuServiceItem.fromJson(item));
      }

      return returnValue;
    } catch (e) {
      throw Exception('Failed to fetch services: $e');
    }
  }

  Future<bool> removeSession(String service) async {
    final result = await http.get(
      Uri.parse(
        "$endpoint/${SelectedProfileService.instance.selectedProfileId}/${service.toLowerCase()}/revoke",
      ),
      headers: {
        "Authorization":
            "Bearer ${AppPocketBaseService.instance.pb.authStore.token}",
      },
    );

    if (result.statusCode != 200) {
      return false;
    }

    return true;
  }
}

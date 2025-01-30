import 'package:madari_client/features/streamio_addons/models/stremio_base_types.dart';

enum ContentType { movie, series, channel, tv }

class SocialLinks {
  final String? instagram;
  final String? twitter;
  final String? facebook;
  final String? website;

  const SocialLinks({
    this.instagram,
    this.twitter,
    this.facebook,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      instagram: json['instagram'] as String?,
      twitter: json['twitter'] as String?,
      facebook: json['facebook'] as String?,
      website: json['website'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'instagram': instagram,
        'twitter': twitter,
        'facebook': facebook,
        'website': website,
      };
}

class CastMember {
  final String id;
  final String name;
  final String? profilePath;
  final String? biography;
  final String? birthDate;
  final String? birthPlace;
  final SocialLinks socialLinks;
  final List<Meta> knownFor;
  final double? popularity;
  final String? department;
  final String? character;

  const CastMember({
    required this.id,
    required this.name,
    this.profilePath,
    this.biography,
    this.birthDate,
    this.birthPlace,
    this.socialLinks = const SocialLinks(),
    this.knownFor = const [],
    this.popularity,
    this.department,
    this.character,
  });

  factory CastMember.fromJson(Map<String, dynamic> json) {
    return CastMember(
      id: json['id'] as String,
      name: json['name'] as String,
      profilePath: json['profilePath'] as String?,
      biography: json['biography'] as String?,
      birthDate: json['birthDate'] as String?,
      birthPlace: json['birthPlace'] as String?,
      socialLinks: SocialLinks.fromJson(json['socialLinks'] ?? {}),
      knownFor: (json['knownFor'] as List<dynamic>?)
              ?.map((e) => Meta.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      popularity: json['popularity'] as double?,
      department: json['department'] as String?,
      character: json['character'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'profile_path': profilePath,
        'biography': biography,
        'birth_date': birthDate,
        'birth_place': birthPlace,
        'social_links': socialLinks.toJson(),
        'known_for': knownFor.map((e) => e.toJson()).toList(),
        'popularity': popularity,
        'department': department,
        'character': character,
      };
}

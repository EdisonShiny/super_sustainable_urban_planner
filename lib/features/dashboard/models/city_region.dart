class CityRegion {
  const CityRegion({
    required this.id,
    required this.name,
    this.country,
    this.region,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String name;
  final String? country;
  final String? region;
  final double? latitude;
  final double? longitude;

  String get displayName {
    final parts = <String>[];
    if (name.isNotEmpty) parts.add(name);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  factory CityRegion.fromMap(Map<String, dynamic> map) {
    return CityRegion(
      id: map['id'] as String,
      name: map['name'] as String,
      country: map['country'] as String?,
      region: map['region'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'country': country,
      'region': region,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

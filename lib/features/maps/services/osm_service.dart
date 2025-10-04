import 'dart:convert';
import 'package:http/http.dart' as http;

class OsmSearchResult {
  const OsmSearchResult({
    required this.id,
    required this.name,
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.country,
    this.region,
  });

  final String id;
  final String name;
  final String displayName;
  final String? country;
  final String? region;
  final double latitude;
  final double longitude;

  static OsmSearchResult? fromJson(Map<String, dynamic> json) {
    final lat = double.tryParse(json['lat']?.toString() ?? '');
    final lon = double.tryParse(json['lon']?.toString() ?? '');
    if (lat == null || lon == null) {
      return null;
    }

    final address = (json['address'] as Map<String, dynamic>?) ?? {};
    final structuredName =
        (json['name'] as String?) ??
        address['city'] as String? ??
        address['town'] as String? ??
        address['village'] as String? ??
        address['hamlet'] as String? ??
        address['municipality'] as String? ??
        address['county'] as String?;

    final displayName = (json['display_name'] as String?)?.trim();
    final region =
        (address['state'] ?? address['region'] ?? address['county']) as String?;
    final country = address['country'] as String?;

    final resolvedName =
        (structuredName ??
            (displayName != null && displayName.isNotEmpty
                ? displayName.split(',').first.trim()
                : null)) ??
        'Unknown location';

    final rawId = json['place_id']?.toString();
    var fallbackId = resolvedName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    fallbackId = fallbackId.replaceAll(RegExp(r'^-+|-+$'), '');
    if (fallbackId.isEmpty) {
      fallbackId = resolvedName.hashCode.toRadixString(16);
    }
    final id = 'osm-${rawId ?? fallbackId}';

    return OsmSearchResult(
      id: id,
      name: resolvedName,
      displayName: displayName ?? resolvedName,
      region: region?.isNotEmpty == true ? region : null,
      country: country?.isNotEmpty == true ? country : null,
      latitude: lat,
      longitude: lon,
    );
  }
}

class OsmService {
  const OsmService._();

  static final OsmService instance = OsmService._();

  static const String attribution = '(c) OpenStreetMap contributors';
  static const String tileTemplate =
      'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> subdomains = ['a', 'b', 'c'];

  static const _userAgent =
      'nasa-space-app-testing/1.0 (support@nasa-space-app-testing.local)';
  static const _baseAuthority = 'nominatim.openstreetmap.org';

  Future<List<OsmSearchResult>> searchPlaces(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final uri = Uri.https(_baseAuthority, '/search', {
      'format': 'jsonv2',
      'limit': '5',
      'q': trimmed,
      'addressdetails': '1',
    });

    try {
      final response = await http.get(
        uri,
        headers: {'User-Agent': _userAgent, 'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return const [];
      }

      final payload = jsonDecode(response.body);
      if (payload is! List) {
        return const [];
      }

      final results = <OsmSearchResult>[];
      for (final item in payload) {
        if (item is Map<String, dynamic>) {
          final parsed = OsmSearchResult.fromJson(item);
          if (parsed != null) {
            results.add(parsed);
          }
        }
      }
      return results;
    } catch (_) {
      return const [];
    }
  }
}

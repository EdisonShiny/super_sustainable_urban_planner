import 'package:flutter/foundation.dart';
import '../../../core/services/supabase_client.dart';
import '../../auth/models/user_profile.dart';
import '../models/city_region.dart';
import '../../maps/services/osm_service.dart';
import 'demo_data_store.dart';

class CityRepository {
  CityRepository._();

  static final CityRepository instance = CityRepository._();

  final ValueNotifier<CityRegion?> _selectedCity = ValueNotifier<CityRegion?>(
    null,
  );

  ValueListenable<CityRegion?> get selectedCity => _selectedCity;

  final OsmService _osmService = OsmService.instance;

  Future<CityRegion?> loadDefaultCity(UserProfile profile) async {
    final cached = _selectedCity.value;
    if (cached != null) {
      return cached;
    }

    final demoStore = DemoDataStore.instance;
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('cities')
            .select('id, name, country, region, latitude, longitude')
            .ilike('name', '%${profile.cityRegion.trim()}%')
            .maybeSingle();

        if (response != null) {
          final city = CityRegion.fromMap(response);
          _selectedCity.value = city;
          return city;
        }
      } catch (_) {
        // Ignore errors and fall back to demo data.
      }
    }

    final demoMatch = demoStore.matchCity(profile.cityRegion);
    if (demoMatch != null) {
      _selectedCity.value = demoMatch;
      return demoMatch;
    }

    final geocodedMatches = await _osmService.searchPlaces(profile.cityRegion);
    if (geocodedMatches.isNotEmpty) {
      final match = geocodedMatches.first;
      final geocodedCity = CityRegion(
        id: match.id,
        name: match.name,
        region: match.region,
        country: match.country,
        latitude: match.latitude,
        longitude: match.longitude,
      );
      _selectedCity.value = geocodedCity;
      return geocodedCity;
    }

    final fallback = CityRegion(
      id: profile.cityRegion,
      name: profile.cityRegion,
      latitude: 0,
      longitude: 0,
    );
    _selectedCity.value = fallback;
    return fallback;
  }

  Future<List<CityRegion>> searchCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }

    final results = <CityRegion>[];
    final seen = <String>{};

    void addIfNew(CityRegion city) {
      if (seen.add(city.id)) {
        results.add(city);
      }
    }

    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('cities')
            .select('id, name, country, region, latitude, longitude')
            .ilike('name', '%$trimmed%');
        for (final item in response.cast<Map<String, dynamic>>()) {
          addIfNew(CityRegion.fromMap(item));
        }
      } catch (_) {
        // Ignore errors and fall back to local/demo data.
      }
    }

    for (final city in DemoDataStore.instance.searchCities(trimmed)) {
      addIfNew(city);
    }

    final geocoded = await _osmService.searchPlaces(trimmed);
    for (final match in geocoded) {
      addIfNew(
        CityRegion(
          id: match.id,
          name: match.name,
          region: match.region,
          country: match.country,
          latitude: match.latitude,
          longitude: match.longitude,
        ),
      );
    }
    return results;
  }

  void selectCity(CityRegion city) {
    _selectedCity.value = city;
  }

  void clearSelection() {
    _selectedCity.value = null;
  }
}

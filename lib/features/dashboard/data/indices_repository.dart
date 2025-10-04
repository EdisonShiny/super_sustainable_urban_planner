import '../../../core/services/supabase_client.dart';
import '../models/index_breakdown.dart';
import '../models/index_score.dart';
import 'demo_data_store.dart';

class IndicesRepository {
  IndicesRepository._();

  static final IndicesRepository instance = IndicesRepository._();

  Future<List<IndexScore>> fetchLatestScores(String cityId) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('index_scores')
            .select('type, value, timestamp')
            .eq('city_id', cityId)
            .order('timestamp', ascending: false);

        if (response.isNotEmpty) {
          final typeToScore = <indexType, IndexScore>{};
          for (final entry in response.cast<Map<String, dynamic>>()) {
            final score = IndexScore.fromMap(entry);
            typeToScore.putIfAbsent(score.type, () => score);
          }

          final scores = typeToScore.values.toList()
            ..sort((a, b) => a.type.sortOrder.compareTo(b.type.sortOrder));
          return scores;
        }
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    return DemoDataStore.instance.latestScoresFor(cityId);
  }

  Future<List<IndexScore>> fetchSeries(String cityId, DateTime from) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('index_scores')
            .select('type, value, timestamp')
            .eq('city_id', cityId)
            .gte('timestamp', from.toIso8601String())
            .order('timestamp');
        if (response.isNotEmpty) {
          return response
              .cast<Map<String, dynamic>>()
              .map(IndexScore.fromMap)
              .toList();
        }
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    return DemoDataStore.instance.seriesFor(cityId, from);
  }

  Future<List<IndexBreakdown>> fetchBreakdown(
    String cityId,
    indexType type,
  ) async {
    final client = maybeSupabaseClient;
    if (client != null) {
      try {
        final response = await client
            .from('index_breakdowns')
            .select('factor, percentage')
            .eq('city_id', cityId)
            .eq('index_type', type.label.toLowerCase())
            .order('percentage', ascending: false);
        if (response.isNotEmpty) {
          return response
              .cast<Map<String, dynamic>>()
              .map(IndexBreakdown.fromMap)
              .toList();
        }
      } catch (_) {
        // Ignore errors and fall back to local demo data.
      }
    }

    final breakdowns = await DemoDataStore.instance.breakdownsFor(cityId);
    return breakdowns[type] ?? const [];
  }
}



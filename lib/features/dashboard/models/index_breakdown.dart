/*
class IndexBreakdown {
  const IndexBreakdown({required this.factor, required this.percentage});

  final String factor;
  final double percentage;

  factory IndexBreakdown.fromMap(Map<String, dynamic> map) {
    return IndexBreakdown(
      factor: map['factor'] as String,
      percentage: (map['percentage'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap(String indexType, String cityId) {
    return <String, dynamic>{
      'city_id': cityId,
      'index_type': indexType,
      'factor': factor,
      'percentage': percentage,
    };
  }
}

*/
class IndexBreakdown {
  const IndexBreakdown({required this.factor, required this.percentage});

  final String factor;
  final double percentage;

  factory IndexBreakdown.fromMap(Map<String, dynamic> map) {
    final raw = (map['percentage'] as num).toDouble();
    // Scale once if backend provided a 0–1 fraction.
    final scaled = raw <= 1.0 ? raw * 100.0 : raw;
    return IndexBreakdown(
      factor: map['factor'] as String,
      percentage: scaled.clamp(0.0, 100.0),
    );
  }

  Map<String, dynamic> toMap(String indexType, String cityId) {
    return <String, dynamic>{
      'city_id': cityId,
      'index_type': indexType,
      'factor': factor,
      'percentage': percentage, // keep 0–100 in app layer
    };
  }
}


import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

enum indexType { usi, gci, cri, hi }

extension indexTypeX on indexType {
  String get label {
    switch (this) {
      case indexType.usi:
        return 'USI';
      case indexType.gci:
        return 'GCI';
      case indexType.cri:
        return 'CRI';
      case indexType.hi:
        return 'HI';
    }
  }

  String get description {
    switch (this) {
      case indexType.usi:
        return 'Urban Sustainability Index';
      case indexType.gci:
        return 'Green Coverage Index';
      case indexType.cri:
        return 'Climate Resilience Index';
      case indexType.hi:
        return 'Health Index';
    }
  }

  int get sortOrder {
    switch (this) {
      case indexType.usi:
        return 0;
      case indexType.gci:
        return 1;
      case indexType.cri:
        return 2;
      case indexType.hi:
        return 3;
    }
  }

  Color get color {
    switch (this) {
      case indexType.usi:
        return AppColors.usi;
      case indexType.gci:
        return AppColors.gci;
      case indexType.cri:
        return AppColors.cri;
      case indexType.hi:
        return AppColors.hi;
    }
  }

  String get valueName => '${label.toLowerCase()}_value';
}

class IndexScore {
  const IndexScore({
    required this.type,
    required this.value,
    required this.timestamp,
  });

  final indexType type;
  final double value;
  final DateTime timestamp;

  IndexScore copyWith({double? value, DateTime? timestamp}) {
    return IndexScore(
      type: type,
      value: value ?? this.value,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory IndexScore.fromMap(Map<String, dynamic> map) {
    return IndexScore(
      type: indexType.values.firstWhere(
        (it) => it.label.toLowerCase() == (map['type'] as String).toLowerCase(),
      ),
      value: (map['value'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> toMap(String cityId) {
    return <String, dynamic>{
      'city_id': cityId,
      'type': type.label.toLowerCase(),
      'value': value,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

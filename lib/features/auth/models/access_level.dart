enum AccessLevel { resident, cityLeader }

extension AccessLevelX on AccessLevel {
  String get label {
    switch (this) {
      case AccessLevel.resident:
        return 'Resident';
      case AccessLevel.cityLeader:
        return 'City Leader';
    }
  }

  String get value {
    switch (this) {
      case AccessLevel.resident:
        return 'resident';
      case AccessLevel.cityLeader:
        return 'cityLeader';
    }
  }

  static AccessLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'resident':
        return AccessLevel.resident;
      case 'cityleader':
      case 'city_leader':
        return AccessLevel.cityLeader;
      default:
        throw ArgumentError('Unknown access level: $value');
    }
  }
}

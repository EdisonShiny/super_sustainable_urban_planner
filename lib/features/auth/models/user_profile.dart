import 'access_level.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.username,
    required this.email,
    required this.accessLevel,
    required this.cityRegion,
    this.departmentAgencies,
  });

  final String id;
  final String username;
  final String email;
  final AccessLevel accessLevel;
  final String cityRegion;
  final String? departmentAgencies;

  bool get isCityLeader => accessLevel == AccessLevel.cityLeader;

  UserProfile copyWith({
    String? username,
    String? email,
    AccessLevel? accessLevel,
    String? cityRegion,
    String? departmentAgencies,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      email: email ?? this.email,
      accessLevel: accessLevel ?? this.accessLevel,
      cityRegion: cityRegion ?? this.cityRegion,
      departmentAgencies: departmentAgencies ?? this.departmentAgencies,
    );
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      accessLevel: AccessLevelX.fromString(map['access_level'] as String),
      cityRegion: map['city_region'] as String,
      departmentAgencies: map['department_agencies'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'username': username,
      'email': email,
      'access_level': accessLevel.value,
      'city_region': cityRegion,
      'department_agencies': departmentAgencies,
    };
  }
}

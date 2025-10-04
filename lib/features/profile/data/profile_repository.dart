import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_client.dart';
import '../../auth/models/access_level.dart';
import '../../auth/models/user_profile.dart';

class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  SupabaseClient get _client {
    final client = maybeSupabaseClient;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    return client;
  }

  Future<UserProfile> fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select(
          'id, username, email, access_level, department_agencies, city_region',
        )
        .eq('id', userId)
        .single();

    return UserProfile.fromMap(response);
  }

  Future<UserProfile> updateProfile(UserProfile profile) async {
    final response = await _client
        .from('profiles')
        .update({
          'username': profile.username,
          'email': profile.email,
          'access_level': profile.accessLevel.value,
          'department_agencies': profile.departmentAgencies,
          'city_region': profile.cityRegion,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', profile.id)
        .select()
        .single();

    return UserProfile.fromMap(response);
  }

  Future<void> updatePassword(String newPassword) async {
    final client = _client;
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
}

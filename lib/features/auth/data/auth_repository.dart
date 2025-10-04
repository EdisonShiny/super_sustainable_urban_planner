import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/supabase_client.dart';
import '../models/access_level.dart';
import '../models/user_profile.dart';

class AuthRepository {
  AuthRepository._();

  static final AuthRepository instance = AuthRepository._();

  SupabaseClient get _client {
    final client = maybeSupabaseClient;
    if (client == null) {
      throw StateError('Supabase client not initialized.');
    }
    return client;
  }

  Session? get currentSession => maybeSupabaseClient?.auth.currentSession;

  Stream<AuthState> get authStateChanges =>
      maybeSupabaseClient?.auth.onAuthStateChange ?? const Stream.empty();

  Future<UserProfile> signIn({
    required String username,
    required String password,
  }) async {
    final client = _client;
    final trimmed = username.trim();

    Map<String, dynamic>? profileResponse = await client
        .from('profiles')
        .select(
          'id, username, email, access_level, department_agencies, city_region',
        )
        .eq('username', trimmed)
        .maybeSingle();

    profileResponse ??= await client
        .from('profiles')
        .select(
          'id, username, email, access_level, department_agencies, city_region',
        )
        .eq('email', trimmed)
        .maybeSingle();

    if (profileResponse == null) {
      throw AuthException('Account not found.');
    }

    final email = profileResponse['email'] as String;

    await client.auth.signInWithPassword(email: email, password: password);

    return UserProfile.fromMap(profileResponse);
  }

  Future<UserProfile> signUp({
    required String username,
    required String email,
    required String password,
    required AccessLevel accessLevel,
    required String cityRegion,
    String? departmentAgencies,
  }) async {
    final client = _client;
    final trimmedUsername = username.trim();
    final trimmedEmail = email.trim();
    final trimmedCityRegion = cityRegion.trim();
    final trimmedDepartment = departmentAgencies?.trim();

    final authResponse = await client.auth.signUp(
      email: trimmedEmail,
      password: password,
      data: {
        'username': trimmedUsername,
        'access_level': accessLevel.value,
        'city_region': trimmedCityRegion,
        if (trimmedDepartment != null && trimmedDepartment.isNotEmpty)
          'department_agencies': trimmedDepartment,
      },
    );

    final user = authResponse.user;
    if (user == null) {
      throw AuthException('Unable to create account.');
    }

    Map<String, dynamic>? profileResponse;
    for (var attempt = 0; attempt < 5; attempt++) {
      profileResponse = await client
          .from('profiles')
          .select(
            'id, username, email, access_level, department_agencies, city_region',
          )
          .eq('id', user.id)
          .maybeSingle();
      if (profileResponse != null) {
        break;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (profileResponse == null) {
      throw AuthException(
        'Account created but profile is pending. Please try signing in shortly.',
      );
    }

    return UserProfile.fromMap(profileResponse);
  }

  Future<void> signOut() async {
    final client = maybeSupabaseClient;
    if (client == null) return;
    await client.auth.signOut();
  }

  Future<UserProfile?> fetchCurrentProfile() async {
    final client = maybeSupabaseClient;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) {
      return null;
    }

    final response = await client
        .from('profiles')
        .select(
          'id, username, email, access_level, department_agencies, city_region',
        )
        .eq('id', userId)
        .maybeSingle();

    if (response == null) {
      return null;
    }
    return UserProfile.fromMap(response);
  }
}

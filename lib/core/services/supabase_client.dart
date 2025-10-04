import 'package:supabase_flutter/supabase_flutter.dart';

const String supabaseUrl = 'https://xnmqdhxthuonoikrnqoq.supabase.co';
const String supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhubXFkaHh0aHVvbm9pa3JucW9xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg4MTU0MzYsImV4cCI6MjA3NDM5MTQzNn0.rLXuGX_IBeT6ptXRp7W38b8FXB7UhEqUBBX9zcDkk6A';

SupabaseClient? _client;

SupabaseClient get supabaseClient {
  final client = _client;
  if (client != null) {
    return client;
  }
  throw StateError(
    'Supabase is not configured. Provide credentials before launching the app.',
  );
}

SupabaseClient? get maybeSupabaseClient => _client;

Future<void> initializeSupabase() async {
  if (_client != null) return;
  final hasCredentials =
      supabaseUrl.isNotEmpty &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseUrl.contains('PLACEHOLDER');
  if (!hasCredentials) {
    return;
  }

  final supabase = await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  _client = supabase.client;
}

Session? get currentSession => _client?.auth.currentSession;

Stream<AuthState> get authStateChanges =>
    _client?.auth.onAuthStateChange ?? const Stream.empty();

Future<void> supabaseSignOut() async {
  final client = _client;
  if (client == null) return;
  await client.auth.signOut();
}

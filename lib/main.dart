import 'dart:developer';
import 'package:flutter/material.dart';
import 'app.dart';
import 'core/services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeSupabase();
  } catch (error, stackTrace) {
    log('Supabase initialization failed', error: error, stackTrace: stackTrace);
  }
  runApp(const MyApp());
}

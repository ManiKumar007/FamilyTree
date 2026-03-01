import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (optional fallback — dart-define takes precedence)
  // In production builds, use --dart-define instead of .env files
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    // .env file is optional — dart-define values are preferred for production
  }

  // Initialize Supabase with persistent session
  // Use dart-define values first, then .env as fallback
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '') != ''
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '') != ''
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  // Only log config status in debug mode — never log actual values
  assert(() {
    debugPrint('Supabase configured: ${supabaseUrl.isNotEmpty}');
    return true;
  }());
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Session will be persisted automatically using SharedPreferences
    ),
  );

  // Handle auth state changes (no PII logging in production)
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    assert(() {
      debugPrint('Auth state changed: ${data.event}');
      return true;
    }());
  });

  // Load persisted language preference
  final prefs = await SharedPreferences.getInstance();
  final savedLanguage = prefs.getString('preferred_language') ?? 'en';

  runApp(
    ProviderScope(
      overrides: [
        initialLocaleProvider.overrideWithValue(Locale(savedLanguage)),
      ],
      child: const MyFamilyTreeApp(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (fallback, dart-define takes precedence)
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️  .env file not found, using dart-define or defaults: $e');
  }

  // Initialize Supabase with persistent session
  // Use dart-define values first, then .env as fallback
  final supabaseUrl = const String.fromEnvironment('SUPABASE_URL', defaultValue: '') != ''
      ? const String.fromEnvironment('SUPABASE_URL')
      : dotenv.env['SUPABASE_URL'] ?? '';
  final supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '') != ''
      ? const String.fromEnvironment('SUPABASE_ANON_KEY')
      : dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  
  debugPrint('🔧 Supabase URL: $supabaseUrl');
  debugPrint('🔧 Anon Key length: ${supabaseAnonKey.length}');
  
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      // Session will be persisted automatically using SharedPreferences
    ),
  );

  // Handle auth state changes
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    final session = data.session;
    if (session != null) {
      debugPrint('✅ User session active: ${session.user.email}');
    } else {
      debugPrint('❌ No active session');
    }
  });

  runApp(
    const ProviderScope(
      child: MyFamilyTreeApp(),
    ),
  );
}

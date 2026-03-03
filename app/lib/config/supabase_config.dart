/**
 * Supabase Proxy Configuration for Flutter app
 * 
 * This file handles Supabase client initialization with support for
 * regional proxy bypass (useful in India where Supabase may be blocked).
 * 
 * Environment Variables:
 * - SUPABASE_URL: Direct Supabase URL (e.g., https://your-project.supabase.co)
 * - SUPABASE_ANON_KEY: Public API key
 * - SUPABASE_PROXY_URL: (Optional) Cloudflare Worker proxy URL
 *     If set, all requests route through this proxy instead of direct to Supabase
 */

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Supabase URLs
  static const String _directSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://vojwwcolmnbzogsrmwap.supabase.co',
  );
  
  // Optional proxy URL for bypassing regional blocks
  static const String _proxyUrl = String.fromEnvironment(
    'SUPABASE_PROXY_URL',
    defaultValue: '', // Leave empty to disable proxy
  );
  
  // Supabase anonymous key
  static const String _anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key-here',
  );

  /// Get the Supabase URL based on configuration
  /// Returns proxy URL if available, otherwise direct URL
  static String getSupabaseUrl() {
    if (_proxyUrl.isNotEmpty) {
      debugPrint('[Supabase] Using proxy URL: $_proxyUrl');
      return _proxyUrl;
    }
    debugPrint('[Supabase] Using direct URL: $_directSupabaseUrl');
    return _directSupabaseUrl;
  }

  /// Initialize Supabase client with proxy support
  static Future<void> initialize() async {
    try {
      final url = getSupabaseUrl();
      
      debugPrint('[Supabase] Initializing with URL: $url');
      
      await Supabase.initialize(
        url: url,
        anonKey: _anonKey,
        headers: {
          // Add custom header to identify proxy requests
          if (_proxyUrl.isNotEmpty) 'X-Proxy-Request': 'true',
        },
      );
      
      debugPrint('[Supabase] Initialization successful');
    } catch (e) {
      debugPrint('[Supabase] Initialization error: $e');
      rethrow;
    }
  }

  /// Get the current Supabase client
  static SupabaseClient getClient() {
    return Supabase.instance.client;
  }

  /// Check if using proxy
  static bool isUsingProxy() => _proxyUrl.isNotEmpty;

  /// Verify Supabase connection
  static Future<bool> verifyConnection() async {
    try {
      final client = getClient();
      final response = await client.rpc('ping').timeout(const Duration(seconds: 5));
      return true;
    } catch (e) {
      debugPrint('[Supabase] Connection verification failed: $e');
      return false;
    }
  }
}

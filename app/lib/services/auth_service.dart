import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/constants.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  GoogleSignIn? _googleSignIn;

  /// Get or create GoogleSignIn instance
  GoogleSignIn get googleSignIn {
    _googleSignIn ??= GoogleSignIn(
      scopes: ['email', 'profile'],
      serverClientId: AppConfig.googleWebClientId.isNotEmpty 
        ? AppConfig.googleWebClientId 
        : null,
    );
    return _googleSignIn!;
  }

  /// Current session
  Session? get currentSession => _supabase.auth.currentSession;

  /// Current user
  User? get currentUser => _supabase.auth.currentUser;

  /// Is user logged in
  bool get isLoggedIn => currentUser != null;

  /// Auth state stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  /// Sign in with Google
  Future<AuthResponse> signInWithGoogle() async {
    // Sign out from previous session to avoid account picker issues
    await googleSignIn.signOut();

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign-in cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('No ID token received from Google');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }

  /// Sign in with email magic link
  Future<void> signInWithEmail(String email) async {
    await _supabase.auth.signInWithOtp(
      email: email,
      emailRedirectTo: 'com.myfamilytree://login-callback',
    );
  }

  /// Verify OTP (for email)
  Future<AuthResponse> verifyOtp(String email, String token) async {
    return await _supabase.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// Get access token for API calls
  String? get accessToken => currentSession?.accessToken;
}

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static final _supabase = Supabase.instance.client;

  static Future<Map<String, dynamic>> signUp({required String email, required String password, Map<String, dynamic>? userMetadata}) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );
      
      return {
        'success': true,
        'message': 'User created successfully',
        'user': response.user
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> login({required String email, required String password}) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return {
        'success': true,
        'message': 'Login successful',
        'user': response.user
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message // 'An unknown authentication error occurred.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      /// Web option #1 (best for web)
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.toothfile://login-callback/',
        authScreenLaunchMode: LaunchMode.externalApplication,
      );

      /// Web option #2 (alternative for web, but not recommended)
      // final GoogleSignIn googleSignIn = GoogleSignIn(
      //   clientId: 'YOUR_WEB_CLIENT_ID', // Optional: if you have a web client ID
      // );
      // final googleUser = await googleSignIn.signIn();
      // final googleAuth = await googleUser!.authentication;
      // final accessToken = googleAuth.accessToken;
      // final idToken = googleAuth.idToken;

      // if (accessToken == null) {
      //   throw 'No Access Token found.';
      // }
      // if (idToken == null) {
      //   throw 'No ID Token found.';
      // }

      // await _supabase.auth.signInWithIdToken(
      //   provider: OAuthProvider.google,
      //   idToken: idToken,
      //   accessToken: accessToken,
      // );





      return {
        'success': true,
        'message': 'Google login successful',
        'user': _supabase.auth.currentUser
      };
    } on AuthException catch (e) {
      return {
        'success': false,
        'message': e.message
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString()
      };
    }
  }

  static Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  static Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}

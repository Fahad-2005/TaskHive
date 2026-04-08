import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current user session
  Session? get currentSession => _supabase.auth.currentSession;

  // Sign Up
  Future<AuthResponse> signUp(String email, String password, String username) async {
    final response = await _supabase.auth.signUp(
      email: email, 
      password: password,
      // This data goes into the 'raw_user_meta_data' column in Auth
      data: {'username': username}, 
    );
    return response;
  }

  // Sign In
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  // Sign Out
  Future<void> signOut() async => await _supabase.auth.signOut();
}
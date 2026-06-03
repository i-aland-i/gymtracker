import '../supabase_client.dart';

class AuthService {
  Future<void> signUp(String email, String password) =>
      supabase.auth.signUp(email: email, password: password);
  Future<void> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);
  Future<void> signOut() => supabase.auth.signOut();
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

class AuthService {
  Future<void> signUp(String email, String password) =>
      supabase.auth.signUp(email: email, password: password);

  Future<void> signIn(String email, String password) =>
      supabase.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => supabase.auth.signOut();

  Future<void> resetPassword(String email) =>
      supabase.auth.resetPasswordForEmail(email);

  Future<void> resendConfirmation(String email) =>
      supabase.auth.resend(type: OtpType.signup, email: email);
}

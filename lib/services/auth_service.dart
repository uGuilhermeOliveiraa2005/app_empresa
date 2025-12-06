import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Login (Igual para todos)
  Future<void> signIn(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw Exception('Erro ao fazer login: $e');
    }
  }

  // CADASTRO DE DONO DE EMPRESA
  Future<void> signUpOwner({
    required String email,
    required String password,
    required String fullName,
    required String cpf,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'cpf': cpf,
          'role': 'company_owner', // <--- A MÁGICA ESTÁ AQUI
        },
      );
    } catch (e) {
      throw Exception('Erro ao cadastrar empresa: $e');
    }
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }
}
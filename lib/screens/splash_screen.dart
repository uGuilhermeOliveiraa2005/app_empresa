import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth/login_company_screen.dart';
import 'home/dashboard_screen.dart';
import 'home/create_company_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Pequeno delay para a tela não piscar muito rápido
    await Future.delayed(const Duration(milliseconds: 500));

    final session = Supabase.instance.client.auth.currentSession;
    
    if (session == null) {
      // Sem sessão -> Login
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginCompanyScreen()));
    } else {
      // Com sessão -> Verifica se tem empresa
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('companies')
            .select('id') // Só precisamos do ID pra saber se existe
            .eq('owner_id', user.id)
            .maybeSingle();
        
        if (mounted) {
          if (data != null) {
            // Tem empresa -> Dashboard
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
          } else {
            // Não tem empresa -> Criar
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateCompanyScreen()));
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}
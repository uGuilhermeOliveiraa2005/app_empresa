import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_colors.dart';
import 'screens/splash_screen.dart'; // Importe a nova tela

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- CONEXÃO COM O SUPABASE ---
  // (Mantenha suas chaves aqui)
  await Supabase.initialize(
    url: 'https://yfjmtxeksibwocvqodzk.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlmam10eGVrc2lid29jdnFvZHprIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ2MTY5NjUsImV4cCI6MjA4MDE5Mjk2NX0.iQp4ICY9j4VaFJ2EnDk7WTrtVWvQjaXt5VRsxVdrk3E', 
  );

  runApp(const MeuAppEmpresa());
}

class MeuAppEmpresa extends StatelessWidget {
  const MeuAppEmpresa({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Empresa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        ),
      ),
      
      // AQUI ESTÁ A CORREÇÃO:
      // Inicia pela Splash Screen, que decide pra onde ir
      home: const SplashScreen(),
    );
  }
}
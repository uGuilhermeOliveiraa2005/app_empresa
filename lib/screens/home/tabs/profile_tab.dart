import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/app_colors.dart';
import '../../auth/login_company_screen.dart';
import '../../profile/setup_pix_screen.dart'; // <--- IMPORTANTE

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    const myFontStyle = TextStyle(fontFamily: 'Poppins');

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Meu Negócio", style: myFontStyle.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 30),

              // --- OPÇÃO DE PAGAMENTO ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.pix, color: Colors.blue),
                ),
                title: Text("Configurar Pagamento Pix", style: myFontStyle.copyWith(fontWeight: FontWeight.bold)),
                subtitle: const Text("Defina sua chave para receber pagamentos"),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SetupPixScreen()));
                },
              ),
              
              const Divider(height: 40),

              // --- LOGOUT ---
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.logout, color: Colors.red),
                ),
                title: Text("Sair da Conta", style: myFontStyle.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginCompanyScreen()),
                      (route) => false,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
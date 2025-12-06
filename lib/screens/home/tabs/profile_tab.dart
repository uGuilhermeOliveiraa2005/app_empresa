import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_colors.dart';
import '../../auth/login_company_screen.dart';
import '../../../widgets/custom_text_field.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _pixKeyController = TextEditingController(); // Chave Pix
  final _emailController = TextEditingController(); 
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _companyId;

  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _emailController.text = user.email ?? '';

        final data = await Supabase.instance.client
            .from('companies')
            .select()
            .eq('owner_id', user.id)
            .maybeSingle();

        if (mounted && data != null) {
          setState(() {
            _companyId = data['id'];
            _nameController.text = data['name'] ?? '';
            _addressController.text = data['address'] ?? '';
            _pixKeyController.text = data['pix_key'] ?? ''; // Carrega do banco
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    if (_companyId == null) return;

    setState(() => _isSaving = true);
    try {
      await Supabase.instance.client.from('companies').update({
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'pix_key': _pixKeyController.text.trim(), // Salva no banco
      }).eq('id', _companyId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Dados atualizados!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginCompanyScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Configurações", style: myFontStyle.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.storefront_rounded, size: 50, color: AppColors.primary),
              ),
            ),
            const SizedBox(height: 30),

            Text("Dados Básicos", style: myFontStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            CustomTextField(label: "Nome do Restaurante", icon: Icons.store, controller: _nameController),
            const SizedBox(height: 16),
            CustomTextField(label: "Endereço", icon: Icons.location_on, controller: _addressController),
            
            const SizedBox(height: 30),
            Text("Financeiro (Pix)", style: myFontStyle.copyWith(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary)),
            const SizedBox(height: 10),
            
            CustomTextField(
              label: "Chave Pix (CPF, Email, Aleatória...)",
              icon: Icons.pix,
              controller: _pixKeyController,
            ),
            const Padding(
              padding: EdgeInsets.only(left: 10, top: 5),
              child: Text("O cliente verá esta chave e o QR Code para pagar.", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.textDark,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text("SALVAR ALTERAÇÕES", style: myFontStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text("Sair da Conta", style: myFontStyle.copyWith(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }
}
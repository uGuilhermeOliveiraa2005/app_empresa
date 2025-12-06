import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import 'dashboard_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _addressController = TextEditingController();
  
  final _cnpjMask = MaskTextInputFormatter(
    mask: '##.###.###/####-##', 
    filter: { "#": RegExp(r'[0-9]') }
  );

  bool _isLoading = false;

  // Estilo de fonte seguro (Offline)
  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  Future<void> _saveCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("Sessão expirada. Faça login novamente.");

      // Salva no Supabase
      await Supabase.instance.client.from('companies').insert({
        'owner_id': user.id,
        'name': _nameController.text.trim(),
        'cnpj': _cnpjController.text.trim(),
        'address': _addressController.text.trim(),
      });

      if (mounted) {
        // Sucesso! Vai para o Dashboard
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.textDark, // Fundo Escuro Premium
      body: SafeArea(
        child: Column(
          children: [
            // --- CABEÇALHO ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Configure seu Negócio",
                    style: myFontStyle.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Preencha os dados abaixo para começar a receber pedidos.",
                    style: myFontStyle.copyWith(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),

            // --- FORMULÁRIO (CARD BRANCO ARREDONDADO) ---
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomTextField(
                          label: "Nome do Restaurante",
                          icon: Icons.edit,
                          controller: _nameController,
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: "CNPJ",
                          icon: Icons.article_outlined,
                          controller: _cnpjController,
                          inputFormatters: [_cnpjMask],
                          keyboardType: TextInputType.number,
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          label: "Endereço",
                          icon: Icons.location_on_outlined,
                          controller: _addressController,
                          validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                        ),
                        const SizedBox(height: 40),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveCompany,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.textDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : Text(
                                  "FINALIZAR CONFIGURAÇÃO",
                                  style: myFontStyle.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
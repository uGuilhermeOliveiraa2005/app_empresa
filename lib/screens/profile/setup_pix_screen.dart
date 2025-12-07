import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../widgets/custom_text_field.dart';

class SetupPixScreen extends StatefulWidget {
  const SetupPixScreen({super.key});

  @override
  State<SetupPixScreen> createState() => _SetupPixScreenState();
}

class _SetupPixScreenState extends State<SetupPixScreen> {
  final _keyController = TextEditingController();
  final _typeController = TextEditingController(); // Ex: CNPJ, Celular
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _companyId;

  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  @override
  void initState() {
    super.initState();
    _loadPixData();
  }

  // Busca os dados atuais da empresa
  Future<void> _loadPixData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('companies')
          .select('id, pix_key, pix_key_type')
          .eq('owner_id', user.id)
          .maybeSingle();
      
      if (mounted && data != null) {
        setState(() {
          _companyId = data['id'];
          _keyController.text = data['pix_key'] ?? '';
          _typeController.text = data['pix_key_type'] ?? '';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePixData() async {
    if (_companyId == null) return;
    setState(() => _isSaving = true);

    try {
      await Supabase.instance.client.from('companies').update({
        'pix_key': _keyController.text.trim(),
        'pix_key_type': _typeController.text.trim(),
      }).eq('id', _companyId!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Chave Pix salva com sucesso!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Configurar Pix", style: myFontStyle.copyWith(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue[100]!),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.blue),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Essas informações aparecerão para o cliente na hora de finalizar o pedido.",
                            style: myFontStyle.copyWith(fontSize: 13, color: Colors.blue[900]),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  CustomTextField(
                    label: "Tipo de Chave (Ex: CPF, CNPJ, Email)",
                    icon: Icons.tag,
                    controller: _typeController,
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    label: "Chave Pix",
                    icon: Icons.pix,
                    controller: _keyController,
                  ),
                  
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _savePixData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSaving 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("SALVAR CONFIGURAÇÃO", style: myFontStyle.copyWith(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
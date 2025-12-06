import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';

class RegisterOwnerScreen extends StatefulWidget {
  const RegisterOwnerScreen({super.key});

  @override
  State<RegisterOwnerScreen> createState() => _RegisterOwnerScreenState();
}

class _RegisterOwnerScreenState extends State<RegisterOwnerScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: { "#": RegExp(r'[0-9]') });
  bool _isLoading = false;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Cria o usuário com a role 'company_owner'
      await _authService.signUpOwner(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        fullName: _nameController.text.trim(),
        cpf: _cpfController.text.trim(),
      );

      if (mounted) {
        // AQUI ESTÁ O PULO DO GATO:
        // No futuro, em vez de voltar pro login, vamos enviar para a tela de "Dados da Empresa"
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada! Agora faça login.')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: AppColors.textDark, // Fundo Escuro
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true, 
      
      body: LayoutBuilder(
        builder: (context, constraints) {
          return ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // --- CABEÇALHO ---
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: isKeyboardOpen ? 80 : size.height * 0.15, 
                        padding: const EdgeInsets.only(left: 32, bottom: 20),
                        width: double.infinity,
                        alignment: Alignment.bottomLeft,
                        child: SafeArea(
                          bottom: false,
                          child: isKeyboardOpen ? const SizedBox.shrink() : Text(
                            "Novo Parceiro",
                            style: GoogleFonts.poppins(
                              fontSize: 28, 
                              fontWeight: FontWeight.bold, 
                              color: Colors.white
                            ),
                          ),
                        ),
                      ),
            
                      // --- ÁREA BRANCA ---
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  CustomTextField(
                                    label: "Nome do Dono",
                                    icon: Icons.person_outline,
                                    controller: _nameController,
                                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    label: "CPF do Dono",
                                    icon: Icons.badge_outlined,
                                    controller: _cpfController,
                                    inputFormatters: [_cpfMask],
                                    keyboardType: TextInputType.number,
                                    validator: (v) => v!.isEmpty ? 'Obrigatório' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    label: "E-mail de Acesso",
                                    icon: Icons.email_outlined,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v!.contains('@') ? null : 'E-mail inválido',
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    label: "Senha",
                                    icon: Icons.lock_outline,
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    label: "Confirmar Senha",
                                    icon: Icons.lock_reset,
                                    controller: _confirmPasswordController,
                                    isPassword: true,
                                    validator: (v) => v != _passwordController.text ? 'Senhas não conferem' : null,
                                  ),
                                  
                                  const SizedBox(height: 20),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleRegister,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.textDark, // Botão preto
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text("CRIAR CONTA", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ),
            ),
          );
        },
      ),
    );
  }
}
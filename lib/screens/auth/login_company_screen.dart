import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_text_field.dart';
import 'register_owner_screen.dart';
import '../home/dashboard_screen.dart';
import '../home/create_company_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginCompanyScreen extends StatefulWidget {
  const LoginCompanyScreen({super.key});

  @override
  State<LoginCompanyScreen> createState() => _LoginCompanyScreenState();
}

class _LoginCompanyScreenState extends State<LoginCompanyScreen> {
  final _authService = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isLoading = false;
  bool _rememberMe = true; // Checkbox

  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (mounted) {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final data = await Supabase.instance.client
              .from('companies')
              .select()
              .eq('owner_id', user.id)
              .maybeSingle();

          if (mounted) {
            if (data != null) {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const DashboardScreen()));
            } else {
               Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CreateCompanyScreen()));
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: AppColors.error),
        );
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
      backgroundColor: AppColors.textDark,
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
                      // --- CABEÇALHO ESCURO ---
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        height: isKeyboardOpen ? size.height * 0.15 : size.height * 0.35,
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: SafeArea(
                            child: SingleChildScrollView(
                              physics: const NeverScrollableScrollPhysics(),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: EdgeInsets.all(isKeyboardOpen ? 5 : 16),
                                    decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                    child: Icon(Icons.store_rounded, size: isKeyboardOpen ? 30 : 50, color: Colors.white),
                                  ),
                                  if (!isKeyboardOpen) ...[
                                    const SizedBox(height: 10),
                                    Text("Gestão Food", style: myFontStyle.copyWith(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                                    Text("Painel Administrativo", style: myFontStyle.copyWith(fontSize: 14, color: Colors.white70)),
                                  ],
                                ],
                              ),
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
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Acesso Empresa", style: myFontStyle.copyWith(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                                  const SizedBox(height: 20),

                                  CustomTextField(
                                    label: "E-mail Empresarial",
                                    icon: Icons.alternate_email_rounded,
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    validator: (v) => v!.contains('@') ? null : 'E-mail inválido',
                                  ),
                                  const SizedBox(height: 16),
                                  
                                  CustomTextField(
                                    label: "Senha",
                                    icon: Icons.lock_outline_rounded,
                                    controller: _passwordController,
                                    isPassword: true,
                                    validator: (v) => v!.length < 6 ? 'Mínimo 6 caracteres' : null,
                                  ),
                                  
                                  const SizedBox(height: 10),

                                  // --- LINHA DO CHECKBOX (EMPRESA) ---
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          activeColor: AppColors.textDark, // Preto para empresa
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                          onChanged: (v) => setState(() => _rememberMe = v!),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text("Lembrar-me", style: myFontStyle.copyWith(color: AppColors.textLight, fontSize: 13)),
                                    ],
                                  ),

                                  if (!isKeyboardOpen) const Spacer(),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 55,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.textDark,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      ),
                                      child: _isLoading
                                        ? const CircularProgressIndicator(color: Colors.white)
                                        : Text("ACESSAR PAINEL", style: myFontStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  
                                  const SizedBox(height: 20),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text("Quer ser parceiro? ", style: myFontStyle.copyWith(color: AppColors.textLight)),
                                        GestureDetector(
                                          onTap: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterOwnerScreen()));
                                          },
                                          child: Text("Cadastre-se", style: myFontStyle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
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
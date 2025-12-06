import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
// Importe todas as abas
import 'tabs/home_tab.dart'; 
import 'tabs/menu_tab.dart';
import 'tabs/tables_tab.dart';
import 'tabs/profile_tab.dart'; // Importante: Nova aba de perfil

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Lista de telas para cada aba
  final List<Widget> _tabs = [
    const HomeTab(),      // Aba 0: Início (Pedidos)
    const MenuTab(),      // Aba 1: Cardápio
    const TablesTab(),    // Aba 2: Mesas/QR
    const ProfileTab(),   // Aba 3: Perfil (Agora implementada)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], 
      
      // O corpo muda de acordo com a aba selecionada
      body: _tabs[_currentIndex],

      // BARRA DE NAVEGAÇÃO
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.primary.withOpacity(0.15),
            labelTextStyle: MaterialStateProperty.all(
              const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          child: NavigationBar(
            height: 70,
            backgroundColor: Colors.white,
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) => setState(() => _currentIndex = index),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'Início',
              ),
              NavigationDestination(
                icon: Icon(Icons.restaurant_menu_outlined),
                selectedIcon: Icon(Icons.restaurant_menu_rounded, color: AppColors.primary),
                label: 'Cardápio',
              ),
              NavigationDestination(
                icon: Icon(Icons.qr_code_scanner), 
                selectedIcon: Icon(Icons.qr_code_2_rounded, color: AppColors.primary),
                label: 'Mesas',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Perfil',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
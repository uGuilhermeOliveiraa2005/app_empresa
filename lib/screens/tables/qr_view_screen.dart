import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/app_colors.dart';

class QrViewScreen extends StatelessWidget {
  final String tableLabel;
  final String tableId;
  final String companyId;
  final String companyName;

  const QrViewScreen({
    super.key,
    required this.tableLabel,
    required this.tableId,
    required this.companyId,
    required this.companyName,
  });

  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> qrData = {
      'c_id': companyId,
      't_id': tableId,
      'lbl': tableLabel,
    };

    final String qrDataString = jsonEncode(qrData);
    
    // 1. Cálculos de dimensão para responsividade total
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;
    final appBarHeight = AppBar().preferredSize.height;
    // Altura exata disponível para o conteúdo (sem barra de status/appbar)
    final availableHeight = size.height - padding.top - padding.bottom - appBarHeight;

    // QR Code terá 60% da largura da tela, travado no máximo em 260px
    final double qrSize = size.width * 0.6 > 260 ? 260 : size.width * 0.6;

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // CORPO COM ALTURA FIXA E SEM ROLAGEM
      body: SizedBox(
        height: availableHeight,
        width: size.width, // Força largura total
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            // Distribui o espaço verticalmente
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center, // Força centro horizontal na coluna
            children: [
              const Spacer(flex: 2), // Espaço flexível no topo
              
              // Textos do Cabeçalho
              Column(
                children: [
                  Text(
                    tableLabel,
                    textAlign: TextAlign.center,
                    style: myFontStyle.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    companyName,
                    textAlign: TextAlign.center,
                    style: myFontStyle.copyWith(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 3), // Espaço médio

              // --- A CORREÇÃO DEFINITIVA PARA CENTRALIZAR ---
              // Envolvemos o container numa Row centralizada.
              // Isso força o alinhamento horizontal mesmo se a Column falhar.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // O CARTÃO BRANCO COM O QR CODE
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QrImageView(
                          data: qrDataString,
                          version: QrVersions.auto,
                          size: qrSize,
                          foregroundColor: AppColors.textDark,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Escaneie para pedir",
                          style: myFontStyle.copyWith(
                            color: AppColors.textLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Spacer(flex: 4), // Espaço maior antes do botão
              
              // Botão Imprimir
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Tire um Print Screen para imprimir!")),
                  );
                },
                icon: const Icon(Icons.print, color: AppColors.primary),
                label: Text("IMPRIMIR", style: myFontStyle.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
              
              const Spacer(flex: 2), // Espaço final no rodapé
            ],
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../core/app_colors.dart';
import '../../menu/add_product_screen.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Função para buscar produtos e categorias juntos
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Busca a empresa do usuário
      final companyRes = await Supabase.instance.client
          .from('companies')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();
      
      if (companyRes == null) {
         setState(() => _isLoading = false);
         return;
      }
      
      final companyId = companyRes['id'];

      // 2. Busca produtos dessa empresa com o nome da categoria (Join)
      final data = await Supabase.instance.client
          .from('products')
          .select('*, categories(name)')
          .eq('company_id', companyId)
          .order('created_at', ascending: false);
      
      setState(() {
        _products = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao carregar: $e')));
        setState(() => _isLoading = false);
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      // APP BAR MAIS LIMPA
      appBar: AppBar(
        title: Text("Cardápio Digital", style: myFontStyle.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: false,
      ),
      
      // BOTÃO FLUTUANTE MAIS MODERNO
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context, 
            MaterialPageRoute(builder: (_) => const AddProductScreen())
          );
          if (result == true) {
            _fetchData(); // Recarrega os dados
          }
        },
        backgroundColor: AppColors.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        label: Text("Adicionar Produto", style: myFontStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
      ),

      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
        : _products.isEmpty 
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                return _buildProductCard(_products[index]);
              },
            ),
    );
  }

  // Widget para quando não tem produtos
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.restaurant_menu_rounded, size: 60, color: AppColors.primary.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text("Seu cardápio está vazio!", style: myFontStyle.copyWith(color: AppColors.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Cadastre seus melhores pratos para começar.", textAlign: TextAlign.center, style: myFontStyle.copyWith(color: Colors.grey[500], fontSize: 16)),
        ],
      ),
    );
  }

  // O NOVO CARD BLINDADO
  Widget _buildProductCard(Map<String, dynamic> product) {
    final categoryName = product['categories'] != null ? product['categories']['name'] : 'Outros';
    final imageUrl = product['image_url'] ?? '';

    // Usamos um Card do Material para melhor elevação e bordas
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8, // Sombra mais suave e moderna
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // Cantos bem arredondados
      child: Container(
        height: 130, // Altura fixa para o card ficar uniforme
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            // --- FOTO DO PRODUTO (LATERAL ESQUERDA) ---
            // O segredo: ClipRRect apenas nos cantos esquerdos da imagem
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                bottomLeft: Radius.circular(24),
              ),
              child: SizedBox(
                width: 130, // Quadrado perfeito
                height: 130,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover, // Preenche o quadrado sem distorcer
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(color: Colors.grey[200], child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 40));
                  },
                ),
              ),
            ),
            
            // --- INFORMAÇÕES (LATERAL DIREITA) ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribui o conteúdo
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Categoria e Status
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                categoryName.toString().toUpperCase(),
                                style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.bold, fontFamily: 'Poppins', letterSpacing: 0.5),
                              ),
                            ),
                            // Ícone de disponível (Verde) ou indisponível (Cinza)
                            Icon(Icons.circle, size: 10, color: product['is_available'] == true ? Colors.green : Colors.grey[300])
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Nome do Produto
                        Text(
                          product['name'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: myFontStyle.copyWith(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                        // Descrição
                        Text(
                          product['description'] ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: myFontStyle.copyWith(fontSize: 12, color: Colors.grey[600], height: 1.2),
                        ),
                      ],
                    ),
                    
                    // Preço
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        _currencyFormat.format(product['price']),
                        style: myFontStyle.copyWith(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
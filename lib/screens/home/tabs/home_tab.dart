import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_colors.dart';
import '../../auth/login_company_screen.dart';
import '../../../widgets/order_card.dart'; // Importe o widget novo

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');
  String _companyName = "Carregando...";
  String? _companyId;

  @override
  void initState() {
    super.initState();
    _loadCompanyInfo();
  }

  Future<void> _loadCompanyInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('companies')
          .select('id, name')
          .eq('owner_id', user.id)
          .maybeSingle();
      
      if (mounted && data != null) {
        setState(() {
          _companyName = data['name'];
          _companyId = data['id'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Só começa a ouvir pedidos quando tivermos o ID da empresa
    final Stream<List<Map<String, dynamic>>>? _ordersStream = _companyId == null
        ? null
        : Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id']) // Escuta mudanças na tabela
            .eq('company_id', _companyId!)
            .order('created_at', ascending: false) // Mais recentes primeiro
            .map((maps) => maps); // Retorna a lista simples por enquanto

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // --- APP BAR ---
          SliverAppBar(
            expandedHeight: 100.0,
            floating: true,
            pinned: true,
            backgroundColor: AppColors.textDark,
            title: Text(
              _companyName,
              style: myFontStyle.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white70),
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginCompanyScreen()));
                  }
                },
              ),
            ],
          ),

          // --- LISTA DE PEDIDOS EM TEMPO REAL ---
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: _companyId == null
                ? const SliverToBoxAdapter(child: Center(child: LinearProgressIndicator()))
                : StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _ordersStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return SliverToBoxAdapter(child: Text("Erro: ${snapshot.error}"));
                      }
                      
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                      }

                      final orders = snapshot.data ?? [];

                      if (orders.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.storefront, size: 60, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text("Sem pedidos por enquanto", style: myFontStyle.copyWith(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      // Como o Stream básico não traz os relacionamentos (Joins) automaticamente em tempo real,
                      // precisamos buscar os detalhes (Itens, Mesas, Clientes) para cada pedido.
                      // O jeito ideal é criar um componente que busca seus próprios detalhes.
                      // Vamos usar o OrderCardWrapper para isso.
                      
                      return SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            return OrderCardWrapper(orderBasic: orders[index]);
                          },
                          childCount: orders.length,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET AUXILIAR PARA BUSCAR DETALHES DO PEDIDO ---
// O Stream acima traz só os dados brutos da tabela 'orders'.
// Este widget pega o ID e busca os nomes (Mesa, Cliente, Produtos)
class OrderCardWrapper extends StatefulWidget {
  final Map<String, dynamic> orderBasic;
  const OrderCardWrapper({super.key, required this.orderBasic});

  @override
  State<OrderCardWrapper> createState() => _OrderCardWrapperState();
}

class _OrderCardWrapperState extends State<OrderCardWrapper> {
  Map<String, dynamic>? _fullOrder;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  // Se o status mudar no pai (Stream), precisamos atualizar aqui também
  @override
  void didUpdateWidget(covariant OrderCardWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.orderBasic['status'] != widget.orderBasic['status']) {
      _fetchDetails();
    }
  }

  Future<void> _fetchDetails() async {
    final data = await Supabase.instance.client
        .from('orders')
        .select('*, order_items(*, products(name)), restaurant_tables(label), profiles(full_name)')
        .eq('id', widget.orderBasic['id'])
        .single();
    
    if (mounted) {
      setState(() => _fullOrder = data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_fullOrder == null) {
      // Card de carregamento (Skeleton)
      return Card(
        margin: const EdgeInsets.only(bottom: 16),
        child: Container(height: 150, padding: const EdgeInsets.all(16), child: const Center(child: CircularProgressIndicator())),
      );
    }
    return OrderCard(order: _fullOrder!);
  }
}
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/app_colors.dart';
import '../../../screens/tables/qr_view_screen.dart';

class TablesTab extends StatefulWidget {
  const TablesTab({super.key});

  @override
  State<TablesTab> createState() => _TablesTabState();
}

class _TablesTabState extends State<TablesTab> {
  TextStyle get myFontStyle => const TextStyle(fontFamily: 'Poppins');
  List<Map<String, dynamic>> _tables = [];
  bool _isLoading = true;
  String _companyName = "";
  String _companyId = "";

  @override
  void initState() {
    super.initState();
    _fetchTables();
  }

  Future<void> _fetchTables() async {
    // Não seta loading=true aqui para não piscar a tela toda vez que adiciona
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // 1. Pega ID e Nome da Empresa
      final companyRes = await Supabase.instance.client
          .from('companies')
          .select('id, name')
          .eq('owner_id', user.id)
          .maybeSingle();

      if (companyRes == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _companyId = companyRes['id'];
      _companyName = companyRes['name'];

      // 2. Busca as mesas
      // Ordenamos pela data de criação para manter a ordem lógica
      final data = await Supabase.instance.client
          .from('restaurant_tables')
          .select()
          .eq('company_id', _companyId)
          .order('created_at', ascending: true);

      if (mounted) {
        setState(() {
          _tables = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  // Lógica inteligente para gerar o nome automático
  Future<void> _addTableAutomatically() async {
    setState(() => _isLoading = true);
    try {
      // Descobre o próximo número
      int nextNumber = 1;
      
      // Tenta extrair os números das mesas existentes para não repetir
      // Ex: Se tem Mesa 01 e Mesa 03, ele deve criar Mesa 04 (ou Mesa 02 se formos preencher buracos, mas o padrão é sempre somar ao maior)
      if (_tables.isNotEmpty) {
        // Pega todos os nomes, tenta tirar apenas o número e acha o maior
        final numbers = _tables.map((t) {
          final String label = t['label'];
          // Remove tudo que não é número da string
          final String numStr = label.replaceAll(RegExp(r'[^0-9]'), ''); 
          return int.tryParse(numStr) ?? 0;
        }).toList();
        
        if (numbers.isNotEmpty) {
          // Pega o maior número e soma 1
          nextNumber = numbers.reduce((curr, next) => curr > next ? curr : next) + 1;
        }
      }

      // Formata: Mesa 01, Mesa 05, Mesa 10
      final String label = "Mesa ${nextNumber.toString().padLeft(2, '0')}";

      // Salva no banco
      await Supabase.instance.client.from('restaurant_tables').insert({
        'company_id': _companyId,
        'label': label,
      });

      // Atualiza a lista
      await _fetchTables();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao criar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Função para deletar mesa
  Future<void> _deleteTable(String tableId, String label) async {
    // Confirmação antes de apagar
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Excluir $label?", style: myFontStyle.copyWith(fontWeight: FontWeight.bold)),
        content: const Text("O QR Code desta mesa deixará de funcionar imediatamente."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("EXCLUIR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('restaurant_tables')
          .delete()
          .eq('id', tableId);
      
      await _fetchTables();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao deletar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text("Gerenciar Mesas", style: myFontStyle.copyWith(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.grey[50],
        elevation: 0,
        centerTitle: false,
      ),
      
      // BOTÃO NOVO (Sem Dialog, cria direto)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _addTableAutomatically,
        backgroundColor: AppColors.textDark,
        icon: _isLoading 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          : const Icon(Icons.add, color: Colors.white),
        label: Text("Nova Mesa", style: myFontStyle.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
      ),

      body: _isLoading && _tables.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _tables.isEmpty
              ? _buildEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 80), // Espaço extra em baixo p/ botão
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 2 Colunas
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Um pouco mais alto que largo para caber tudo
                  ),
                  itemCount: _tables.length,
                  itemBuilder: (context, index) {
                    final table = _tables[index];
                    return _buildTableCard(table);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_restaurant_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("Nenhuma mesa cadastrada", style: myFontStyle.copyWith(color: Colors.grey[600], fontSize: 18)),
          Text("Clique em 'Nova Mesa' para começar", style: myFontStyle.copyWith(color: Colors.grey[400], fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTableCard(Map<String, dynamic> table) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5)),
        ],
        border: Border.all(color: Colors.grey[100]!),
      ),
      // Stack permite colocar o botão de excluir "flutuando" no canto
      child: Stack(
        children: [
          // CONTEÚDO PRINCIPAL (Clicável para abrir QR)
          Positioned.fill(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrViewScreen(
                      tableLabel: table['label'],
                      tableId: table['id'],
                      companyId: _companyId,
                      companyName: _companyName,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code_2, size: 32, color: AppColors.primary),
                  ),
                  const SizedBox(height: 12),
                  
                  // FittedBox impede o texto de estourar (se for Mesa 10000 ele diminui a fonte)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        table['label'],
                        style: myFontStyle.copyWith(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Ver QR Code",
                    style: myFontStyle.copyWith(fontSize: 10, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // BOTÃO DE EXCLUIR (No canto superior direito)
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () => _deleteTable(table['id'], table['label']),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_colors.dart';

class OrderCard extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderCard({super.key, required this.order});

  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  bool _isLoading = false;
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  // Configuração Visual dos Status e Pagamento
  Map<String, dynamic> _getStatusConfig(String status, String paymentStatus) {
    // SE O PAGAMENTO ESTÁ EM ANÁLISE, PRIORIDADE MÁXIMA
    if (paymentStatus == 'analise') {
      return {
        'color': Colors.purple,
        'label': 'VERIFICAR PIX',
        'progress': 0.1,
        'actionLabel': 'VER COMPROVANTE',
        'nextStatus': 'check_pix', // Ação especial que abre o modal
        'icon': Icons.payments,
      };
    }

    switch (status) {
      case 'pendente': return {'color': Colors.orange, 'label': 'NOVO', 'progress': 0.25, 'actionLabel': 'ACEITAR', 'nextStatus': 'em_preparo', 'icon': Icons.soup_kitchen};
      case 'em_preparo': return {'color': Colors.blue, 'label': 'NA COZINHA', 'progress': 0.50, 'actionLabel': 'PRONTO', 'nextStatus': 'pronto', 'icon': Icons.room_service};
      case 'pronto': return {'color': Colors.green, 'label': 'PRONTO', 'progress': 0.75, 'actionLabel': 'ENTREGAR', 'nextStatus': 'entregue', 'icon': Icons.check_circle};
      case 'entregue': return {'color': Colors.grey, 'label': 'CONCLUÍDO', 'progress': 1.0, 'actionLabel': null, 'nextStatus': null, 'icon': Icons.archive};
      default: return {'color': Colors.red, 'label': 'CANCELADO', 'progress': 0.0, 'actionLabel': null, 'nextStatus': null, 'icon': Icons.cancel};
    }
  }

  // Abre o diálogo com a foto do comprovante
  void _showProofDialog() {
    final proofUrl = widget.order['proof_url'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Comprovante Pix"),
        content: proofUrl != null 
            ? ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 400),
                child: Image.network(
                  proofUrl, 
                  fit: BoxFit.contain,
                  errorBuilder: (_,__,___) => const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [Icon(Icons.broken_image, size: 50, color: Colors.grey), Text("Erro ao carregar imagem")],
                  ),
                ),
              )
            : const Text("Nenhum comprovante anexado."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLTAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () {
              Navigator.pop(ctx);
              _approvePayment();
            },
            child: const Text("CONFIRMAR PAGAMENTO", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // Aprova o pagamento
  Future<void> _approvePayment() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'payment_status': 'pago',
            'status': 'em_preparo'
          })
          .eq('id', widget.order['id']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Avança o status
  Future<void> _advanceStatus(String? nextStatus) async {
    if (nextStatus == 'check_pix') {
      _showProofDialog();
      return;
    }
    if (nextStatus == null) return;

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': nextStatus})
          .eq('id', widget.order['id']);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.order['status'] ?? 'pendente';
    final paymentStatus = widget.order['payment_status'] ?? 'pendente';
    final config = _getStatusConfig(status, paymentStatus);
    
    final items = List<Map<String, dynamic>>.from(widget.order['order_items'] ?? []);
    final tableName = widget.order['restaurant_tables']?['label'] ?? 'Mesa ?';
    final customerName = widget.order['profiles']?['full_name'] ?? 'Cliente';
    final total = (widget.order['total_amount'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['color'].withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de Progresso no Topo
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: LinearProgressIndicator(
              value: config['progress'],
              backgroundColor: config['color'].withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(config['color']),
              minHeight: 6,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CABEÇALHO (MESA E STATUS) ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start, // Alinha ao topo caso quebre linha
                  children: [
                    // Coluna de Texto (Com Expanded para não empurrar o badge)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "$tableName • $customerName", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis, // Corta com ... se for grande
                          ),
                          const SizedBox(height: 4),
                          // Detalhes de Pagamento (Ex: Troco)
                          if (widget.order['payment_details'] != null && widget.order['payment_details'].toString().isNotEmpty)
                            Text(
                              widget.order['payment_details'], 
                              style: TextStyle(color: Colors.grey[700], fontSize: 13, fontStyle: FontStyle.italic),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Badge de Status (Não encolhe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: config['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        config['label'], 
                        style: TextStyle(color: config['color'], fontSize: 11, fontWeight: FontWeight.bold)
                      ),
                    )
                  ],
                ),
                
                const Divider(height: 24),

                // --- LISTA DE ITENS ---
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['products']?['name'] ?? 'Item', style: const TextStyle(fontSize: 14)),
                            if (item['observation'] != null && item['observation'].toString().isNotEmpty)
                              Text(
                                "Obs: ${item['observation']}", 
                                style: const TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic)
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 16),

                // --- BOTÃO DE AÇÃO OU TOTAL ---
                if (config['actionLabel'] != null)
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _advanceStatus(config['nextStatus']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: config['color'], 
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      icon: Icon(config['icon'], size: 20),
                      label: _isLoading 
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(config['actionLabel'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  // Se finalizado, mostra o total grande
                  Align(
                    alignment: Alignment.centerRight, 
                    child: Text(
                      "Total: ${_currencyFormat.format(total)}", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
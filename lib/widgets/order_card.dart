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

  // --- CONFIGURAÇÃO DE CORES E STATUS ---
  Map<String, dynamic> _getStatusConfig(String status, String paymentStatus) {
    // 1. PRIORIDADE: SE O PAGAMENTO ESTÁ EM ANÁLISE (PIX)
    if (paymentStatus == 'analise') {
      return {
        'color': Colors.purple,
        'label': 'VERIFICAR PIX',
        'progress': 0.1,
        'actionLabel': 'VER COMPROVANTE',
        'nextStatus': 'VIEW_PROOF', // Gatilho especial
        'icon': Icons.receipt_long,
      };
    }

    // 2. STATUS NORMAIS DO PEDIDO
    switch (status.toLowerCase()) {
      case 'pendente':
        return {
          'color': Colors.orange,
          'label': 'NOVO PEDIDO',
          'progress': 0.2,
          'actionLabel': 'ACEITAR / COZINHA',
          'nextStatus': 'em_preparo',
          'icon': Icons.soup_kitchen
        };
      case 'em_preparo':
        return {
          'color': Colors.blue,
          'label': 'NA COZINHA',
          'progress': 0.5,
          'actionLabel': 'MARCAR COMO PRONTO',
          'nextStatus': 'pronto',
          'icon': Icons.room_service
        };
      case 'pronto':
        return {
          'color': Colors.green,
          'label': 'AGUARDANDO RETIRADA',
          'progress': 0.8,
          'actionLabel': 'ENTREGAR E FINALIZAR',
          'nextStatus': 'entregue',
          'icon': Icons.check_circle
        };
      case 'entregue':
        return {
          'color': Colors.grey,
          'label': 'CONCLUÍDO',
          'progress': 1.0,
          'actionLabel': null,
          'nextStatus': null,
          'icon': Icons.archive
        };
      default:
        return {
          'color': Colors.red,
          'label': 'CANCELADO',
          'progress': 0.0,
          'actionLabel': null,
          'nextStatus': null,
          'icon': Icons.cancel
        };
    }
  }

  // --- MODAL DE COMPROVANTE ---
  void _showProofDialog(String? url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de Título
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Comprovante do Cliente", style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Imagem com Zoom (InteractiveViewer)
            Flexible(
              child: Container(
                color: Colors.black,
                width: double.infinity,
                child: url != null
                    ? InteractiveViewer(
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (_, child, loading) {
                            if (loading == null) return child;
                            return const Center(child: CircularProgressIndicator(color: Colors.white));
                          },
                          errorBuilder: (_,__,___) => const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.white, size: 50),
                              SizedBox(height: 10),
                              Text("Erro ao carregar imagem", style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      )
                    : const Center(child: Text("Nenhuma imagem anexada", style: TextStyle(color: Colors.white))),
              ),
            ),

            // Botões de Decisão
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _updateStatus('cancelado', paymentStatus: 'rejeitado');
                      },
                      child: const Text("REJEITAR"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () {
                        Navigator.pop(ctx);
                        // Aprova o pagamento e já manda pra cozinha
                        _updateStatus('em_preparo', paymentStatus: 'aprovado');
                      },
                      child: const Text("APROVAR", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- LÓGICA DE ATUALIZAÇÃO ---
  Future<void> _updateStatus(String status, {String? paymentStatus}) async {
    setState(() => _isLoading = true);
    try {
      final updateData = {'status': status};
      if (paymentStatus != null) {
        updateData['payment_status'] = paymentStatus;
      }

      await Supabase.instance.client
          .from('orders')
          .update(updateData)
          .eq('id', widget.order['id']);

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erro: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dados Básicos
    final status = widget.order['status'] ?? 'pendente';
    final paymentStatus = widget.order['payment_status'] ?? 'pendente';
    final proofUrl = widget.order['proof_url']; // URL do comprovante
    final config = _getStatusConfig(status, paymentStatus);

    // Dados Relacionados (Joins)
    final items = List<Map<String, dynamic>>.from(widget.order['order_items'] ?? []);
    final tableName = widget.order['restaurant_tables']?['label'] ?? 'Mesa ?';
    final customerName = widget.order['profiles']?['full_name'] ?? 'Cliente';
    final total = (widget.order['total_amount'] as num).toDouble();
    final paymentDetails = widget.order['payment_details'] ?? '';
    
    // Data
    final createdAt = DateTime.parse(widget.order['created_at']).toLocal();
    final timeString = DateFormat('HH:mm').format(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config['color'].withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Barra de Status Colorida
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
                // 2. Cabeçalho
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("$tableName • $timeString", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text(customerName, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                          if (paymentDetails.toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(paymentDetails, style: TextStyle(color: Colors.blue[800], fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: config['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(config['icon'], size: 14, color: config['color']),
                          const SizedBox(width: 4),
                          Text(config['label'], style: TextStyle(color: config['color'], fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
                
                const Divider(height: 24),

                // 3. Itens
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                        child: Text("${item['quantity']}x", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['products']?['name'] ?? 'Item', style: const TextStyle(fontSize: 14)),
                            if (item['observation'] != null && item['observation'].toString().isNotEmpty)
                              Text("Obs: ${item['observation']}", style: const TextStyle(color: Colors.red, fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 16),

                // 4. Rodapé (Total + Ação)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("TOTAL", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text(_currencyFormat.format(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textDark)),
                      ],
                    ),
                    
                    if (config['actionLabel'] != null)
                      ElevatedButton.icon(
                        onPressed: _isLoading 
                          ? null 
                          : () {
                              if (config['nextStatus'] == 'VIEW_PROOF') {
                                _showProofDialog(proofUrl);
                              } else {
                                _updateStatus(config['nextStatus']);
                              }
                            },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: config['color'],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: Icon(config['icon'], size: 18),
                        label: _isLoading 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(config['actionLabel'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      )
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
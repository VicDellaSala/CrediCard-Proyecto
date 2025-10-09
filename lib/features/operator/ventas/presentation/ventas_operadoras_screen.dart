import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Ventas > Selección de Operadora y Plan
/// Lee los planes por línea desde `almacen_tarjetas/{lineaId}`
/// y muestra un ExpansionTile por cada línea: Digitel, Movistar, Publica.
/// Al seleccionar un plan, navega a /ventas/operadoras/serial con todos los datos.
class VentasOperadorasScreen extends StatelessWidget {
  const VentasOperadorasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);
  static const _collection = 'almacen_tarjetas';

  @override
  Widget build(BuildContext context) {
// 🔹 Datos que llegan desde VentasEquiposScreen
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final String? rif = args['rif'] as String?;
    final String? modeloSeleccionado = args['modeloSeleccionado'] as String?;
    final String? modeloId = args['modeloId'] as String?;
    final double? modeloPrecio =
    (args['precio'] is num) ? (args['precio'] as num).toDouble() : null;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Encabezado
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.sim_card, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Seleccionar operadora y plan',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido scrolleable
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(_collection)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text('Error: ${snap.error}'),
                    );
                  }

// Normalizamos por línea (Digitel / Movistar / Publica)
                  final Map<String, Map<String, dynamic>> lineas = {
                    'digitel': {},
                    'movistar': {},
                    'publica': {},
                  };
                  for (final d in (snap.data?.docs ?? const [])) {
                    final id = d.id.toString().trim().toLowerCase();
                    final data = d.data();
                    if (lineas.containsKey(id)) {
                      lineas[id] = data;
                    }
                  }

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      children: [
                        _LineaTile(
                          titulo: 'Línea: Digitel',
                          lineaId: 'digitel',
                          lineaName: 'Digitel',
                          data: lineas['digitel'] ?? const {},
                          onSelectPlan: (planIndex, planTitle, planDesc, planPrice) {
                            _irARegistroSerial(
                              context: context,
                              rif: rif, // 🔹 añadimos rif aquí
                              modeloSeleccionado: modeloSeleccionado,
                              modeloId: modeloId,
                              modeloPrecio: modeloPrecio,
                              lineaId: 'digitel',
                              lineaName: 'Digitel',
                              planIndex: planIndex,
                              planTitle: planTitle,
                              planDesc: planDesc,
                              planPrice: planPrice,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _LineaTile(
                          titulo: 'Línea: Movistar',
                          lineaId: 'movistar',
                          lineaName: 'Movistar',
                          data: lineas['movistar'] ?? const {},
                          onSelectPlan: (planIndex, planTitle, planDesc, planPrice) {
                            _irARegistroSerial(
                              context: context,
                              rif: rif, // 🔹 añadimos rif aquí
                              modeloSeleccionado: modeloSeleccionado,
                              modeloId: modeloId,
                              modeloPrecio: modeloPrecio,
                              lineaId: 'movistar',
                              lineaName: 'Movistar',
                              planIndex: planIndex,
                              planTitle: planTitle,
                              planDesc: planDesc,
                              planPrice: planPrice,
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _LineaTile(
                          titulo: 'Línea: Publica',
                          lineaId: 'publica',
                          lineaName: 'Publica',
                          data: lineas['publica'] ?? const {},
                          onSelectPlan: (planIndex, planTitle, planDesc, planPrice) {
                            _irARegistroSerial(
                              context: context,
                              rif: rif, // 🔹 añadimos rif aquí
                              modeloSeleccionado: modeloSeleccionado,
                              modeloId: modeloId,
                              modeloPrecio: modeloPrecio,
                              lineaId: 'publica',
                              lineaName: 'Publica',
                              planIndex: planIndex,
                              planTitle: planTitle,
                              planDesc: planDesc,
                              planPrice: planPrice,
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _irARegistroSerial({
    required BuildContext context,
    String? rif,
    String? modeloSeleccionado,
    String? modeloId,
    double? modeloPrecio,
    required String lineaId,
    required String lineaName,
    required int planIndex,
    required String planTitle,
    required String planDesc,
    required String planPrice,
  }) {
    Navigator.pushNamed(
      context,
      '/ventas/operadoras/serial',
      arguments: {
        'rif': rif, // 🔹 reenviamos rif también
        'modeloSeleccionado': modeloSeleccionado,
        'modeloId': modeloId,
        'modeloPrecio': modeloPrecio,
        'lineaId': lineaId,
        'lineaName': lineaName,
        'planIndex': planIndex,
        'planTitle': planTitle,
        'planDesc': planDesc,
        'planPrice': planPrice,
      },
    );
  }
}

/// ---------------------------------------------------------------------------
/// Tile por línea (ExpansionTile) que pinta hasta 3 planes
class _LineaTile extends StatelessWidget {
  final String titulo;
  final String lineaId;
  final String lineaName;
  final Map<String, dynamic> data;
  final void Function(int planIndex, String title, String desc, String price)
  onSelectPlan;

  const _LineaTile({
    required this.titulo,
    required this.lineaId,
    required this.lineaName,
    required this.data,
    required this.onSelectPlan,
  });

  @override
  Widget build(BuildContext context) {
// Plan 1 (obligatorio)
    final p1Title = (data['plan1_title'] ?? '').toString();
    final p1Desc = (data['plan1_desc'] ?? '').toString();
    final p1Price = _priceToString(data['plan1_price']);

// Planes opcionales
    final p2Title = (data['plan2_title'] ?? '').toString();
    final p2Desc = (data['plan2_desc'] ?? '').toString();
    final p2Price = _priceToString(data['plan2_price']);

    final p3Title = (data['plan3_title'] ?? '').toString();
    final p3Desc = (data['plan3_desc'] ?? '').toString();
    final p3Price = _priceToString(data['plan3_price']);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Row(
          children: [
            const Icon(Icons.hub, color: Colors.black54),
            const SizedBox(width: 10),
            Text(
              titulo,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        children: [
// Plan 1
          _PlanCard(
            requiredLabel: ' (obligatorio)',
            title: p1Title.isEmpty ? 'Plan 1' : p1Title,
            desc: p1Desc,
            price: p1Price,
            onSelect: () => onSelectPlan(1, p1Title.isEmpty ? 'Plan 1' : p1Title, p1Desc, p1Price),
          ),
          const SizedBox(height: 8),

// Plan 2
          if (p2Title.isNotEmpty || p2Desc.isNotEmpty || p2Price.isNotEmpty) ...[
            _PlanCard(
              title: p2Title.isEmpty ? 'Plan 2' : p2Title,
              desc: p2Desc,
              price: p2Price,
              onSelect: () => onSelectPlan(2, p2Title.isEmpty ? 'Plan 2' : p2Title, p2Desc, p2Price),
            ),
            const SizedBox(height: 8),
          ],

// Plan 3
          if (p3Title.isNotEmpty || p3Desc.isNotEmpty || p3Price.isNotEmpty) ...[
            _PlanCard(
              title: p3Title.isEmpty ? 'Plan 3' : p3Title,
              desc: p3Desc,
              price: p3Price,
              onSelect: () => onSelectPlan(3, p3Title.isEmpty ? 'Plan 3' : p3Title, p3Desc, p3Price),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  static String _priceToString(dynamic v) {
    if (v == null) return '';
    if (v is int) return '\$${v.toStringAsFixed(2)}';
    if (v is double) return '\$${v.toStringAsFixed(2)}';
    if (v is String) {
      final n = double.tryParse(v.replaceAll('\$', '').trim());
      return n == null ? v : '\$${n.toStringAsFixed(2)}';
    }
    return '';
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String desc;
  final String price;
  final String requiredLabel;
  final VoidCallback onSelect;

  const _PlanCard({
    required this.title,
    required this.desc,
    required this.price,
    this.requiredLabel = '',
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E9EC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
// Título
          Text(
            '$title$requiredLabel',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),

// Descripción
          if (desc.isNotEmpty) ...[
            _MultilinePreview(
              label: 'Descripción',
              text: desc,
              maxLines: 3,
            ),
            const SizedBox(height: 6),
          ],

// Precio
          if (price.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.sell_outlined, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Precio: $price',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

// Botón seleccionar
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onSelect,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Seleccionar plan'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MultilinePreview extends StatelessWidget {
  final String label;
  final String text;
  final int maxLines;

  const _MultilinePreview({
    required this.label,
    required this.text,
    this.maxLines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          text,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(label),
                content: SingleChildScrollView(child: Text(text)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cerrar'),
                  )
                ],
              ),
            ),
            child: const Text('Ver más'),
          ),
        ),
      ],
    );
  }
}

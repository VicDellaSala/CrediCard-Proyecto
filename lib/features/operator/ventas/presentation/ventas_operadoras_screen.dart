import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VentasOperadorasScreen extends StatelessWidget {
  const VentasOperadorasScreen({
    super.key,
    required this.rif,
    this.modeloSeleccionado,
  });

  /// RIF del cliente actual (pásalo desde tu flujo de ventas)
  final String rif;

  /// (opcional) el modelo de POS seleccionado previamente (si ya lo tienes)
  final String? modeloSeleccionado;

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header celeste
            Container(
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const Spacer(),
                  const Text(
                    'Seleccionar operadora y plan',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('almacen_tarjetas')
                    .orderBy('linea_id') // asumiendo que guardas digitel/movistar/publica
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

                  final docs = snap.data?.docs ?? const [];
                  if (docs.isEmpty) {
                    return const Center(child: Text('No hay líneas (tarjetas) registradas.'));
                  }

// Layout tipo grid flexible (2 o 3 columnas según ancho)
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 1000;
                      final crossAxisCount = isWide ? 3 : 1;

                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: isWide ? 1.10 : 0.85,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i].data();
                          final docId = docs[i].id;
                          final linea = (d['linea'] ?? '').toString();
                          final lineaId = (d['linea_id'] ?? docId).toString();

// Planes (cualquiera puede estar vacío, el Plan 1 suele ser obligatorio)
                          final p1Title = (d['plan1_title'] ?? 'Plan 1').toString();
                          final p1Desc = (d['plan1_desc'] ?? '').toString();
                          final p1Price = (d['plan1_price'] ?? '').toString();

                          final p2Title = (d['plan2_title'] ?? 'Plan 2').toString();
                          final p2Desc = (d['plan2_desc'] ?? '').toString();
                          final p2Price = (d['plan2_price'] ?? '').toString();

                          final p3Title = (d['plan3_title'] ?? 'Plan 3').toString();
                          final p3Desc = (d['plan3_desc'] ?? '').toString();
                          final p3Price = (d['plan3_price'] ?? '').toString();

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.sim_card, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Línea: $linea',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),

// Los 3 planes como tarjetas internas
                                _PlanCard(
                                  title: p1Title,
                                  desc: p1Desc,
                                  price: p1Price,
                                  requiredLabel: ' (obligatorio)',
                                  onSelect: () => _goSerial(context, lineaId, linea, 1, p1Title, p1Desc, p1Price),
                                ),
                                if (p2Title.trim().isNotEmpty || p2Desc.trim().isNotEmpty || p2Price.trim().isNotEmpty)
                                  _PlanCard(
                                    title: p2Title,
                                    desc: p2Desc,
                                    price: p2Price,
                                    onSelect: () => _goSerial(context, lineaId, linea, 2, p2Title, p2Desc, p2Price),
                                  ),
                                if (p3Title.trim().isNotEmpty || p3Desc.trim().isNotEmpty || p3Price.trim().isNotEmpty)
                                  _PlanCard(
                                    title: p3Title,
                                    desc: p3Desc,
                                    price: p3Price,
                                    onSelect: () => _goSerial(context, lineaId, linea, 3, p3Title, p3Desc, p3Price),
                                  ),
                                const Spacer(),
                                if (modeloSeleccionado != null) ...[
                                  const Divider(height: 20),
                                  Text(
                                    'Modelo seleccionado: $modeloSeleccionado',
                                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _goSerial(
      BuildContext context,
      String lineaId,
      String lineaName,
      int planIndex,
      String planTitle,
      String planDesc,
      String planPrice,
      ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VentasRegistroSerialScreen(
          rif: rif,
          lineaId: lineaId,
          lineaName: lineaName,
          planIndex: planIndex,
          planTitle: planTitle,
          planDesc: planDesc,
          planPrice: planPrice,
          modeloSeleccionado: modeloSeleccionado,
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.desc,
    required this.price,
    this.requiredLabel = '',
    required this.onSelect,
  });

  final String title;
  final String desc;
  final String price;
  final String requiredLabel;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${title.trim().isEmpty ? 'Plan' : title}$requiredLabel',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
          if (desc.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(desc, style: const TextStyle(fontSize: 13)),
          ],
          if (price.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('Precio: $price', style: const TextStyle(fontSize: 13)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSelect,
              child: const Text('Seleccionar plan'),
            ),
          )
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// >>> Si tu colección se llama distinto, cambia esto:
const String kPVEquiposCollection = 'puntos_venta_equipos';

class AlmacenVerEquiposScreen extends StatelessWidget {
  const AlmacenVerEquiposScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header celestito
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
                    'Almacén · Equipos existentes',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection(kPVEquiposCollection)
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
                    return const Center(
                      child: Text('No hay equipos registrados.'),
                    );
                  }

// Agrupar por modelo y sumar cantidades totales + desglose por operadora
                  final Map<String, int> totalPorModelo = {};
                  final Map<String, Map<String, int>> desglosePorModelo = {};

                  for (final d in docs) {
                    final data = d.data();
                    final modelo = (data['modelo'] ?? '').toString().trim();
                    if (modelo.isEmpty) continue;

                    final cant = (data['cantidad'] is int)
                        ? data['cantidad'] as int
                        : int.tryParse('${data['cantidad']}') ?? 0;

                    final operadora = (data['operadora'] ?? '').toString().trim();
                    totalPorModelo.update(modelo, (prev) => prev + cant, ifAbsent: () => cant);

                    final mapa = desglosePorModelo.putIfAbsent(modelo, () => <String, int>{});
                    final keyOp = _normalizaOperadora(operadora);
                    mapa.update(keyOp, (prev) => prev + cant, ifAbsent: () => cant);
                  }

                  final modelos = totalPorModelo.keys.toList()
                    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

// Total global
                  final totalGlobal = totalPorModelo.values.fold<int>(0, (s, v) => s + v);

                  return Column(
                    children: [
// Total global visible arriba
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2, color: Colors.black87),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Equipos disponibles (todas las operadoras): $totalGlobal',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

// Lista por modelo
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (_, i) {
                            final modelo = modelos[i];
                            final total = totalPorModelo[modelo] ?? 0;
                            final desglose = desglosePorModelo[modelo] ?? const {};

                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => _ModeloDetalleScreen(
                                      modelo: modelo,
                                      total: total,
                                      desglose: desglose,
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.devices_other, color: Colors.black87),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            modelo,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Unidades totales: $total'),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemCount: modelos.length,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _normalizaOperadora(String raw) {
    final v = raw.trim().toLowerCase();
    if (v == 'movistar') return 'Movistar';
    if (v == 'digitel') return 'Digitel';
    if (v == 'pública' || v == 'publica') return 'Pública';
    return 'Otros';
  }
}

/// ---------------------------------------------------------------------------
/// Detalle por modelo: muestra desglose y permite añadir más cantidad.
class _ModeloDetalleScreen extends StatefulWidget {
  final String modelo;
  final int total;
  final Map<String, int> desglose;

  const _ModeloDetalleScreen({
    required this.modelo,
    required this.total,
    required this.desglose,
  });

  @override
  State<_ModeloDetalleScreen> createState() => _ModeloDetalleScreenState();
}

class _ModeloDetalleScreenState extends State<_ModeloDetalleScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final movistar = widget.desglose['Movistar'] ?? 0;
    final digitel = widget.desglose['Digitel'] ?? 0;
    final publica = widget.desglose['Pública'] ?? 0;
    final otros = widget.desglose.entries
        .where((e) => e.key != 'Movistar' && e.key != 'Digitel' && e.key != 'Pública')
        .fold<int>(0, (sum, e) => sum + e.value);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header
            Container(
              decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
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
                  Text(
                    'Modelo: ${widget.modelo}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _cardDesglose('Movistar', movistar, Icons.network_cell),
                      const SizedBox(height: 10),
                      _cardDesglose('Digitel', digitel, Icons.signal_cellular_alt),
                      const SizedBox(height: 10),
                      _cardDesglose('Pública', publica, Icons.public),
                      if (otros > 0) ...[
                        const SizedBox(height: 10),
                        _cardDesglose('Otros', otros, Icons.help_outline),
                      ],
                      const SizedBox(height: 18),
                      _cardTotal(widget.total),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _onAddPressed,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir más cantidad'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardDesglose(String label, int value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
          Text('$value', style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _cardTotal(int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          const Icon(Icons.summarize, color: Colors.black54),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('Total unidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Text('$total', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Future<void> _onAddPressed() async {
    final result = await showDialog<_AddUnitsResult>(
      context: context,
      builder: (_) => const _AddUnitsDialog(),
    );

    if (result == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection(kPVEquiposCollection).add({
        'modelo': widget.modelo,
        'cantidad': result.cantidad,
        'operadora': result.operadora, // Movistar | Digitel | Pública
        'serial': result.serial?.isEmpty == true ? null : result.serial,
        'sin_serial': (result.serial == null || result.serial!.isEmpty),
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Se añadieron ${result.cantidad} a ${result.operadora}')),
      );

// Volver automáticamente para ver el total actualizado o quedarte.
// Navigator.pop(context);
      setState(() {}); // refresca detalle (si estás sumando local, no necesario con streams)
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')),
      );
    }
  }
}

/// ------------------------ Diálogo para añadir más ---------------------------

class _AddUnitsResult {
  final String operadora;
  final int cantidad;
  final String? serial;
  const _AddUnitsResult({required this.operadora, required this.cantidad, this.serial});
}

class _AddUnitsDialog extends StatefulWidget {
  const _AddUnitsDialog();

  @override
  State<_AddUnitsDialog> createState() => _AddUnitsDialogState();
}

class _AddUnitsDialogState extends State<_AddUnitsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();

  final _ops = const ['Movistar', 'Digitel', 'Pública'];
  String? _operadora;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir cantidad'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Operadora',
                  border: OutlineInputBorder(),
                ),
                items: _ops.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                value: _operadora,
                onChanged: (v) => setState(() => _operadora = v),
                validator: (v) => v == null ? 'Selecciona una operadora' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cantidadCtrl,
                decoration: const InputDecoration(
                  labelText: 'Cantidad',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  if (n == null || n <= 0) return 'Ingresa una cantidad válida (> 0)';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serialCtrl,
                decoration: const InputDecoration(
                  labelText: 'Serial (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final cantidad = int.parse(_cantidadCtrl.text.trim());
            final res = _AddUnitsResult(
              operadora: _operadora!,
              cantidad: cantidad,
              serial: _serialCtrl.text.trim().isEmpty ? null : _serialCtrl.text.trim(),
            );
            Navigator.pop(context, res);
          },
          child: const Text('Guardar'),
        )
      ],
    );
  }
}

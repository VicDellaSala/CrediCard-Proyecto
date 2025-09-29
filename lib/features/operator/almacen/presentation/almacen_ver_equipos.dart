import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Estructura en Firestore:
/// almacen_pdv/{modeloId}
/// - modelo: "Castlle"
/// - modelo_id: "castlle"
/// - updatedAt: ts
/// subcolección equipos/{serial_lower}
/// - serial: "UJ789"
/// - serial_lower: "uj789"
/// - createdAt: ts
/// - createdBy: uid
const String kAlmacenPdv = 'almacen_pdv';
const String kSubEquipos = 'equipos';

class AlmacenVerEquiposScreen extends StatelessWidget {
  const AlmacenVerEquiposScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final modelosStream = FirebaseFirestore.instance
        .collection(kAlmacenPdv)
        .orderBy('modelo_id')
        .snapshots();

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
                stream: modelosStream,
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
                      child: Text('No hay modelos registrados en el almacén.'),
                    );
                  }

// GRID de tarjetas grandes (responsivo simple)
                  return LayoutBuilder(
                    builder: (context, c) {
                      final w = c.maxWidth;
                      final crossCount = w >= 1000 ? 3 : (w >= 650 ? 2 : 1);

                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.9,
                        ),
                        itemCount: docs.length,
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          final data = d.data();
                          final modelo = (data['modelo'] ?? '').toString();
                          final modeloId = (data['modelo_id'] ?? '').toString();
                          final docRef = d.reference;

                          return _ModeloCard(
                            modelo: modelo,
                            modeloId: modeloId,
                            ref: docRef,
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
}

class _ModeloCard extends StatelessWidget {
  final String modelo;
  final String modeloId;
  final DocumentReference<Map<String, dynamic>> ref;

  const _ModeloCard({
    required this.modelo,
    required this.modeloId,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
// Contador de seriales (sin orderBy para no exigir campos)
    final countStream = ref.collection(kSubEquipos).snapshots();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _ModeloDetalleScreen(
              modelo: modelo,
              modeloId: modeloId,
              ref: ref,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.devices_other, size: 34, color: Colors.black87),
            const SizedBox(height: 10),
            Text(
              modelo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: countStream,
              builder: (context, snap) {
                final total = (snap.data?.docs.length ?? 0);
                return Text(
                  'Seriales disponibles: $total',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Detalle del modelo: lista de seriales + botón para añadir serial
class _ModeloDetalleScreen extends StatelessWidget {
  final String modelo;
  final String modeloId;
  final DocumentReference<Map<String, dynamic>> ref;

  const _ModeloDetalleScreen({
    required this.modelo,
    required this.modeloId,
    required this.ref,
  });

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
// ⚠️ SIN orderBy para que incluya docs viejos sin serial_lower
    final serialesStream = ref.collection(kSubEquipos).snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddSerial(context),
        icon: const Icon(Icons.add),
        label: const Text('Añadir serial'),
      ),
      body: SafeArea(
        child: Column(
          children: [
// Header
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
                  Text(
                    'Modelo: $modelo',
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: serialesStream,
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

                  final raw = snap.data?.docs ?? const [];
                  if (raw.isEmpty) {
                    return const Center(
                      child: Text('No hay seriales cargados para este modelo.'),
                    );
                  }

// Ordenar en cliente por serial (o serial_lower si existe)
                  final items = raw
                      .map((d) => d.data())
                      .toList()
                    ..sort((a, b) {
                      final sa = (a['serial_lower'] ?? a['serial'] ?? '').toString();
                      final sb = (b['serial_lower'] ?? b['serial'] ?? '').toString();
                      return sa.compareTo(sb);
                    });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final data = items[i];
                      final serial = (data['serial'] ?? '').toString();

                      return Container(
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
                            const Icon(Icons.qr_code, color: Colors.black54),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                serial.isEmpty ? '(sin serial)' : serial,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Future<void> _onAddSerial(BuildContext context) async {
    final res = await showDialog<String?>(
      context: context,
      builder: (_) => const _AddSerialDialog(),
    );
    if (res == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión.')),
      );
      return;
    }

    final serial = res.trim().toUpperCase();
    final serialLower = serial.toLowerCase();

    try {
      final docRef = ref.collection(kSubEquipos).doc(serialLower);
      final exists = await docRef.get();
      if (exists.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El serial $serial ya existe en este modelo.')),
        );
        return;
      }

      await docRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

// actualiza updatedAt del modelo por conveniencia
      await ref.update({'updatedAt': FieldValue.serverTimestamp()});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serial $serial añadido a $modelo')),
      );
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')),
      );
    }
  }
}

class _AddSerialDialog extends StatefulWidget {
  const _AddSerialDialog();

  @override
  State<_AddSerialDialog> createState() => _AddSerialDialogState();
}

class _AddSerialDialogState extends State<_AddSerialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir serial'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: _ctrl,
            decoration: const InputDecoration(
              labelText: 'Serial (formato AA999, ej: UJ789)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim();
              final reg = RegExp(r'^[A-Za-z]{2}\d{3}$');
              if (!reg.hasMatch(s)) {
                return 'Formato inválido. Usa 2 letras + 3 números (ej: UJ789)';
              }
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, null), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _ctrl.text.trim().toUpperCase());
          },
          child: const Text('Guardar'),
        )
      ],
    );
  }
}

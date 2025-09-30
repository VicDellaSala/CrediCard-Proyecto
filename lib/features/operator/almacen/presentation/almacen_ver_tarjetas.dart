import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Colecciones usadas para TARJETAS de operadoras
const String kTarjRoot = 'almacen_tarjetas'; // doc por línea: digitel / movistar / publica
const String kSubTarjetas = 'tarjetas'; // subcolección con documentos por serial

/// ╔═══════════════════════════════════════════════════════════════════╗
/// ║ Lista de líneas (Digitel / Movistar / Pública) con conteo total ║
/// ╚═══════════════════════════════════════════════════════════════════╝
class AlmacenVerTarjetasOperadorasScreen extends StatelessWidget {
  const AlmacenVerTarjetasOperadorasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);
  static const _lines = <String>['Digitel', 'Movistar', 'Publica'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Encabezado celestito
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
                  const Spacer(),
                  const Text(
                    'Almacén · Ver tarjetas',
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
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _lines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final linea = _lines[i];
                  final lineaId = _lineId(linea);

// StreamBuilder para contar cuántos seriales hay en esa línea
                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection(kTarjRoot)
                        .doc(lineaId)
                        .collection(kSubTarjetas)
                        .snapshots(),
                    builder: (context, snap) {
                      final total = snap.hasData ? snap.data!.docs.length : 0;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AlmacenVerTarjetasScreen(linea: linea),
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
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.apartment, color: Colors.black87),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      linea,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Seriales disponibles: $total'),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
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

  static String _lineId(String name) {
    final v = name.trim().toLowerCase();
    if (v == 'pública') return 'publica';
    return v;
  }
}

/// ╔═══════════════════════════════════════════════════════════════════╗
/// ║ Detalle de una línea: lista de seriales + botón “Añadir serial” ║
/// ╚═══════════════════════════════════════════════════════════════════╝
class AlmacenVerTarjetasScreen extends StatelessWidget {
  final String linea;
  const AlmacenVerTarjetasScreen({super.key, required this.linea});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final lineaId = _lineId(linea);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header
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
                  const Spacer(),
                  Text(
                    'Línea: $linea',
                    style: const TextStyle(
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
                    .collection(kTarjRoot)
                    .doc(lineaId)
                    .collection(kSubTarjetas)
                    .orderBy('serial_lower') // orden alfabético por id en minúsculas
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
                      child: Text('No hay seriales cargados para esta línea.'),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final data = docs[i].data();
                      final serial = (data['serial'] ?? '').toString();
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.credit_card, color: Colors.black87),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    serial,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (createdAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cargado: $createdAt',
                                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                                    ),
                                  ],
                                ],
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

// FAB para añadir nuevo serial (valida LLDD)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onAddSerial(context, lineaId, linea),
        icon: const Icon(Icons.add),
        label: const Text('Añadir serial'),
      ),
    );
  }

  static String _lineId(String name) {
    final v = name.trim().toLowerCase();
    if (v == 'pública') return 'publica';
    return v;
  }

  Future<void> _onAddSerial(BuildContext context, String lineaId, String linea) async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const _AddSerialDialog(),
    );
    if (res == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
        );
      }
      return;
    }

    final serial = res.trim().toUpperCase(); // EJ: BU67
    final serialLower = serial.toLowerCase(); // id del doc

    try {
      final root = FirebaseFirestore.instance.collection(kTarjRoot);
      final lineRef = root.doc(lineaId);
      final lineDoc = await lineRef.get();

// si la línea aún no existe, se crea
      if (!lineDoc.exists) {
        await lineRef.set({
          'linea': linea,
          'linea_id': lineaId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final serialRef = lineRef.collection(kSubTarjetas).doc(serialLower);
      final already = await serialRef.get();
      if (already.exists) {
        throw FirebaseException(plugin: 'firestore', code: 'already-exists', message: 'El serial ya existe');
      }

      await serialRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      await lineRef.update({'updatedAt': FieldValue.serverTimestamp()});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Añadido $serial a $linea')),
        );
      }
    } on FirebaseException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message ?? e.code}')),
        );
      }
    }
  }
}

/// ╔═══════════════════════════════════════════════════════════════════╗
/// ║ Diálogo para capturar serial con validación EXACTA LLDD (BU67) ║
/// ╚═══════════════════════════════════════════════════════════════════╝
class _AddSerialDialog extends StatefulWidget {
  const _AddSerialDialog();

  @override
  State<_AddSerialDialog> createState() => _AddSerialDialogState();
}

class _AddSerialDialogState extends State<_AddSerialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

// Dos letras (A-Z) + dos números (0-9), p.ej. BU67
  final _re = RegExp(r'^[A-Z]{2}\d{2}$');

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
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Serial (formato: LLDD, ej: BU67)',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final txt = (v ?? '').trim().toUpperCase();
              if (!_re.hasMatch(txt)) return 'Formato inválido. Usa 2 letras + 2 números (ej: BU67)';
              return null;
            },
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _ctrl.text.trim().toUpperCase());
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

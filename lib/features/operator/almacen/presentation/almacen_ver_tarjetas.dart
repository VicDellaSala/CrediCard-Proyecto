import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ====================== CONSTANTES DE FIRESTORE ======================
const String kAlmacenTarjetasRoot = 'almacen_tarjetas'; // colección raíz por línea
const String kSubTarjetas = 'tarjetas'; // subcolección de seriales
const Color _panelColor = Color(0xFFAED6D8);

/// ====================================================================
/// LISTADO DE LÍNEAS (con total de seriales disponibles por línea)
class AlmacenVerTarjetasOperadorasScreen extends StatelessWidget {
  const AlmacenVerTarjetasOperadorasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colRef = FirebaseFirestore.instance.collection(kAlmacenTarjetasRoot);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
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
                  const Text(
                    'Almacén · Tarjetas de operadoras',
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
                stream: colRef.snapshots(),
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

                  final lineas = snap.data?.docs ?? const [];
                  if (lineas.isEmpty) {
                    return const Center(
                      child: Text('No hay líneas registradas.'),
                    );
                  }

                  final sorted = [...lineas]..sort((a, b) {
                    final la = (a.data()['linea'] ?? a.id).toString().toLowerCase();
                    final lb = (b.data()['linea'] ?? b.id).toString().toLowerCase();
                    return la.compareTo(lb);
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final d = sorted[i];
                      final data = d.data();
                      final lineaId = d.id;
                      final nombreLinea = (data['linea'] ?? lineaId).toString();
                      final subRef = colRef.doc(lineaId).collection(kSubTarjetas);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _LineaDetalleScreen(
                                lineaId: lineaId,
                                nombreLinea: nombreLinea,
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
                              const Icon(Icons.sim_card, color: Colors.black87),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      nombreLinea,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                                      future: subRef.get(),
                                      builder: (context, countSnap) {
                                        if (countSnap.connectionState == ConnectionState.waiting) {
                                          return const Text('Seriales disponibles: —');
                                        }
                                        final total = countSnap.data?.docs.length ?? 0;
                                        return Text('Seriales disponibles: $total');
                                      },
                                    ),
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
}

/// ====================================================================
/// DETALLE DE LÍNEA: lista de seriales + acción de añadir y eliminar
class _LineaDetalleScreen extends StatefulWidget {
  final String lineaId;
  final String nombreLinea;

  const _LineaDetalleScreen({
    required this.lineaId,
    required this.nombreLinea,
  });

  @override
  State<_LineaDetalleScreen> createState() => _LineaDetalleScreenState();
}

class _LineaDetalleScreenState extends State<_LineaDetalleScreen> {
  late final DocumentReference<Map<String, dynamic>> _lineaRef;
  late final CollectionReference<Map<String, dynamic>> _serialsRef;

  @override
  void initState() {
    super.initState();
    _lineaRef = FirebaseFirestore.instance
        .collection(kAlmacenTarjetasRoot)
        .doc(widget.lineaId);
    _serialsRef = _lineaRef.collection(kSubTarjetas);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onAddSerial,
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
                    'Línea: ${widget.nombreLinea}',
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
                stream: _serialsRef.snapshots(),
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

                  final serialDocs = snap.data?.docs ?? const [];
                  if (serialDocs.isEmpty) {
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: _card(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Acciones de seriales',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: _onDeleteSerial,
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('Eliminar serial'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text('No hay seriales cargados para esta línea.'),
                          ),
                        ),
                      ],
                    );
                  }

                  final items = serialDocs
                      .map((d) => d.data())
                      .toList()
                    ..sort((a, b) {
                      final sa = (a['serial_lower'] ?? a['serial'] ?? '').toString();
                      final sb = (b['serial_lower'] ?? b['serial'] ?? '').toString();
                      return sa.compareTo(sb);
                    });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length + 1, // +1 tarjeta de acciones arriba
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Acciones de seriales',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              OutlinedButton.icon(
                                onPressed: _onDeleteSerial,
                                icon: const Icon(Icons.delete_outline),
                                label: const Text('Eliminar serial'),
                              ),
                            ],
                          ),
                        );
                      }

                      final s = items[i - 1];
                      final serial = (s['serial'] ?? '').toString();
                      final createdAt = (s['createdAt'] as Timestamp?)?.toDate();

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                            const Icon(Icons.confirmation_number_outlined),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                serial.isEmpty ? '(sin serial)' : serial,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            if (createdAt != null)
                              Text(
                                '${createdAt.toLocal()}',
                                style: const TextStyle(fontSize: 12, color: Colors.black54),
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

  /// --------------------------- Helpers UI ---------------------------
  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }

  /// --------------------------- Serial: Añadir / Eliminar ---------------------------
  Future<void> _onAddSerial() async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const _AddSerialDialog(),
    );
    if (res == null) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
      );
      return;
    }

    final serial = res.trim().toUpperCase();
    final serialLower = serial.toLowerCase();

    try {
      final docRef = _serialsRef.doc(serialLower);
      final exists = await docRef.get();
      if (exists.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('El serial $serial ya existe en esta línea.')));
        return;
      }

      await docRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      await _lineaRef.set({
        'linea': widget.nombreLinea,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Añadido $serial a ${widget.nombreLinea}')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message ?? e.code}')));
    }
  }

  Future<void> _onDeleteSerial() async {
    final res = await showDialog<String>(
      context: context,
      builder: (_) => const _DeleteSerialDialog(),
    );
    if (res == null) return;

    final serial = res.trim().toUpperCase();
    if (serial.isEmpty) return;

    final serialLower = serial.toLowerCase();

    try {
      final docRef = _serialsRef.doc(serialLower);
      final doc = await docRef.get();
      if (!doc.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El serial $serial no existe en ${widget.nombreLinea}.')),
        );
        return;
      }

      await docRef.delete();
      await _lineaRef.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serial $serial eliminado de ${widget.nombreLinea}')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.message ?? e.code}')));
    }
  }
}

/// ====================================================================
/// Diálogo para añadir un serial (valida letras+números)
class _AddSerialDialog extends StatefulWidget {
  const _AddSerialDialog();

  @override
  State<_AddSerialDialog> createState() => _AddSerialDialogState();
}

class _AddSerialDialogState extends State<_AddSerialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();

  @override
  void dispose() {
    _serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Añadir serial de tarjeta'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: 'Serial (ej. BU67)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa un serial';
              final ok = RegExp(r'^[A-Za-z0-9\-_.]+$').hasMatch(s);
              if (!ok) return 'Caracteres inválidos';
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
            Navigator.pop(context, _serialCtrl.text.trim());
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// ====================================================================
/// Diálogo para eliminar un serial (debe ingresar el serial exacto)
class _DeleteSerialDialog extends StatefulWidget {
  const _DeleteSerialDialog();

  @override
  State<_DeleteSerialDialog> createState() => _DeleteSerialDialogState();
}

class _DeleteSerialDialogState extends State<_DeleteSerialDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();

  @override
  void dispose() {
    _serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Eliminar serial de tarjeta'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: 'Serial exacto (ej. BU67)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa el serial a eliminar';
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
            Navigator.pop(context, _serialCtrl.text.trim());
          },
          child: const Text('Eliminar'),
        ),
      ],
    );
  }
}

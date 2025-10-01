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
/// DETALLE DE LÍNEA: lista de seriales + acción de añadir/eliminar + EDITAR PLANES
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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _lineaRef.snapshots(),
          builder: (context, lineSnap) {
            final lineaData = lineSnap.data?.data() ?? {};
            final plan1Title = (lineaData['plan1_title'] ?? '').toString();
            final plan1Desc = (lineaData['plan1_desc'] ?? '').toString();
            final plan1PriceAny = lineaData['plan1_price'];
            final plan1Price = _asDouble(plan1PriceAny);

            final plan2Title = (lineaData['plan2_title'] ?? '').toString();
            final plan2Desc = (lineaData['plan2_desc'] ?? '').toString();
            final plan2Price = _asDouble(lineaData['plan2_price']);

            final plan3Title = (lineaData['plan3_title'] ?? '').toString();
            final plan3Desc = (lineaData['plan3_desc'] ?? '').toString();
            final plan3Price = _asDouble(lineaData['plan3_price']);

            return Column(
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
                  child: Column(
                    children: [
// ---- Tarjeta de Planes ----
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: _card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.list_alt_outlined),
                                  const SizedBox(width: 8),
                                  const Expanded(
                                    child: Text(
                                      'Planes de la línea',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _onEditPlanes(
                                      plan1Title: plan1Title,
                                      plan1Desc: plan1Desc,
                                      plan1Price: plan1Price,
                                      plan2Title: plan2Title,
                                      plan2Desc: plan2Desc,
                                      plan2Price: plan2Price,
                                      plan3Title: plan3Title,
                                      plan3Desc: plan3Desc,
                                      plan3Price: plan3Price,
                                    ),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Editar planes'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _planTile(context, 'Plan 1 (obligatorio)', plan1Title, plan1Desc, plan1Price),
                              const SizedBox(height: 8),
                              if (plan2Title.isNotEmpty || plan2Desc.isNotEmpty || plan2Price != null)
                                _planTile(context, 'Plan 2', plan2Title, plan2Desc, plan2Price),
                              if (plan2Title.isNotEmpty || plan2Desc.isNotEmpty || plan2Price != null)
                                const SizedBox(height: 8),
                              if (plan3Title.isNotEmpty || plan3Desc.isNotEmpty || plan3Price != null)
                                _planTile(context, 'Plan 3', plan3Title, plan3Desc, plan3Price),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

// ---- Lista de Seriales ----
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
              ],
            );
          },
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

  Widget _planTile(
      BuildContext context,
      String label,
      String title,
      String desc,
      double? price,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text('Título: ${title.isEmpty ? '—' : title}'),
          const SizedBox(height: 4),
          Text('Descripción: ${desc.isEmpty ? '—' : desc}'),
          const SizedBox(height: 4),
          Text('Precio: ${price == null ? '—' : '\$${price.toStringAsFixed(2)}'}'),
        ],
      ),
    );
  }

  double? _asDouble(dynamic v) {
    return switch (v) {
      int x => x.toDouble(),
      double x => x,
      String s => double.tryParse(s),
      _ => null,
    };
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

  /// --------------------------- Editar Planes ---------------------------
  Future<void> _onEditPlanes({
    required String plan1Title,
    required String plan1Desc,
    required double? plan1Price,
    required String plan2Title,
    required String plan2Desc,
    required double? plan2Price,
    required String plan3Title,
    required String plan3Desc,
    required double? plan3Price,
  }) async {
    final res = await showDialog<_PlanesResult>(
      context: context,
      builder: (_) => _EditPlanesDialog(
        lineaName: widget.nombreLinea,
        p1Title: plan1Title,
        p1Desc: plan1Desc,
        p1Price: plan1Price,
        p2Title: plan2Title,
        p2Desc: plan2Desc,
        p2Price: plan2Price,
        p3Title: plan3Title,
        p3Desc: plan3Desc,
        p3Price: plan3Price,
      ),
    );
    if (res == null) return;

    final Map<String, dynamic> payload = {
      'plan1_title': res.p1Title.trim(),
      'plan1_desc': res.p1Desc.trim(),
      'plan1_price': res.p1Price,
// opcionales (si están vacíos, los guardo como vacío/null sin problema)
      'plan2_title': res.p2Title.trim(),
      'plan2_desc': res.p2Desc.trim(),
      'plan2_price': res.p2Price,
      'plan3_title': res.p3Title.trim(),
      'plan3_desc': res.p3Desc.trim(),
      'plan3_price': res.p3Price,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await _lineaRef.set(payload, SetOptions(merge: true));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Planes actualizados')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar planes: ${e.message ?? e.code}')),
      );
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

/// ====================================================================
/// Diálogo para editar los 3 planes (Plan 1 obligatorio; 2 y 3 opcionales)
class _EditPlanesDialog extends StatefulWidget {
  final String lineaName;
  final String p1Title;
  final String p1Desc;
  final double? p1Price;
  final String p2Title;
  final String p2Desc;
  final double? p2Price;
  final String p3Title;
  final String p3Desc;
  final double? p3Price;

  const _EditPlanesDialog({
    required this.lineaName,
    required this.p1Title,
    required this.p1Desc,
    required this.p1Price,
    required this.p2Title,
    required this.p2Desc,
    required this.p2Price,
    required this.p3Title,
    required this.p3Desc,
    required this.p3Price,
  });

  @override
  State<_EditPlanesDialog> createState() => _EditPlanesDialogState();
}

class _EditPlanesDialogState extends State<_EditPlanesDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _p1Title;
  late final TextEditingController _p1Desc;
  late final TextEditingController _p1Price;

  late final TextEditingController _p2Title;
  late final TextEditingController _p2Desc;
  late final TextEditingController _p2Price;

  late final TextEditingController _p3Title;
  late final TextEditingController _p3Desc;
  late final TextEditingController _p3Price;

  @override
  void initState() {
    super.initState();
    _p1Title = TextEditingController(text: widget.p1Title);
    _p1Desc = TextEditingController(text: widget.p1Desc);
    _p1Price = TextEditingController(text: widget.p1Price == null ? '' : widget.p1Price!.toString());

    _p2Title = TextEditingController(text: widget.p2Title);
    _p2Desc = TextEditingController(text: widget.p2Desc);
    _p2Price = TextEditingController(text: widget.p2Price == null ? '' : widget.p2Price!.toString());

    _p3Title = TextEditingController(text: widget.p3Title);
    _p3Desc = TextEditingController(text: widget.p3Desc);
    _p3Price = TextEditingController(text: widget.p3Price == null ? '' : widget.p3Price!.toString());
  }

  @override
  void dispose() {
    _p1Title.dispose();
    _p1Desc.dispose();
    _p1Price.dispose();
    _p2Title.dispose();
    _p2Desc.dispose();
    _p2Price.dispose();
    _p3Title.dispose();
    _p3Desc.dispose();
    _p3Price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar planes · ${widget.lineaName}'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _planEditor(
                  label: 'Plan 1 (obligatorio)',
                  titleCtrl: _p1Title,
                  descCtrl: _p1Desc,
                  priceCtrl: _p1Price,
                  requiredPlan: true,
                ),
                const SizedBox(height: 12),
                _planEditor(
                  label: 'Plan 2 (opcional)',
                  titleCtrl: _p2Title,
                  descCtrl: _p2Desc,
                  priceCtrl: _p2Price,
                ),
                const SizedBox(height: 12),
                _planEditor(
                  label: 'Plan 3 (opcional)',
                  titleCtrl: _p3Title,
                  descCtrl: _p3Desc,
                  priceCtrl: _p3Price,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: _onSave,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _planEditor({
    required String label,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required TextEditingController priceCtrl,
    bool requiredPlan = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        TextFormField(
          controller: titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Título del plan',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (!requiredPlan) return null;
            if ((v ?? '').trim().isEmpty) return 'Título requerido para el Plan 1';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: descCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Descripción',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (!requiredPlan) return null;
            if ((v ?? '').trim().isEmpty) return 'Descripción requerida para el Plan 1';
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Precio (ej. 5.00)',
            border: OutlineInputBorder(),
          ),
          validator: (v) {
            if (!requiredPlan) {
              if ((v ?? '').trim().isEmpty) return null;
            }
            final raw = (v ?? '').trim();
            if (raw.isEmpty) return 'Precio requerido para el Plan 1';
            final d = double.tryParse(raw.replaceAll(',', '.'));
            if (d == null || d < 0) return 'Precio inválido';
            return null;
          },
        ),
      ],
    );
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    final p1Title = _p1Title.text.trim();
    final p1Desc = _p1Desc.text.trim();
    final p1Price = double.tryParse(_p1Price.text.trim().replaceAll(',', '.'));

    final p2Title = _p2Title.text.trim();
    final p2Desc = _p2Desc.text.trim();
    final p2Price = _p2Price.text.trim().isEmpty
        ? null
        : double.tryParse(_p2Price.text.trim().replaceAll(',', '.'));

    final p3Title = _p3Title.text.trim();
    final p3Desc = _p3Desc.text.trim();
    final p3Price = _p3Price.text.trim().isEmpty
        ? null
        : double.tryParse(_p3Price.text.trim().replaceAll(',', '.'));

    Navigator.pop(
      context,
      _PlanesResult(
        p1Title: p1Title, p1Desc: p1Desc, p1Price: p1Price,
        p2Title: p2Title, p2Desc: p2Desc, p2Price: p2Price,
        p3Title: p3Title, p3Desc: p3Desc, p3Price: p3Price,
      ),
    );
  }
}

class _PlanesResult {
  final String p1Title;
  final String p1Desc;
  final double? p1Price;
  final String p2Title;
  final String p2Desc;
  final double? p2Price;
  final String p3Title;
  final String p3Desc;
  final double? p3Price;

  _PlanesResult({
    required this.p1Title,
    required this.p1Desc,
    required this.p1Price,
    required this.p2Title,
    required this.p2Desc,
    required this.p2Price,
    required this.p3Title,
    required this.p3Desc,
    required this.p3Price,
  });
}

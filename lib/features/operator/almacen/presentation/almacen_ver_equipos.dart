import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ====================== CONSTANTES DE FIRESTORE ======================
const String kAlmacenEquiposRoot = 'almacen_pdv'; // colección raíz por modelo
const String kSubEquipos = 'equipos'; // subcolección de seriales
const Color _panelColor = Color(0xFFAED6D8);

/// ====================================================================
/// LISTADO DE MODELOS (con total de seriales disponibles)
class AlmacenVerEquiposScreen extends StatelessWidget {
  const AlmacenVerEquiposScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colRef = FirebaseFirestore.instance.collection(kAlmacenEquiposRoot);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
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

                  final models = snap.data?.docs ?? const [];
                  if (models.isEmpty) {
                    return const Center(
                      child: Text('No hay equipos registrados.'),
                    );
                  }

                  final sorted = [...models]..sort((a, b) {
                    final ma = a.id.toLowerCase();
                    final mb = b.id.toLowerCase();
                    return ma.compareTo(mb);
                  });

                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sorted.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final d = sorted[i];
                      final data = d.data();
                      final modeloId = d.id;
                      final modelo = (data['modelo'] ?? modeloId).toString();
                      final subRef = colRef.doc(modeloId).collection(kSubEquipos);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => _ModeloDetalleScreen(
                                modeloId: modeloId,
                                modelo: modelo,
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
/// DETALLE DE MODELO: descripción, características, precio y seriales;
/// permite editar (desc/carac/precio), añadir y eliminar seriales.
class _ModeloDetalleScreen extends StatefulWidget {
  final String modeloId;
  final String modelo;

  const _ModeloDetalleScreen({
    required this.modeloId,
    required this.modelo,
  });

  @override
  State<_ModeloDetalleScreen> createState() => _ModeloDetalleScreenState();
}

class _ModeloDetalleScreenState extends State<_ModeloDetalleScreen> {
  late final DocumentReference<Map<String, dynamic>> _modelRef;
  late final CollectionReference<Map<String, dynamic>> _serialsRef;

  @override
  void initState() {
    super.initState();
    _modelRef = FirebaseFirestore.instance
        .collection(kAlmacenEquiposRoot)
        .doc(widget.modeloId);

    _serialsRef = _modelRef.collection(kSubEquipos);
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

            FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: _modelRef.get(),
              builder: (context, modelSnap) {
                if (modelSnap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (modelSnap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Error: ${modelSnap.error}'),
                  );
                }

                final doc = modelSnap.data; // propiedad, no método
                final mdata = doc?.data() ?? <String, dynamic>{};

                final String descripcion = (mdata['descripcion'] ?? '').toString();
                final String caracteristicas = (mdata['caracteristicas'] ?? '').toString();
                final num? precioNum = mdata['precio'] is num ? mdata['precio'] as num : null;
                final String precioStr =
                (precioNum == null) ? '—' : _formatMoneda(precioNum.toDouble());

                return Expanded(
                  child: Column(
                    children: [
// Tarjeta de info (Descripción, Características, Precio)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _rowLabelValue(
                                context: context,
                                label: 'Descripción',
                                value: descripcion.isEmpty ? '—' : descripcion,
                                onEdit: () => _editTextField(
                                  title: 'Editar descripción',
                                  initial: descripcion,
                                  fieldKey: 'descripcion',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _rowLabelValue(
                                context: context,
                                label: 'Características',
                                value: caracteristicas.isEmpty ? '—' : caracteristicas,
                                onEdit: () => _editTextField(
                                  title: 'Editar características',
                                  initial: caracteristicas,
                                  fieldKey: 'caracteristicas',
                                ),
                              ),
                              const SizedBox(height: 8),
                              _rowLabelValue(
                                context: context,
                                label: 'Precio',
                                value: precioStr,
                                onEdit: () => _editPriceField(
                                  title: 'Editar precio',
                                  initialNumber: precioNum?.toDouble(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

// Lista de seriales
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
                              itemCount: items.isEmpty ? 1 : items.length + 1,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
// Primer “card” de acciones: eliminar serial
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

// Lista de seriales
                                if (items.isEmpty) {
                                  return _card(
                                    child: const Text(
                                      'No hay seriales cargados para este modelo.',
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// --------------------------- Helpers de UI ---------------------------
  Widget _rowLabelValue({
    required BuildContext context,
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onEdit,
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Editar $label',
        ),
      ],
    );
  }

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

  String _formatMoneda(double v) {
// Simple formatting sin intl: 2 decimales con separador punto
    return '\$${v.toStringAsFixed(2)}';
  }

  /// --------------------------- Editores ---------------------------
  Future<void> _editTextField({
    required String title,
    required String initial,
    required String fieldKey,
  }) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditTextDialog(title: title, initial: initial),
    );
    if (text == null) return;

    try {
      await _modelRef.update({
        fieldKey: text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Actualizado $fieldKey')),
      );
      setState(() {}); // refresca el FutureBuilder
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message ?? e.code}')));
    }
  }

  Future<void> _editPriceField({
    required String title,
    required double? initialNumber,
  }) async {
    final text = await showDialog<String>(
      context: context,
      builder: (_) => _EditPriceDialog(
        title: title,
        initial: initialNumber == null ? '' : initialNumber.toStringAsFixed(2),
      ),
    );
    if (text == null) return;

// Permite coma o punto; convertimos a double
    final norm = text.replaceAll(',', '.').trim();
    final value = double.tryParse(norm);
    if (value == null || value < 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Precio inválido')),
      );
      return;
    }

    try {
      await _modelRef.update({
        'precio': value, // número
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Precio actualizado a ${_formatMoneda(value)}')),
      );
      setState(() {}); // refresca el FutureBuilder
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.message ?? e.code}')));
    }
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
            .showSnackBar(SnackBar(content: Text('El serial $serial ya existe en este modelo.')));
        return;
      }

      await docRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      await _modelRef.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Añadido $serial a ${widget.modelo}')),
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
          SnackBar(content: Text('El serial $serial no existe en este modelo.')),
        );
        return;
      }

      await docRef.delete();
      await _modelRef.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Serial $serial eliminado de ${widget.modelo}')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al eliminar: ${e.message ?? e.code}')));
    }
  }
}

/// ====================================================================
/// Diálogo para editar texto (descripción / características)
class _EditTextDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _EditTextDialog({required this.title, required this.initial});

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        child: TextField(
          controller: _ctrl,
          maxLines: 4,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Escribe aquí…',
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// ====================================================================
/// Diálogo para editar precio (acepta coma/punto)
class _EditPriceDialog extends StatefulWidget {
  final String title;
  final String initial;
  const _EditPriceDialog({required this.title, required this.initial});

  @override
  State<_EditPriceDialog> createState() => _EditPriceDialogState();
}

class _EditPriceDialogState extends State<_EditPriceDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.initial);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: TextField(
          controller: _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Precio (ej. 500)',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _ctrl.text),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

/// ====================================================================
/// Diálogo para añadir un serial (valida letras+números sencillos)
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
      title: const Text('Añadir serial'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: 'Serial (ej. UJ789)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa un serial';
// Acepta letras y números (ajusta si quieres AA999 únicamente)
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
      title: const Text('Eliminar serial'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 360,
          child: TextFormField(
            controller: _serialCtrl,
            decoration: const InputDecoration(
              labelText: 'Serial exacto (ej. UJ789)',
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

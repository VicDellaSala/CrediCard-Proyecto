import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// ====================== CONSTANTES DE FIRESTORE ======================
/// Raíz del almacén de puntos de venta (modelos)
const String kAlmacenEquiposRoot = 'almacen_pdv';
/// Subcolección con los seriales por modelo
const String kSubEquipos = 'equipos';

/// Color del encabezado “celestito”
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

// Stream de todos los modelos
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

// Orden alfabético por modelo_id / modelo
                  final sorted = [...models]..sort((a, b) {
                    final ma = (a.id).toLowerCase();
                    final mb = (b.id).toLowerCase();
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

// Contador de seriales en subcolección
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

// Total de seriales disponibles (conteo simple)
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
/// DETALLE DE MODELO: muestra descripción, características y seriales.
/// Permite editar descripción/características y añadir nuevos seriales.
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

// FUTURE del doc de modelo (para leer/editar descripción y características)
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

                final doc = modelSnap.data();
                final mdata = doc?.data() ?? <String, dynamic>{};

                final String descripcion = (mdata['descripcion'] ?? '').toString();
                final String caracteristicas = (mdata['caracteristicas'] ?? '').toString();

                return Expanded(
                  child: Column(
                    children: [
// Tarjeta de Descripción + Características (con botones de editar)
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
                            if (serialDocs.isEmpty) {
                              return const Center(
                                child: Text('No hay seriales cargados para este modelo.'),
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
                              itemCount: items.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (_, i) {
                                final s = items[i];
                                final serial = (s['serial'] ?? '').toString();
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

  /// UI de la fila de Descripción/Características con botón editar
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

  /// Edita un campo de texto del doc de modelo (descripcion / caracteristicas)
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

  /// Añadir un nuevo serial a la subcolección /equipos
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
// Evitar duplicados por id (con el serial_lower como id del doc).
      final docRef = _serialsRef.doc(serialLower);
      final exists = await docRef.get();
      if (exists.exists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ese serial ya existe para este modelo.')));
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
              labelText: 'Serial (ej. UG767)',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa un serial';
// Acepta letras y números (puedes afinar el patrón a AA999 si lo deseas)
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
        )
      ],
    );
  }
}

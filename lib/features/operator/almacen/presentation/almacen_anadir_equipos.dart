import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlmacenAnadirEquiposScreen extends StatefulWidget {
  const AlmacenAnadirEquiposScreen({super.key});

  @override
  State<AlmacenAnadirEquiposScreen> createState() => _AlmacenAnadirEquiposScreenState();
}

class _AlmacenAnadirEquiposScreenState extends State<AlmacenAnadirEquiposScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();
  final _modeloCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  String _normId(String s) {
// Normaliza para IDs: minúsculas, quita símbolos raros, espacios -> "_"
    final base = s.trim().toLowerCase();
    final only = base
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]+', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return only.isEmpty ? 'sin_nombre' : only;
  }

  String _normName(String s) => s.trim();

// Valida "UG767": 2 letras + 3 dígitos (insensible a mayúsculas)
  bool _validSerialPattern(String s) {
    final v = s.trim();
    final regex = RegExp(r'^[A-Za-z]{2}\d{3}$');
    return regex.hasMatch(v);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
      );
      return;
    }

    final modeloNombre = _normName(_modeloCtrl.text); // p.ej. "Castlle"
    final modeloId = _normId(modeloNombre); // p.ej. "castlle"

    final serialNombre = _serialCtrl.text.trim().toUpperCase(); // guardamos visible en MAYÚSCULAS "UG767"
    final serialId = _normId(serialNombre); // id doc: "ug767"

    setState(() => _saving = true);

    try {
      final modelDocRef = FirebaseFirestore.instance
          .collection('almacen_pdv')
          .doc(modeloId);

      final equipoDocRef = modelDocRef
          .collection('equipos')
          .doc(serialId);

// Evitar duplicados de serial dentro del mismo modelo
      final exists = await equipoDocRef.get();
      if (exists.exists) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El serial $serialNombre ya existe en el modelo "$modeloNombre".')),
        );
        return;
      }

// Crea/actualiza doc del modelo (padre)
      await modelDocRef.set({
        'modelo': modeloNombre, // bonito, como lo escribiste
        'modelo_id': modeloId, // normalizado (clave)
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

// Crea doc del equipo (subcolección con el serial)
      await equipoDocRef.set({
        'modelo': modeloNombre,
        'modelo_id': modeloId,
        'serial': serialNombre, // "UG767"
        'serial_id': serialId, // "ug767"
        'estado': 'activo',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado: $modeloNombre → serial $serialNombre')),
      );

// Limpia solo el serial para cargar otro del mismo modelo
      _serialCtrl.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Almacén · Añadir equipo nuevo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
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
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
// Modelo
                          TextFormField(
                            controller: _modeloCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Modelo del punto de venta (ej: Castlle / Unidigital)',
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Ingresa el modelo' : null,
                          ),
                          const SizedBox(height: 14),

// Serial (2 letras + 3 números, ej: UG767)
                          TextFormField(
                            controller: _serialCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Serial (formato: AA999, ej: UG767)',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ingresa el serial';
                              }
                              if (!_validSerialPattern(v)) {
                                return 'Formato inválido (usa 2 letras + 3 números, ej: UG767)';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _saving ? null : _guardar,
                              icon: _saving
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                                  : const Icon(Icons.save),
                              label: const Text('Guardar equipo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

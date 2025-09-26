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
  bool _sinSerial = false;
  bool _saving = false;

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  String _norm(String s) => s.trim();

  String _normId(String s) {
    final base = s.trim().toLowerCase();
    final repl = base
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s_-]+', unicode: true), '')
        .replaceAll(RegExp(r'\s+'), '_');
    return repl.isEmpty ? 'sin_nombre' : repl;
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

    final modelo = _norm(_modeloCtrl.text);
    final modeloId = _normId(modelo);

    late final String serialId;
    String? serialValue;

    if (_sinSerial) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      serialId = 'sin_$ts';
      serialValue = null;
    } else {
      final s = _norm(_serialCtrl.text);
      if (s.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ingresa el serial o marca "Sin serial"')),
        );
        return;
      }
      serialId = _normId(s);
      serialValue = s;
    }

    setState(() => _saving = true);

    try {
      final modelDocRef = FirebaseFirestore.instance
          .collection('almacen_pdv')
          .doc(modeloId);

      final equipoDocRef = modelDocRef.collection('equipos').doc(serialId);

      final exists = await equipoDocRef.get();
      if (exists.exists) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ya existe un equipo con ese serial en este modelo')),
        );
        return;
      }

// ✅ Crea/actualiza el doc del modelo (padre)
      await modelDocRef.set({
        'modelo': modelo,
        'modelo_id': modeloId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

// ✅ Crea el doc del equipo (subcolección)
      await equipoDocRef.set({
        'modelo': modelo,
        'modelo_id': modeloId,
        'serial': serialValue, // null si es "sin serial"
        'serial_id': serialId,
        'estado': 'activo',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipo guardado en "$modelo"')),
      );

      _serialCtrl.clear();
      setState(() {
        _sinSerial = false;
      });
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
                    'Almacén · Añadir equipo',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _modeloCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Modelo del equipo',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Ingresa el modelo' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _serialCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Serial',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_sinSerial,
                              validator: (v) {
                                if (_sinSerial) return null;
                                if (v == null || v.isEmpty) return 'Ingresa el serial';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _sinSerial,
                            onChanged: (val) {
                              setState(() {
                                _sinSerial = val ?? false;
                              });
                            },
                          ),
                          const Text("Sin serial"),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _saving ? null : _guardar,
                        child: _saving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Guardar equipo'),
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
}

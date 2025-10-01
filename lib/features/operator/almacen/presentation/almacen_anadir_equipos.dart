import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const String kAlmacenEquiposRoot = 'almacen_pdv'; // colección raíz (modelos)
const String kSubEquipos = 'equipos'; // subcolección (seriales)
const Color _panelColor = Color(0xFFAED6D8);

class AlmacenAnadirEquiposScreen extends StatefulWidget {
  const AlmacenAnadirEquiposScreen({super.key});

  @override
  State<AlmacenAnadirEquiposScreen> createState() => _AlmacenAnadirEquiposScreenState();
}

class _AlmacenAnadirEquiposScreenState extends State<AlmacenAnadirEquiposScreen> {
  final _formKey = GlobalKey<FormState>();

  final _modeloCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();
  final _descripcionCtrl = TextEditingController();
  final _caracteristicasCtrl = TextEditingController();
  final _precioCtrl = TextEditingController(); // NUEVO (opcional, double)

  bool _saving = false;

  @override
  void dispose() {
    _modeloCtrl.dispose();
    _serialCtrl.dispose();
    _descripcionCtrl.dispose();
    _caracteristicasCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
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
                    'Almacén · Añadir equipos',
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
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _card(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Datos del equipo',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),

// Modelo (requerido)
                            TextFormField(
                              controller: _modeloCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Modelo del equipo (ej. Castlle, Unidigital)',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Ingresa el modelo';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

// Serial (requerido)
                            TextFormField(
                              controller: _serialCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Serial (ej. UG767 / UJ78)',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Ingresa el serial';
// Acepta letras y números; ajusta si quieres el patrón estricto.
                                final ok = RegExp(r'^[A-Za-z0-9\-_.]+$').hasMatch(s);
                                if (!ok) return 'Serial inválido (solo letras/números - _ .)';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),

// Descripción (opcional)
                            TextFormField(
                              controller: _descripcionCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Descripción (opcional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

// Características (opcional)
                            TextFormField(
                              controller: _caracteristicasCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Características (opcional)',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),

// Precio (opcional, double)
                            TextFormField(
                              controller: _precioCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Precio (opcional, ej. 1250.00)',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (v) {
                                final raw = (v ?? '').trim();
                                if (raw.isEmpty) return null; // opcional
                                final norm = raw.replaceAll(',', '.');
                                final d = double.tryParse(norm);
                                if (d == null || d < 0) return 'Precio inválido';
                                return null;
                              },
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _onSave,
                                icon: _saving
                                    ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                                    : const Icon(Icons.save),
                                label: Text(_saving ? 'Guardando...' : 'Guardar equipo'),
                              ),
                            ),
                          ],
                        ),
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

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
      );
      return;
    }

    final modeloRaw = _modeloCtrl.text.trim();
    final modeloId = modeloRaw.toLowerCase(); // id del doc
    final serial = _serialCtrl.text.trim().toUpperCase();
    final serialLower = serial.toLowerCase();

    final descripcion = _descripcionCtrl.text.trim();
    final caracteristicas = _caracteristicasCtrl.text.trim();

// Precio (opcional)
    double? precio;
    final precioRaw = _precioCtrl.text.trim();
    if (precioRaw.isNotEmpty) {
      final norm = precioRaw.replaceAll(',', '.');
      precio = double.tryParse(norm);
    }

    final modelRef = FirebaseFirestore.instance.collection(kAlmacenEquiposRoot).doc(modeloId);
    final serialRef = modelRef.collection(kSubEquipos).doc(serialLower);

    try {
// 1) Crear/actualizar el documento del MODELO (merge)
      final modelSnap = await modelRef.get();
      final now = FieldValue.serverTimestamp();

      final Map<String, dynamic> baseModel = {
        'modelo': modeloRaw,
        'updatedAt': now,
      };

// Solo incluimos estos campos si vienen con algo (no pisamos con vacío)
      if (descripcion.isNotEmpty) baseModel['descripcion'] = descripcion;
      if (caracteristicas.isNotEmpty) baseModel['caracteristicas'] = caracteristicas;
      if (precio != null) baseModel['precio'] = precio;

      if (!modelSnap.exists) {
        baseModel['createdAt'] = now;
      }

      await modelRef.set(baseModel, SetOptions(merge: true));

// 2) Crear el SERIAL si no existe
      final serialSnap = await serialRef.get();
      if (serialSnap.exists) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El serial $serial ya existe para $modeloRaw')),
        );
        return;
      }

      await serialRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': now,
        'createdBy': uid,
      });

// 3) Done
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Equipo "$modeloRaw" guardado con serial $serial')),
        );
// Limpia serial para poder seguir cargando
        _serialCtrl.clear();
// Si quieres limpiar todo, descomenta:
// _modeloCtrl.clear();
// _descripcionCtrl.clear();
// _caracteristicasCtrl.clear();
// _precioCtrl.clear();
      }
    } on FirebaseException catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')));
    }
  }
}

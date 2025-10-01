import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

const String kAlmacenTarjetasRoot = 'almacen_tarjetas';
const String kSubTarjetas = 'tarjetas';
const Color _panelColor = Color(0xFFAED6D8);

class AlmacenAnadirTarjetasOperadorasScreen extends StatefulWidget {
  const AlmacenAnadirTarjetasOperadorasScreen({super.key});

  @override
  State<AlmacenAnadirTarjetasOperadorasScreen> createState() => _AlmacenAnadirTarjetasOperadorasScreenState();
}

class _AlmacenAnadirTarjetasOperadorasScreenState extends State<AlmacenAnadirTarjetasOperadorasScreen> {
  final _formKey = GlobalKey<FormState>();

  final _serialCtrl = TextEditingController();

// Línea (Digitel / Movistar / Pública)
  final _lineas = const ['Digitel', 'Movistar', 'Pública'];
  String? _linea;

// Plan 1 (obligatorio)
  final _p1Title = TextEditingController();
  final _p1Desc = TextEditingController();
  final _p1Price = TextEditingController();

// Plan 2 (opcional)
  final _p2Title = TextEditingController();
  final _p2Desc = TextEditingController();
  final _p2Price = TextEditingController();

// Plan 3 (opcional)
  final _p3Title = TextEditingController();
  final _p3Desc = TextEditingController();
  final _p3Price = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _serialCtrl.dispose();
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
                    'Almacén · Añadir tarjeta',
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
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _card(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Datos de la tarjeta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 12),

                            DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Línea (obligatorio)',
                                border: OutlineInputBorder(),
                              ),
                              items: _lineas.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                              value: _linea,
                              onChanged: (v) => setState(() => _linea = v),
                              validator: (v) => v == null ? 'Selecciona la línea' : null,
                            ),
                            const SizedBox(height: 12),

                            TextFormField(
                              controller: _serialCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Serial (ej. BU67)',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.characters,
                              validator: (v) {
                                final s = (v ?? '').trim();
                                if (s.isEmpty) return 'Ingresa el serial';
                                final ok = RegExp(r'^[A-Za-z0-9\-_.]+$').hasMatch(s);
                                if (!ok) return 'Serial inválido (solo letras/números - _ .)';
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 12),

                            const Text('Planes de la línea', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 8),
                            const Text('Plan 1 es obligatorio. Planes 2 y 3 son opcionales.'),

                            const SizedBox(height: 16),
                            _planCard(
                              titulo: 'Plan 1 (obligatorio)',
                              titleCtrl: _p1Title,
                              descCtrl: _p1Desc,
                              priceCtrl: _p1Price,
                              requiredFields: true,
                            ),
                            const SizedBox(height: 10),
                            _planCard(
                              titulo: 'Plan 2 (opcional)',
                              titleCtrl: _p2Title,
                              descCtrl: _p2Desc,
                              priceCtrl: _p2Price,
                            ),
                            const SizedBox(height: 10),
                            _planCard(
                              titulo: 'Plan 3 (opcional)',
                              titleCtrl: _p3Title,
                              descCtrl: _p3Desc,
                              priceCtrl: _p3Price,
                            ),

                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _saving ? null : _onSave,
                                icon: _saving
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Icon(Icons.save),
                                label: Text(_saving ? 'Guardando...' : 'Guardar'),
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

  Widget _planCard({
    required String titulo,
    required TextEditingController titleCtrl,
    required TextEditingController descCtrl,
    required TextEditingController priceCtrl,
    bool requiredFields = false,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          TextFormField(
            controller: titleCtrl,
            decoration: const InputDecoration(labelText: 'Título del plan', border: OutlineInputBorder()),
            validator: (v) {
              if (!requiredFields) return null;
              if ((v ?? '').trim().isEmpty) return 'Título requerido';
              return null;
            },
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: descCtrl,
            decoration: const InputDecoration(labelText: 'Descripción (opcional)', border: OutlineInputBorder()),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: priceCtrl,
            decoration: const InputDecoration(labelText: 'Precio (ej. 5.00)', border: OutlineInputBorder()),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final raw = (v ?? '').trim();
              if (!requiredFields && raw.isEmpty) return null;
              final norm = raw.replaceAll(',', '.');
              final d = double.tryParse(norm);
              if (d == null || d < 0) return 'Precio inválido';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión nuevamente.')),
      );
      return;
    }

    setState(() => _saving = true);

    final linea = _linea!;
    final lineaId = linea.toLowerCase();
    final serial = _serialCtrl.text.trim().toUpperCase();
    final serialLower = serial.toLowerCase();

// Construimos array de planes
    List<Map<String, dynamic>> planes = [];

// Plan 1 (requerido)
    final p1Title = _p1Title.text.trim();
    final p1Desc = _p1Desc.text.trim();
    final p1Price = _p1Price.text.trim().replaceAll(',', '.');
    planes.add({
      'index': 1,
      'title': p1Title,
      'description': p1Desc.isEmpty ? null : p1Desc,
      'price': double.parse(p1Price),
    });

// Plan 2 (opcional)
    if (_p2Title.text.trim().isNotEmpty || _p2Price.text.trim().isNotEmpty || _p2Desc.text.trim().isNotEmpty) {
      final t = _p2Title.text.trim();
      final d = _p2Desc.text.trim();
      final pr = _p2Price.text.trim().replaceAll(',', '.');
      final prDouble = pr.isEmpty ? null : double.tryParse(pr);
      planes.add({
        'index': 2,
        'title': t.isEmpty ? null : t,
        'description': d.isEmpty ? null : d,
        'price': prDouble,
      });
    }

// Plan 3 (opcional)
    if (_p3Title.text.trim().isNotEmpty || _p3Price.text.trim().isNotEmpty || _p3Desc.text.trim().isNotEmpty) {
      final t = _p3Title.text.trim();
      final d = _p3Desc.text.trim();
      final pr = _p3Price.text.trim().replaceAll(',', '.');
      final prDouble = pr.isEmpty ? null : double.tryParse(pr);
      planes.add({
        'index': 3,
        'title': t.isEmpty ? null : t,
        'description': d.isEmpty ? null : d,
        'price': prDouble,
      });
    }

    final lineaRef = FirebaseFirestore.instance.collection(kAlmacenTarjetasRoot).doc(lineaId);
    final serialRef = lineaRef.collection(kSubTarjetas).doc(serialLower);

    try {
// Merge línea con planes
      await lineaRef.set({
        'linea': linea,
        'planes': planes,
        'updatedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

// Serial (evita duplicados)
      final exists = await serialRef.get();
      if (exists.exists) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El serial $serial ya existe en $linea.')),
        );
        return;
      }

      await serialRef.set({
        'serial': serial,
        'serial_lower': serialLower,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tarjeta guardada en $linea con serial $serial')),
      );

      _serialCtrl.clear();
// Opcional: limpiar planes solo si quieres
// _p1Title.clear(); _p1Desc.clear(); _p1Price.clear();
// _p2Title.clear(); _p2Desc.clear(); _p2Price.clear();
// _p3Title.clear(); _p3Desc.clear(); _p3Price.clear();

    } on FirebaseException catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String kAlmacenTarjetasCollection = 'almacen_tarjetas';
const String kSubSeriales = 'seriales';

class AlmacenAnadirTarjetaOperadoraScreen extends StatefulWidget {
  const AlmacenAnadirTarjetaOperadoraScreen({super.key});

  @override
  State<AlmacenAnadirTarjetaOperadoraScreen> createState() =>
      _AlmacenAnadirTarjetaOperadoraScreenState();
}

class _AlmacenAnadirTarjetaOperadoraScreenState
    extends State<AlmacenAnadirTarjetaOperadoraScreen> {
  final _formKey = GlobalKey<FormState>();
  final _lineaCtrl = TextEditingController();
  final _serialCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _lineaCtrl.dispose();
    _serialCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión de nuevo.')),
      );
      return;
    }

    final linea = _lineaCtrl.text.trim();
    final lineaId = linea.toLowerCase();
    final serial = _serialCtrl.text.trim().toUpperCase();
    final serialId = serial.toLowerCase();

    setState(() => _saving = true);

    try {
      final ref = FirebaseFirestore.instance.collection(kAlmacenTarjetasCollection);
      final lineRef = ref.doc(lineaId);
      final lineDoc = await lineRef.get();

      if (!lineDoc.exists) {
        await lineRef.set({
          'linea': linea,
          'linea_id': lineaId,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      final serialRef = lineRef.collection(kSubSeriales).doc(serialId);
      if ((await serialRef.get()).exists) {
        throw FirebaseException(
          plugin: 'firestore',
          code: 'already-exists',
          message: 'Este serial ya existe en $linea',
        );
      }

      await serialRef.set({
        'serial': serial,
        'serial_lower': serialId,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      await lineRef.update({'updatedAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Añadido $serial a la línea $linea')),
      );
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
              decoration: BoxDecoration(
                color: const Color(0xFFAED6D8),
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _lineaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nombre de la línea (ej: Movistar, Digitel, Pública)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa un nombre de línea válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _serialCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Serial de la tarjeta (ej: JU87)',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Ingresa un serial válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _onSave,
                            icon: _saving
                                ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                                : const Icon(Icons.save),
                            label: const Text('Guardar tarjeta'),
                          ),
                        ),
                      ],
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

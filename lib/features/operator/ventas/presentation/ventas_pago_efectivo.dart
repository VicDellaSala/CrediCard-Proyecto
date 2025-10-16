import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasPagoEfectivoScreen extends StatefulWidget {
  const VentasPagoEfectivoScreen({super.key});

  @override
  State<VentasPagoEfectivoScreen> createState() => _VentasPagoEfectivoScreenState();
}

class _VentasPagoEfectivoScreenState extends State<VentasPagoEfectivoScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();

// Args
  String _rif = '';
  String _clienteNombre = '';
  double _totalAPagar = 0.0;

// Controles
  final _comercioCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _aprobacionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  String _moneda = 'Bs'; // Bs / USD
  late final String _fecha; // yyyy-mm-dd
  late final String _hora; // HH:mm

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha =
    "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _hora = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

// N° de aprobación de 6 dígitos (editable)
    _aprobacionCtrl.text = _random6();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map<String, dynamic>;
    _rif = (args['rif'] ?? '').toString();
    _totalAPagar = _toDouble(args['total']);

    _cargarNombreClientePorRif(_rif);
  }

  @override
  void dispose() {
    _comercioCtrl.dispose();
    _montoCtrl.dispose();
    _aprobacionCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

// ====================== Utils ======================
  String _random6() => (Random().nextInt(900000) + 100000).toString(); // 6 dígitos

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll('\$', '').replaceAll('USD', '').replaceAll('Bs', '').replaceAll(',', '.').trim();
      return double.tryParse(s) ?? 0;
    }
    return 0;
  }

  bool _isReferenciaValida(String v) => RegExp(r'^00\d{5}$').hasMatch(v); // 00 + 5 dígitos

  Future<void> _cargarNombreClientePorRif(String rif) async {
    if (rif.isEmpty) return;
    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rif.toLowerCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        final nombre = (data['first_name'] ?? '').toString();
        final apellido = (data['last_name'] ?? '').toString();
        setState(() =>
        _clienteNombre = [nombre, apellido].where((e) => e.trim().isNotEmpty).join(' ').trim());
      }
    } catch (_) {}
  }

// ====================== Guardar ======================
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final comercio = _comercioCtrl.text.trim();
    final monto = _toDouble(_montoCtrl.text);
    final aprobacion = _aprobacionCtrl.text.trim();
    final referencia = _referenciaCtrl.text.trim();

    try {
      final firestore = FirebaseFirestore.instance;

// 1) Guardar pago en efectivo
      await firestore.collection('pagos_efectivo').add({
        'rif': _rif,
        'nombre': _clienteNombre,
        'comercio': comercio,
        'moneda': _moneda, // 'Bs' o 'USD'
        'monto': monto,
        'aprobacion': aprobacion, // 6 dígitos
        'referencia': referencia, // 00 + 5 dígitos
        'fecha': _fecha,
        'hora': _hora,
        'createdAt': FieldValue.serverTimestamp(),
      });

// 2) Ajustar deuda en Cliente_completo (mismo criterio que los otros)
      final diff = monto - _totalAPagar;

      final q = await firestore
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: _rif.toLowerCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final ref = q.docs.first.reference;
        final data = q.docs.first.data();

        final double deudaActual = _toDouble(data['deuda']);
        double nuevaDeuda;
        if (diff < 0) {
// Pagó menos → aumenta deuda
          nuevaDeuda = deudaActual + (-diff);
        } else if (diff > 0) {
// Pagó de más → reduce deuda (sin bajar de 0)
          final tmp = deudaActual - diff;
          nuevaDeuda = tmp < 0 ? 0 : tmp;
        } else {
          nuevaDeuda = deudaActual;
        }

        await ref.update({
          'deuda': double.parse(nuevaDeuda.toStringAsFixed(2)),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

// 3) Ir al comprobante / ventas_datos_finales
      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          'tipo': 'efectivo',
          'rif': _rif,
          'monto': monto,
          'total': _totalAPagar,
          'moneda': _moneda,
          'aprobacion': aprobacion,
          'referencia': referencia,
          'comercio': comercio,
          'fecha': _fecha,
          'hora': _hora,
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: $e')),
      );
    }
  }

// ====================== UI ======================
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
                children: const [
                  Spacer(),
                  Text(
                    'Pago en Efectivo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  Spacer(),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _resumenCard(),
                      const SizedBox(height: 16),
                      _formCard(),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _guardar,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Guardar y continuar'),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
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

  Widget _resumenCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.receipt_long, color: Colors.black54),
            SizedBox(width: 8),
            Text('Resumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Text('RIF: ${_rif.isEmpty ? '—' : _rif}'),
          Text('Cliente: ${_clienteNombre.isEmpty ? '—' : _clienteNombre}'),
          const SizedBox(height: 6),
          Text('Total a pagar: \$${_totalAPagar.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Fecha: $_fecha Hora: $_hora'),
        ],
      ),
    );
  }

  Widget _formCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
// Comercio
            TextFormField(
              controller: _comercioCtrl,
              decoration: const InputDecoration(
                labelText: 'Comercio',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el comercio' : null,
            ),
            const SizedBox(height: 12),

// Moneda
            DropdownButtonFormField<String>(
              value: _moneda,
              items: const [
                DropdownMenuItem(value: 'Bs', child: Text('Bolívares (Bs)')),
                DropdownMenuItem(value: 'USD', child: Text('Dólares (USD)')),
              ],
              onChanged: (v) => setState(() => _moneda = v ?? 'Bs'),
              decoration: const InputDecoration(
                labelText: 'Moneda',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

// Monto pagado
            TextFormField(
              controller: _montoCtrl,
              decoration: InputDecoration(
                labelText: 'Monto pagado (Total: \$${_totalAPagar.toStringAsFixed(2)})',
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final n = double.tryParse((v ?? '').replaceAll(',', '.').trim());
                if (n == null || n <= 0) return 'Monto inválido';
                return null;
              },
            ),
            const SizedBox(height: 12),

// Aprobación (6)
            TextFormField(
              controller: _aprobacionCtrl,
              decoration: const InputDecoration(
                labelText: 'N° de aprobación (6 dígitos)',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
              keyboardType: TextInputType.number,
              validator: (v) => RegExp(r'^\d{6}$').hasMatch((v ?? '').trim()) ? null : 'Deben ser 6 dígitos',
            ),
            const SizedBox(height: 12),

// Referencia (00 + 5 dígitos)
            TextFormField(
              controller: _referenciaCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencia (formato 00#####)',
                hintText: 'Ej: 0012345',
                border: OutlineInputBorder(),
              ),
              maxLength: 7,
              keyboardType: TextInputType.number,
              validator: (v) {
                final s = (v ?? '').trim();
                if (!_isReferenciaValida(s)) return 'Debe empezar con 00 y tener 7 dígitos (00#####)';
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
    ],
  );
}

import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasComodatoScreen extends StatefulWidget {
  const VentasComodatoScreen({super.key});

  @override
  State<VentasComodatoScreen> createState() => _VentasComodatoScreenState();
}

class _VentasComodatoScreenState extends State<VentasComodatoScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();

// ------- Args / contexto -------
  String _rif = '';
  String _clienteNombre = '';
  String _lineaName = '';
  String _planTitle = '';
  String _planPriceStr = '0';
  String? _modeloSeleccionado;
  String _posPriceStr = '0';
  String? _serialEquipo;
  String? _serialSim;

// Totales (monto de comodato = total)
  double get _planPrice => _parseMoney(_planPriceStr);
  double get _posPrice => _parseMoney(_posPriceStr);
  double get _total => (_planPrice + _posPrice);

// ------- Controles -------
  final _comercioCtrl = TextEditingController(); // opcional (por consistencia)
  final _referenciaCtrl = TextEditingController(); // 00 + 6 dígitos

  late final String _fecha; // yyyy-MM-dd
  late final String _hora; // HH:mm

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

// Referencia por defecto (editable)
    _referenciaCtrl.text = _randReferencia();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};

    _rif = (args['rif'] ?? '').toString();
    _lineaName = (args['lineaName'] ?? '').toString();
    _planTitle = (args['planTitle'] ?? '').toString();
    _planPriceStr = (args['planPrice'] ?? '0').toString();
    _modeloSeleccionado = (args['modeloSeleccionado'])?.toString();
    _posPriceStr = (args['posPrice'] ?? '0').toString();
    _serialEquipo = (args['serialEquipo'])?.toString();
    _serialSim = (args['serialSim'])?.toString();

// Si te llega 'total' directo desde la pantalla anterior, lo usamos para forzar consistencia
    final totalArg = _toDouble(args['total']);
    if (totalArg > 0) {
// Reescribimos plan/pos de manera que total = totalArg (solo para mostrar coherente)
// No es estrictamente necesario; el ajuste de deuda usará _total calculado o totalArg (prefiere totalArg)
// Aquí solo nos aseguramos de que no haya confusión visual si te llega 'total'.
      final diff = totalArg - (_planPrice + _posPrice);
      if (diff.abs() > 0.009) {
// Si hay diferencia notable, priorizamos 'total' en vez de recomputar
// Mostramos total desde el arg en el resumen usando _totalArgForUi
        _totalArgForUi = totalArg;
      }
    }

    _cargarNombreClientePorRif(_rif);
  }

  double? _totalArgForUi; // Para el caso que te llegue 'total' pre-calculado

  @override
  void dispose() {
    _comercioCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

// ====================== Utils ======================
  static double _parseMoney(String raw) {
    final s = raw.replaceAll('\$', '').replaceAll('USD', '').replaceAll('Bs', '').replaceAll(',', '.').trim();
    return double.tryParse(s) ?? 0.0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll(RegExp(r'[^\d.,-]'), '').replaceAll(',', '.');
      return double.tryParse(s) ?? 0;
    }
    return 0;
  }

  String _randReferencia() {
    final r = Random.secure();
// "00" + 6 dígitos
    final digits = List.generate(6, (_) => r.nextInt(10)).join();
    return '00$digits';
  }

  bool _isReferenciaValida(String v) => RegExp(r'^00\d{6}$').hasMatch(v); // 00 + 6 dígitos

  Future<void> _cargarNombreClientePorRif(String rif) async {
    if (rif.isEmpty) return;
    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rif.toLowerCase())
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final d = q.docs.first.data();
        final nombre = (d['first_name'] ?? '').toString();
        final apellido = (d['last_name'] ?? '').toString();
        setState(() {
          _clienteNombre = [nombre, apellido].where((x) => x.trim().isNotEmpty).join(' ');
        });
      }
    } catch (_) {}
  }

// ====================== Guardar ======================
  Future<void> _guardar() async {
// Validar solo referencia (monto es automático)
    if (!_formKey.currentState!.validate()) return;

    final referencia = _referenciaCtrl.text.trim();
    if (!_isReferenciaValida(referencia)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La referencia debe ser 00 y 6 dígitos')),
      );
      return;
    }

// Monto de comodato = total (preferimos el total que llegó por args si existe)
    final montoComodato = _totalArgForUi ?? _total;

    try {
      final firestore = FirebaseFirestore.instance;

// 1) Guardar pago de comodato
      await firestore.collection('pagos_comodato').add({
        'rif': _rif,
        'nombre': _clienteNombre,
        'referencia': referencia, // 00 + 6 dígitos
        'monto': montoComodato, // AUTOGENERADO por total
        'fecha': _fecha,
        'hora': _hora,
        'comercio': _comercioCtrl.text.trim(), // opcional
// contexto (por si quieres auditar)
        'lineaName': _lineaName,
        'planTitle': _planTitle,
        'planPrice': _planPrice.toStringAsFixed(2),
        'modeloSeleccionado': _modeloSeleccionado,
        'posPrice': _posPrice.toStringAsFixed(2),
        'total': montoComodato.toStringAsFixed(2),
        'serialEquipo': _serialEquipo,
        'serialSim': _serialSim,
        'createdAt': FieldValue.serverTimestamp(),
      });

// 2) Aumentar deuda (comodato suma el total a la deuda)
      final q = await firestore
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: _rif.toLowerCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final ref = q.docs.first.reference;
        await firestore.runTransaction((tx) async {
          final snap = await tx.get(ref);
          if (!snap.exists) return;
          final data = snap.data() as Map<String, dynamic>;
          final deudaActual = _toDouble(data['deuda']);
          final nuevaDeuda = deudaActual + montoComodato;
          tx.update(ref, {
            'deuda': double.parse(nuevaDeuda.toStringAsFixed(2)),
            'updated_at': FieldValue.serverTimestamp(),
          });
        });
      }

      if (!mounted) return;

// 3) Ir a comprobante / datos finales
      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          'tipo': 'comodato',

          // Comprobante comodato
          'rif': _rif,
          'fecha': _fecha,
          'hora': _hora,
          'referencia': _referenciaCtrl.text.trim(), // 00 + 6 dígitos
          'monto': montoComodato,                  // lo que cargaste a deuda

          // ⬇️ Passthrough
          'lineaName': (ModalRoute.of(context)?.settings.arguments as Map?)?['lineaName'],
          'planTitle': (ModalRoute.of(context)?.settings.arguments as Map?)?['planTitle'],
          'planDesc': (ModalRoute.of(context)?.settings.arguments as Map?)?['planDesc'],
          'planPrice': (ModalRoute.of(context)?.settings.arguments as Map?)?['planPrice'],
          'modeloSeleccionado': (ModalRoute.of(context)?.settings.arguments as Map?)?['modeloSeleccionado'],
          'posPrice': (ModalRoute.of(context)?.settings.arguments as Map?)?['posPrice'],
          'total': (ModalRoute.of(context)?.settings.arguments as Map?)?['total'],
          'serialEquipo': (ModalRoute.of(context)?.settings.arguments as Map?)?['serialEquipo'],
          'serialSim': (ModalRoute.of(context)?.settings.arguments as Map?)?['serialSim'],
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
    final totalVisual = _totalArgForUi ?? _total;

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
                  SizedBox(width: 48), // mantenemos simetría
                  Expanded(
                    child: Text(
                      'Comodato',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _resumenCard(totalVisual),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenCard(double totalVisual) {
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
          if (_clienteNombre.isNotEmpty) Text('Cliente: $_clienteNombre'),
          const SizedBox(height: 6),
          Text('Operadora: ${_lineaName.isEmpty ? '—' : _lineaName}'),
          if (_planTitle.isNotEmpty) Text('Plan: $_planTitle'),
          if (_modeloSeleccionado != null && _modeloSeleccionado!.trim().isNotEmpty)
            Text('Modelo POS: ${_modeloSeleccionado!}'),
          const SizedBox(height: 10),
          Text('Monto de comodato (se cargará a deuda): \$${totalVisual.toStringAsFixed(2)}',
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
      child: Column(
        children: [
// Comercio opcional (por consistencia con otros flujos)
          TextFormField(
            controller: _comercioCtrl,
            decoration: const InputDecoration(
              labelText: 'Comercio (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

// Referencia 00 + 6 dígitos (editable, validada)
          TextFormField(
            controller: _referenciaCtrl,
            decoration: const InputDecoration(
              labelText: 'Referencia (00 + 6 dígitos)',
              hintText: 'Ej: 00123456',
              border: OutlineInputBorder(),
            ),
            maxLength: 8,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!_isReferenciaValida(s)) return 'Debe iniciar con 00 y tener 8 dígitos (00######)';
              return null;
            },
          ),

// El MONTO NO SE EDITA (se informa solamente)
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'El monto se calcula automáticamente con el total de la venta.',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
  );
}

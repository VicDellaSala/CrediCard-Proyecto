import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasAccessComerceScreen extends StatefulWidget {
  const VentasAccessComerceScreen({super.key});

  @override
  State<VentasAccessComerceScreen> createState() => _VentasAccessComerceScreenState();
}

class _VentasAccessComerceScreenState extends State<VentasAccessComerceScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();

// Args
  String _rif = '';
  String _clienteNombre = '';
  double _totalAPagar = 0.0;

// Controles
  final _empresaCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

// Campos especiales
  final _aprobacionCtrl = TextEditingController();
  final _traceCtrl = TextEditingController();
  final _afiliadoCtrl = TextEditingController();
  final _terminalCtrl = TextEditingController();
  final _loteCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

  String? _banco;
  late final String _fecha;
  late final String _hora;

  final _bancos = const [
    'Bancamiga',
    'Banco de Venezuela',
    'Bancaribe',
    'Banco del Tesoro',
    'Bancrecer',
    'Mi Banco',
    'BANFANB',
    'Banco Activo',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _hora = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

// Defaults
    _aprobacionCtrl.text = _randomAprobacion6();
    _traceCtrl.text = _random4();
    _afiliadoCtrl.text = _random8();
    _terminalCtrl.text = _randomNDigits(4);
    _loteCtrl.text = _randomNDigits(2).padLeft(2, '0');
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
    for (var c in [
      _empresaCtrl,
      _ubicacionCtrl,
      _montoCtrl,
      _aprobacionCtrl,
      _traceCtrl,
      _afiliadoCtrl,
      _terminalCtrl,
      _loteCtrl,
      _referenciaCtrl
    ]) {
      c.dispose();
    }
    super.dispose();
  }

// ====================== Utils ======================
  String _random4() => (Random().nextInt(9000) + 1000).toString();
  String _random8() => (Random().nextInt(90000000) + 10000000).toString();
  String _randomNDigits(int n) => List.generate(n, (_) => Random().nextInt(10)).join();
  String _randomAprobacion6() => '0${(Random().nextInt(90000) + 10000)}';

  double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v.replaceAll(RegExp(r'[^\d.,]'), '').replaceAll(',', '.');
      return double.tryParse(s) ?? 0;
    }
    return 0;
  }

  bool _isAprobacionValida(String v) => RegExp(r'^0\d{5}$').hasMatch(v);
  bool _isTraceValido(String v) => RegExp(r'^\d{4}$').hasMatch(v);
  bool _isAfiliadoValido(String v) => RegExp(r'^\d{8}$').hasMatch(v);
  bool _isTerminalValida(String v) => RegExp(r'^\d{4}$').hasMatch(v);
  bool _isLoteValido(String v) => RegExp(r'^\d{2}$').hasMatch(v);
  bool _isReferenciaValida(String v) => RegExp(r'^00\d{4}$').hasMatch(v);

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
        setState(() {
          final nombre = (d['first_name'] ?? '').toString();
          final apellido = (d['last_name'] ?? '').toString();
          _clienteNombre = [nombre, apellido].where((x) => x.trim().isNotEmpty).join(' ');
        });
      }
    } catch (_) {}
  }

// ====================== Guardar ======================
  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_banco == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selecciona el banco.')));
      return;
    }

    final empresa = _empresaCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final aprobacion = _aprobacionCtrl.text.trim();
    final trace = _traceCtrl.text.trim();
    final afiliado = _afiliadoCtrl.text.trim();
    final terminal = _terminalCtrl.text.trim();
    final lote = _loteCtrl.text.trim();
    final referencia = _referenciaCtrl.text.trim();
    final montoPag = _toDouble(_montoCtrl.text);

    try {
      final firestore = FirebaseFirestore.instance;

      await firestore.collection('pagos_access_comerce').add({
        'rif': _rif,
        'nombre': _clienteNombre,
        'empresa': empresa,
        'ubicacion': ubicacion,
        'banco': _banco,
        'aprobacion': aprobacion,
        'trace': trace,
        'afiliado': afiliado,
        'terminal': terminal,
        'lote': lote,
        'referencia': referencia,
        'monto': montoPag,
        'fecha': _fecha,
        'hora': _hora,
        'createdAt': FieldValue.serverTimestamp(),
      });

// Deuda
      final diff = montoPag - _totalAPagar;
      final q = await firestore
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: _rif.toLowerCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final ref = q.docs.first.reference;
        final data = q.docs.first.data();
        final double deudaActual = _toDouble(data['deuda']);
        double nuevaDeuda = deudaActual;

        if (diff < 0) nuevaDeuda += (-diff);
        else if (diff > 0) nuevaDeuda = (deudaActual - diff).clamp(0, double.infinity);

        await ref.update({
          'deuda': double.parse(nuevaDeuda.toStringAsFixed(2)),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          'tipo': 'access',
          'rif': _rif,
          'monto': montoPag,
          'total': _totalAPagar,
          'banco': _banco,
          'aprobacion': aprobacion,
          'trace': trace,
          'afiliado': afiliado,
          'empresa': empresa,
          'ubicacion': ubicacion,
          'terminal': terminal,
          'lote': lote,
          'referencia': referencia, // ✅ ahora sí se llama igual que en el comprobante
          'fecha': _fecha,
          'hora': _hora,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              child: const Center(
                child: Text(
                  'Access / Comerce',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                ),
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
          const Row(
            children: [
              Icon(Icons.receipt_long, color: Colors.black54),
              SizedBox(width: 8),
              Text('Resumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 10),
          if (_rif.isNotEmpty) Text('RIF: $_rif'),
          if (_clienteNombre.isNotEmpty) Text('Cliente: $_clienteNombre'),
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
      child: Column(
        children: [
          _input(_empresaCtrl, 'Nombre de la empresa / local'),
          _input(_ubicacionCtrl, 'Ubicación de la empresa / local'),
          _dropdownBanco(),
          _input(_aprobacionCtrl, 'N° de aprobación (0 + 5 dígitos)',
              validator: (v) => _isAprobacionValida((v ?? '').trim()) ? null : 'Formato inválido'),
          _input(_traceCtrl, 'Trace (4 dígitos)',
              validator: (v) => _isTraceValido((v ?? '').trim()) ? null : '4 dígitos'),
          _input(_afiliadoCtrl, 'Afiliado (8 dígitos)',
              validator: (v) => _isAfiliadoValido((v ?? '').trim()) ? null : '8 dígitos'),
          Row(
            children: [
              Expanded(child: _input(_terminalCtrl, 'Terminal (4 dígitos)',
                  validator: (v) => _isTerminalValida((v ?? '').trim()) ? null : '4 dígitos')),
              const SizedBox(width: 12),
              Expanded(child: _input(_loteCtrl, 'Lote (2 dígitos)',
                  validator: (v) => _isLoteValido((v ?? '').trim()) ? null : '2 dígitos')),
            ],
          ),
          _input(_referenciaCtrl, 'Referencia (00 + 4 dígitos)',
              validator: (v) => _isReferenciaValida((v ?? '').trim()) ? null : 'Debe ser 00####'),
          _input(_montoCtrl, 'Monto transferido (ej: 206.00)',
              validator: (v) => _toDouble(v) <= 0 ? 'Monto inválido' : null),
        ],
      ),
    );
  }

  Widget _input(TextEditingController c, String label, {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: validator ??
                (v) => (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null,
      ),
    );
  }

  Widget _dropdownBanco() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: _banco,
        decoration: const InputDecoration(labelText: 'Banco', border: OutlineInputBorder()),
        items: _bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
        onChanged: (v) => setState(() => _banco = v),
        validator: (v) => v == null ? 'Selecciona el banco' : null,
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
  );
}

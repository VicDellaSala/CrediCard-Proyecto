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

// Args que llegan (igual que en los otros flujos)
  String _rif = '';
  String _clienteNombre = ''; // opcional, lo buscamos por RIF
  double _totalAPagar = 0.0;

// Controles
  final _empresaCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

// Campos especiales
  final _aprobacionCtrl = TextEditingController(); // 6 dígitos iniciando en 0
  final _traceCtrl = TextEditingController(); // 4 dígitos
  final _afiliadoCtrl = TextEditingController(); // 8 dígitos

  String? _banco;
  late final String _fecha; // yyyy-mm-dd
  late final String _hora; // HH:mm

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
    _fecha = "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _hora = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

// Generamos por defecto (EDITABLES):
    _aprobacionCtrl.text = _randomAprobacion6(); // 6 dígitos empezando por 0
    _traceCtrl.text = _random4(); // 4 dígitos
    _afiliadoCtrl.text = _random8(); // 8 dígitos
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
    _empresaCtrl.dispose();
    _ubicacionCtrl.dispose();
    _montoCtrl.dispose();
    _aprobacionCtrl.dispose();
    _traceCtrl.dispose();
    _afiliadoCtrl.dispose();
    super.dispose();
  }

// ====================== Utils ======================

  String _random4() => (Random().nextInt(9000) + 1000).toString(); // 4 dígitos
  String _random8() => (Random().nextInt(90000000) + 10000000).toString(); // 8 dígitos

// 6 dígitos que INICIE en 0: "0" + 5 dígitos aleatorios
  String _randomAprobacion6() {
    final tail = (Random().nextInt(90000) + 10000).toString(); // 5 dígitos
    return '0$tail'; // ej: 045678
  }

  double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) {
      final s = v
          .replaceAll('\$', '')
          .replaceAll('USD', '')
          .replaceAll('Bs', '')
          .replaceAll(',', '.')
          .trim();
      return double.tryParse(s) ?? 0;
    }
    return 0;
  }

  bool _isAprobacionValida(String v) => RegExp(r'^0\d{5}$').hasMatch(v); // 6 dígitos empezando en 0
  bool _isTraceValido(String v) => RegExp(r'^\d{4}$').hasMatch(v); // 4 dígitos
  bool _isAfiliadoValido(String v) => RegExp(r'^\d{8}$').hasMatch(v); // 8 dígitos

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
        setState(() {
          _clienteNombre = [nombre, apellido].where((e) => e.trim().isNotEmpty).join(' ').trim();
        });
      }
    } catch (_) {}
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_banco == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona el banco.')),
      );
      return;
    }

    final empresa = _empresaCtrl.text.trim();
    final ubicacion = _ubicacionCtrl.text.trim();
    final aprobacion = _aprobacionCtrl.text.trim();
    final trace = _traceCtrl.text.trim();
    final afiliado = _afiliadoCtrl.text.trim();
    final montoPag = _toDouble(_montoCtrl.text);

    try {
      final firestore = FirebaseFirestore.instance;

// 1) Guardar pago Access/Comerce
      await firestore.collection('pagos_access_comerce').add({
        'rif': _rif,
        'nombre': _clienteNombre,
        'empresa': empresa,
        'ubicacion': ubicacion,
        'banco': _banco,
        'aprobacion': aprobacion, // debe iniciar en 0 (validado)
        'trace': trace, // 4 dígitos
        'afiliado': afiliado, // 8 dígitos
        'monto': montoPag,
        'fecha': _fecha,
        'hora': _hora,
        'createdAt': FieldValue.serverTimestamp(),
      });

// 2) Ajustar deuda en Cliente_completo
// Si monto < total → deuda += (total - monto)
// Si monto > total → deuda -= (monto - total) (sin bajar de 0)
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
        double nuevaDeuda;
        if (diff < 0) {
// Pagó menos → aumenta deuda
          nuevaDeuda = deudaActual + (-diff);
        } else if (diff > 0) {
// Pagó de más → reduce deuda
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pago Access/Comerce guardado.')),
      );

// 3) Ir a datos finales
      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          'rif': _rif,
          'monto': montoPag,
          'total': _totalAPagar,
          'banco': _banco,
          'aprobacion': aprobacion,
          'trace': trace,
          'afiliado': afiliado,
          'empresa': empresa,
          'ubicacion': ubicacion,
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
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const Spacer(),
                  const Text(
                    'Access / Comerce',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
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
          Row(children: const [
            Icon(Icons.receipt_long, color: Colors.black54),
            SizedBox(width: 8),
            Text('Resumen', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          Text('RIF: ${_rif.isEmpty ? '—' : _rif}'),
          Text('Cliente: ${_clienteNombre.isEmpty ? '—' : _clienteNombre}'),
          const SizedBox(height: 6),
          Text('Total a pagar: \$${_totalAPagar.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w800)),
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
// Empresa / Local
          TextFormField(
            controller: _empresaCtrl,
            decoration: const InputDecoration(
              labelText: 'Nombre de la empresa / local',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa el nombre de la empresa o local' : null,
          ),
          const SizedBox(height: 12),

// Ubicación
          TextFormField(
            controller: _ubicacionCtrl,
            decoration: const InputDecoration(
              labelText: 'Ubicación de la empresa / local',
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Ingresa la ubicación' : null,
          ),
          const SizedBox(height: 12),

// Banco
          DropdownButtonFormField<String>(
            value: _banco,
            decoration: const InputDecoration(
              labelText: 'Banco',
              border: OutlineInputBorder(),
            ),
            items: _bancos.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
            onChanged: (v) => setState(() => _banco = v),
            validator: (v) => v == null ? 'Selecciona el banco' : null,
          ),
          const SizedBox(height: 12),

// Aprobación (6 dígitos, empezando en 0)
          TextFormField(
            controller: _aprobacionCtrl,
            decoration: const InputDecoration(
              labelText: 'N° de aprobación (debe iniciar con 0)',
              border: OutlineInputBorder(),
            ),
            maxLength: 6,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!_isAprobacionValida(s)) return 'Formato inválido (0 + 5 dígitos)';
              return null;
            },
          ),
          const SizedBox(height: 12),

// Trace (4 dígitos)
          TextFormField(
            controller: _traceCtrl,
            decoration: const InputDecoration(
              labelText: 'Trace (4 dígitos)',
              border: OutlineInputBorder(),
            ),
            maxLength: 4,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!_isTraceValido(s)) return 'Deben ser 4 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 12),

// Afiliado (8 dígitos)
          TextFormField(
            controller: _afiliadoCtrl,
            decoration: const InputDecoration(
              labelText: 'Afiliado (8 dígitos)',
              border: OutlineInputBorder(),
            ),
            maxLength: 8,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!_isAfiliadoValido(s)) return 'Deben ser 8 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 12),

// Monto transferido
          TextFormField(
            controller: _montoCtrl,
            decoration: const InputDecoration(
              labelText: 'Monto transferido',
              hintText: 'Ej: 206.00',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.').trim());
              if (n == null || n <= 0) return 'Monto inválido';
              return null;
            },
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

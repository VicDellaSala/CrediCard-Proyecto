import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasTransferenciaBancariaScreen extends StatefulWidget {
  const VentasTransferenciaBancariaScreen({super.key});

  @override
  State<VentasTransferenciaBancariaScreen> createState() =>
      _VentasTransferenciaBancariaScreenState();
}

class _VentasTransferenciaBancariaScreenState extends State<VentasTransferenciaBancariaScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();

// Args
  String _rif = '';
  String _clienteNombre = ''; // opcional, intentamos leerlo de Cliente_completo
  double _totalAPagar = 0.0;

// Campos del formulario
  final _comercioCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _afiliadoCtrl = TextEditingController(); // ← inicia vacío
  final _aprobacionCtrl = TextEditingController();
  final _referenciaCtrl = TextEditingController();

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
    _fecha =
    "${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    _hora =
    "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

// Generar un número de aprobación de 6 dígitos (editable)
    _aprobacionCtrl.text = _random6();

// referencia inicia vacía (y se valida ^00\d{4}$)
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
    (ModalRoute.of(context)?.settings.arguments ?? {}) as Map<String, dynamic>;

    _rif = (args['rif'] ?? '').toString();
    _totalAPagar = _toDouble(args['total']);

// Intentar cargar nombre cliente de Cliente_completo (opcional, no bloquea)
    _cargarNombreClientePorRif(_rif);
  }

  @override
  void dispose() {
    _comercioCtrl.dispose();
    _montoCtrl.dispose();
    _afiliadoCtrl.dispose();
    _aprobacionCtrl.dispose();
    _referenciaCtrl.dispose();
    super.dispose();
  }

// Utils
  String _random6() => (Random().nextInt(900000) + 100000).toString();

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

  bool _isReferenciaValida(String v) => RegExp(r'^00\d{4}$').hasMatch(v); // 00 + 4 dígitos

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
        setState(() => _clienteNombre = [nombre, apellido]
            .where((e) => e.trim().isNotEmpty)
            .join(' ')
            .trim());
      }
    } catch (_) {}
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_banco == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Selecciona el banco.')));
      return;
    }

    final monto = _toDouble(_montoCtrl.text);
    final afiliado = _afiliadoCtrl.text.trim();
    final aprobacion = _aprobacionCtrl.text.trim();
    final referencia = _referenciaCtrl.text.trim();
    final comercio = _comercioCtrl.text.trim();

    try {
      final firestore = FirebaseFirestore.instance;

// 1) Guardar la transferencia
      await firestore.collection('transferencias_bancarias').add({
        'rif': _rif,
        'nombre': _clienteNombre,
        'banco': _banco,
        'afiliado': afiliado,
        'aprobacion': aprobacion,
        'referencia': referencia,
        'monto': monto,
        'fecha': _fecha,
        'hora': _hora,
        'comercio': comercio,
        'createdAt': FieldValue.serverTimestamp(),
      });

// 2) Ajustar deuda en Cliente_completo
// Si monto < total → deuda += (total - monto)
// Si monto > total → deuda -= (monto - total) (sin bajar de 0)
      final diff = monto - _totalAPagar;

      final q = await firestore
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: _rif.toLowerCase())
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final docRef = q.docs.first.reference;
        final data = q.docs.first.data();

        final double deudaActual = _toDouble(data['deuda']);
        double nuevaDeuda;
        if (diff < 0) {
// pagó menos → aumenta deuda
          nuevaDeuda = deudaActual + (-diff);
        } else if (diff > 0) {
// pagó de más → reduce deuda
          final tmp = deudaActual - diff;
          nuevaDeuda = tmp < 0 ? 0 : tmp;
        } else {
          nuevaDeuda = deudaActual; // exacto, no cambia
        }

        await docRef.update({
          'deuda': double.parse(nuevaDeuda.toStringAsFixed(2)),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Transferencia guardada.')));

// ⬇️⬇️ CAMBIO: enviamos el tipo para que la factura se pinte correctamente
      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          // Identificación del tipo
          'tipo': 'transferencia',

          // Comprobante (ya lo tenías)
          'rif': _rif,
          'monto': monto,
          'total': _totalAPagar,
          'banco': _banco,
          'afiliado': afiliado,
          'aprobacion': aprobacion,
          'referencia': referencia,
          'fecha': _fecha,
          'hora': _hora,
          'comercio': comercio,

          // ⬇️ Passthrough para que no se pierdan
          'lineaName': (ModalRoute.of(context)?.settings.arguments as Map?)?['lineaName'],
          'planTitle': (ModalRoute.of(context)?.settings.arguments as Map?)?['planTitle'],
          'planDesc': (ModalRoute.of(context)?.settings.arguments as Map?)?['planDesc'],
          'planPrice': (ModalRoute.of(context)?.settings.arguments as Map?)?['planPrice'],
          'modeloSeleccionado': (ModalRoute.of(context)?.settings.arguments as Map?)?['modeloSeleccionado'],
          'posPrice': (ModalRoute.of(context)?.settings.arguments as Map?)?['posPrice'],
          'serialEquipo': (ModalRoute.of(context)?.settings.arguments as Map?)?['serialEquipo'],
          'serialSim': (ModalRoute.of(context)?.settings.arguments as Map?)?['serialSim'],
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error inesperado: $e')));
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
              decoration:
              BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
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
                    'Transferencia bancaria',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
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
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
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
            Text('Resumen',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
      child: Column(
        children: [
          TextFormField(
            controller: _comercioCtrl,
            decoration: const InputDecoration(
              labelText: 'Comercio (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

// Banco
          DropdownButtonFormField<String>(
            value: _banco,
            decoration: const InputDecoration(
              labelText: 'Banco',
              border: OutlineInputBorder(),
            ),
            items: _bancos
                .map((b) => DropdownMenuItem(value: b, child: Text(b)))
                .toList(),
            onChanged: (v) => setState(() => _banco = v),
            validator: (v) => v == null ? 'Selecciona el banco' : null,
          ),
          const SizedBox(height: 12),

// Afiliado (manual; empieza vacío)
          TextFormField(
            controller: _afiliadoCtrl,
            decoration: const InputDecoration(
              labelText: 'Afiliado (8 dígitos)',
              hintText: '########',
              border: OutlineInputBorder(),
            ),
            maxLength: 8,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (s.isEmpty) return 'Ingresa el número de afiliado';
              if (!RegExp(r'^\d{8}$').hasMatch(s)) return 'Deben ser 8 dígitos';
              return null;
            },
          ),
          const SizedBox(height: 12),

// Aprobación
          TextFormField(
            controller: _aprobacionCtrl,
            decoration: const InputDecoration(
              labelText: 'N° de aprobación (6 dígitos)',
              border: OutlineInputBorder(),
            ),
            maxLength: 6,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!RegExp(r'^\d{6}$').hasMatch(s)) {
                return 'Deben ser 6 dígitos';
              }
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
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            validator: (v) {
              final n =
              double.tryParse((v ?? '').replaceAll(',', '.').trim());
              if (n == null || n <= 0) return 'Monto inválido';
              return null;
            },
          ),
          const SizedBox(height: 12),

// Referencia: debe iniciar con 00 + 4 dígitos
          TextFormField(
            controller: _referenciaCtrl,
            decoration: const InputDecoration(
              labelText: 'Referencia (formato 00####)',
              hintText: 'Ej: 001234',
              border: OutlineInputBorder(),
            ),
            maxLength: 6,
            keyboardType: TextInputType.number,
            validator: (v) {
              final s = (v ?? '').trim();
              if (!_isReferenciaValida(s)) {
                return 'Debe empezar con 00 y tener 6 dígitos (00####)';
              }
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
    boxShadow: const [
      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
    ],
  );
}

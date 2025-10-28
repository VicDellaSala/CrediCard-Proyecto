import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Pago por Punto de Venta (PDV)
/// - Muestra el total a pagar
/// - Pide datos del voucher PDV (banco, marca, terminal, afiliado, lote, referencia, etc.)
/// - Guarda en /pagos_pdv
/// - Ajusta la deuda en Cliente_completo (deuda += total - montoPagado)
/// - Navega a /ventas/datos-finales
class VentaPdvPagoScreen extends StatefulWidget {
  const VentaPdvPagoScreen({super.key});

  @override
  State<VentaPdvPagoScreen> createState() => _VentaPdvPagoScreenState();
}

class _VentaPdvPagoScreenState extends State<VentaPdvPagoScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();

// ------- Argumentos que llegan desde Contado/Financiado -------
  String _rif = '';
  String _lineaName = '';
  String _planTitle = '';
  String _planPriceStr = '0';
  String? _modeloSeleccionado;
  String _posPriceStr = '0';
  String? _serialEquipo;
  String? _serialSim;

  double get _planPrice => _parseMoney(_planPriceStr);
  double get _posPrice => _parseMoney(_posPriceStr);
  double get _total => _planPrice + _posPrice;

// ------- Campos PDV -------
  final _comercioCtrl = TextEditingController();
  final _afiliadoCtrl = TextEditingController(); // 8 dígitos
  final _terminalCtrl = TextEditingController(); // 2 letras + 3 dígitos (p.ej. FR123) (editable)
  final _aprobacionCtrl = TextEditingController(); // 6 dígitos (editable)
  final _loteCtrl = TextEditingController(); // "000" + 3 dígitos (6 en total)
  final _referenciaCtrl = TextEditingController(); // "0000" + 2 dígitos (6 en total)
  final _montoCtrl = TextEditingController(); // monto pagado

  String? _bancoPdv; // dropdown banco emisior PDV
  String _cardBrand = 'Visa'; // Visa / MasterCard

  late final String _fecha; // yyyy-MM-dd
  late final String _hora; // HH:mm

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _fecha =
    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    _hora = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

// Por defecto: terminal, aprobación, lote, referencia
    _terminalCtrl.text = _randTerminal();
    _aprobacionCtrl.text = _randDigits(6);
    _loteCtrl.text = '000${_randDigits(3)}'; // 000 + 3 dígitos
    _referenciaCtrl.text = '0000${_randDigits(2)}'; // 0000 + 2 dígitos
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
  }

  @override
  void dispose() {
    _comercioCtrl.dispose();
    _afiliadoCtrl.dispose();
    _terminalCtrl.dispose();
    _aprobacionCtrl.dispose();
    _loteCtrl.dispose();
    _referenciaCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

// -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    final bancos = const [
      'Banco de Venezuela',
      'Bancamiga',
      'Bancaribe',
      'Banco del Tesoro',
      'Bancrecer',
      'Mi Banco',
      'Banfanb',
      'Banco Activo',
    ];

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
                    'Pago por Punto de Venta (PDV)',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
// Resumen
                      _card(
                        title: 'Resumen de compra',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _rowIconText(Icons.person_outline,
                                'Cliente (RIF): ${_rif.isEmpty ? '—' : _rif}'),
                            _rowIconText(Icons.hub_outlined,
                                'Operadora: ${_lineaName.isEmpty ? '—' : _lineaName}'),
                            const SizedBox(height: 8),
                            const Text('Plan seleccionado:',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                                '• ${_planTitle.isEmpty ? 'Plan' : _planTitle} — \$${_planPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 8),
                            const Text('Modelo de POS:',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            Text(
                                '• ${_modeloSeleccionado ?? '—'} — \$${_posPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 10),
                            Text('TOTAL: \$${_total.toStringAsFixed(2)}',
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

// Formulario PDV
                      _card(
                        title: 'Datos del voucher PDV',
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
// Banco del PDV
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Banco del PDV',
                                  border: OutlineInputBorder(),
                                ),
                                items: bancos
                                    .map((b) =>
                                    DropdownMenuItem(value: b, child: Text(b)))
                                    .toList(),
                                value: _bancoPdv,
                                onChanged: (v) => setState(() => _bancoPdv = v),
                                validator: (v) =>
                                v == null ? 'Selecciona el banco' : null,
                              ),
                              const SizedBox(height: 12),

// Comercio
                              TextFormField(
                                controller: _comercioCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Comercio',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (v) => (v == null || v.trim().isEmpty)
                                    ? 'Ingresa el comercio'
                                    : null,
                              ),
                              const SizedBox(height: 12),

// Fecha y hora (solo lectura)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Fecha',
                                        border: const OutlineInputBorder(),
                                        hintText: _fecha,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        labelText: 'Hora',
                                        border: const OutlineInputBorder(),
                                        hintText: _hora,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

// Marca de tarjeta
                              DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Marca de tarjeta',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                      value: 'Visa', child: Text('Visa')),
                                  DropdownMenuItem(
                                      value: 'MasterCard',
                                      child: Text('MasterCard')),
                                ],
                                value: _cardBrand,
                                onChanged: (v) =>
                                    setState(() => _cardBrand = v ?? 'Visa'),
                              ),
                              const SizedBox(height: 12),

// Terminal (2 letras + 3 dígitos), Aprobación (6 dígitos)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _terminalCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Terminal (p.ej. FR123)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) {
                                        final s =
                                        (v ?? '').trim().toUpperCase();
                                        final ok = RegExp(r'^[A-Z]{2}\d{3}$')
                                            .hasMatch(s);
                                        return ok ? null : 'Formato inválido';
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _aprobacionCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Aprobación (6 dígitos)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => RegExp(r'^\d{6}$')
                                          .hasMatch((v ?? '').trim())
                                          ? null
                                          : '6 dígitos',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

// Afiliado (8 dígitos), Lote (000 + 3 dígitos)
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _afiliadoCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Afiliado (8 dígitos)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => RegExp(r'^\d{8}$')
                                          .hasMatch((v ?? '').trim())
                                          ? null
                                          : '8 dígitos',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _loteCtrl,
                                      decoration: const InputDecoration(
                                        labelText: 'Lote (000 + 3 dígitos)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => RegExp(r'^000\d{3}$')
                                          .hasMatch((v ?? '').trim())
                                          ? null
                                          : 'Ej: 000123',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

// Referencia (0000 + 2 dígitos), Monto pagado
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _referenciaCtrl,
                                      decoration: const InputDecoration(
                                        labelText:
                                        'Referencia (0000 + 2 dígitos)',
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (v) => RegExp(r'^0000\d{2}$')
                                          .hasMatch((v ?? '').trim())
                                          ? null
                                          : 'Ej: 000012',
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _montoCtrl,
                                      decoration: InputDecoration(
                                        labelText:
                                        'Monto pagado (Total: \$${_total.toStringAsFixed(2)})',
                                        border: const OutlineInputBorder(),
                                      ),
                                      keyboardType:
                                      TextInputType.numberWithOptions(
                                          decimal: true),
                                      validator: (v) {
                                        final n = double.tryParse(
                                            (v ?? '')
                                                .replaceAll(',', '.')
                                                .trim());
                                        if (n == null || n <= 0) {
                                          return 'Monto inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),
                      SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _onGuardar,
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
          ],
        ),
      ),
    );
  }

// -------------------- Acciones --------------------
  Future<void> _onGuardar() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sesión inválida')));
      return;
    }

    final banco = _bancoPdv ?? '';
    final comercio = _comercioCtrl.text.trim();
    final afiliado = _afiliadoCtrl.text.trim();
    final terminal = _terminalCtrl.text.trim().toUpperCase();
    final aprobacion = _aprobacionCtrl.text.trim();
    final lote = _loteCtrl.text.trim();
    final referencia = _referenciaCtrl.text.trim();
    final montoPagado =
    double.parse(_montoCtrl.text.replaceAll(',', '.').trim());

// Si el cliente ya tiene afiliación en Cliente_completo, úsala
    final afiliadoFinal = await _afiliadoPreferido(afiliado);

    try {
// 1) Guardar pago PDV
      final payload = {
        'rif': _rif,
        'nombre': _comercioCtrl.text.trim(), // o el nombre del comercio
        'banco': banco,
        'cardBrand': _cardBrand,
        'terminal': terminal,
        'afiliado': afiliadoFinal,
        'aprobacion': aprobacion,
        'lote': lote,
        'referencia': referencia,
        'monto': montoPagado,

// contexto de la compra
        'lineaName': _lineaName,
        'planTitle': _planTitle,
        'planPrice': _planPrice.toStringAsFixed(2),
        'modeloSeleccionado': _modeloSeleccionado,
        'posPrice': _posPrice.toStringAsFixed(2),
        'total': _total.toStringAsFixed(2),
        'serialEquipo': _serialEquipo,
        'serialSim': _serialSim,

// marcas de tiempo y autores
        'fecha': _fecha,
        'hora': _hora,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      };

      await FirebaseFirestore.instance.collection('pagos_pdv').add(payload);

// 2) Ajustar deuda: deudaNueva = deudaActual + (total - montoPagado)
      await _ajustarDeudaCliente(_rif, _total, montoPagado);

      if (!mounted) return;
// --------- ÚNICO CAMBIO CRÍTICO ---------
      final prevArgs =
          (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?) ?? {};

      Navigator.pushNamed(
        context,
        '/ventas/datos-finales',
        arguments: {
          'tipo': 'pdv',
          'rif': _rif,
          'banco': banco,
          'cardBrand': _cardBrand,
          'comercio': comercio,
          'afiliado': afiliadoFinal,
          'terminal': terminal,
          'lote': lote,
          'fecha': _fecha,
          'hora': _hora,
          'aprobacion': aprobacion,
          'referencia': referencia,
          'monto': montoPagado,

          // Passthrough correcto desde prevArgs
          'lineaName': prevArgs['lineaName'],
          'planTitle': prevArgs['planTitle'],
          'planDesc': prevArgs['planDesc'],
          'planPrice': prevArgs['planPrice'],
          'modeloSeleccionado': prevArgs['modeloSeleccionado'],
          'posPrice': prevArgs['posPrice'],
          'total': prevArgs['total'],
          'serialEquipo': prevArgs['serialEquipo'],
          'serialSim': prevArgs['serialSim'],
        },
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<String> _afiliadoPreferido(String afiliadoIngresado) async {
    final rifLower = _rif.trim().toLowerCase();
    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rifLower)
          .limit(1)
          .get();
      if (q.docs.isNotEmpty) {
        final data = q.docs.first.data();
        final af = (data['afiliacion_numero'] ?? '').toString().trim();
        if (af.isNotEmpty && RegExp(r'^\d{8}$').hasMatch(af)) {
          return af;
        }
      }
    } catch (_) {}
    return afiliadoIngresado; // fallback al ingresado
  }

  Future<void> _ajustarDeudaCliente(
      String rif, double total, double pagado) async {
    final rifLower = rif.trim().toLowerCase();
    final col = FirebaseFirestore.instance.collection('Cliente_completo');
    final q = await col.where('rif_lower', isEqualTo: rifLower).limit(1).get();

    if (q.docs.isEmpty) return;

    final docRef = col.doc(q.docs.first.id);
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final deudaActual = _asDoubleSafe(data['deuda']);
      final diff = total - pagado; // si es negativo, reduce deuda
      final nueva = deudaActual + diff;
      tx.update(docRef, {
        'deuda': nueva,
        'updated_at': FieldValue.serverTimestamp(),
      });
    });
  }

// -------------------- Helpers --------------------
  static double _parseMoney(String raw) {
    final s = raw
        .replaceAll('\$', '')
        .replaceAll('USD', '')
        .replaceAll('Bs', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(s) ?? 0.0;
  }

  static double _asDoubleSafe(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.replaceAll(',', '.')) ?? 0.0;
    return 0.0;
  }

  static String _randDigits(int n) {
    final r = Random.secure();
    String s = '';
    for (var i = 0; i < n; i++) {
      s += r.nextInt(10).toString();
    }
    return s;
  }

  static String _randTerminal() {
    final r = Random.secure();
    final letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    final a = letters[r.nextInt(letters.length)];
    final b = letters[r.nextInt(letters.length)];
    final d1 = r.nextInt(10).toString();
    final d2 = r.nextInt(10).toString();
    final d3 = r.nextInt(10).toString();
    return '$a$b$d1$d2$d3';
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.receipt_long, color: Colors.black54),
            const SizedBox(width: 8),
            Text(title,
                style:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _rowIconText(IconData i, String t) {
    return Row(
      children: [
        Icon(i, color: Colors.black54),
        const SizedBox(width: 8),
        Expanded(child: Text(t)),
      ],
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasGuardarTodoScreen extends StatefulWidget {
  const VentasGuardarTodoScreen({super.key});

  @override
  State<VentasGuardarTodoScreen> createState() => _VentasGuardarTodoScreenState();
}

class _VentasGuardarTodoScreenState extends State<VentasGuardarTodoScreen> {
  static const _panelColor = Color(0xFFAED6D8);

// ---- args base (todo llega por arguments) ----
  late final Map<String, dynamic> _args;
  String _rif = '';
  String? _lineaName;
  String? _planTitle;
  String? _planDesc;
  String? _planPriceStr;
  String? _modeloSeleccionado;
  String? _posPriceStr;
  String? _totalStr;
  String? _serialEquipo;
  String? _serialSim;

// tipo de pago (para render del método + reenviar al comprobante)
  String _tipo = ''; // 'transferencia' | 'pdv' | 'efectivo' | 'access' | 'comodato'

// Cliente (Firestore)
  DocumentSnapshot<Map<String, dynamic>>? _clienteDoc;
  bool _loadingCliente = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};

// Datos comunes de la venta (pueden venir desde varias pantallas)
    _rif = (_args['rif'] ?? '').toString();
    _lineaName = _args['lineaName']?.toString();
    _planTitle = _args['planTitle']?.toString();
    _planDesc = _args['planDesc']?.toString();
    _planPriceStr = _args['planPrice']?.toString();
    _modeloSeleccionado = _args['modeloSeleccionado']?.toString();
    _posPriceStr = _args['posPrice']?.toString();
    _totalStr = (_args['total'] ?? _args['monto'] ?? '').toString(); // a veces llega como 'monto'
    _serialEquipo = _args['serialEquipo']?.toString();
    _serialSim = _args['serialSim']?.toString();

    _tipo = (_args['tipo'] ?? '').toString().toLowerCase();

    _cargarClientePorRif();
  }

  Future<void> _cargarClientePorRif() async {
    if (_rif.isEmpty) {
      setState(() => _loadingCliente = false);
      return;
    }
    try {
      final q = await FirebaseFirestore.instance
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: _rif.toLowerCase())
          .limit(1)
          .get();

      if (mounted) {
        setState(() {
          _clienteDoc = q.docs.isNotEmpty ? q.docs.first : null;
          _loadingCliente = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCliente = false);
    }
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

// ------------------- UI -------------------
  @override
  Widget build(BuildContext context) {
    final total = _toDouble(_totalStr);

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
                    'Guardar todo',
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _card(
                          title: 'Resumen de compra',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _kv('RIF', _rif.isEmpty ? '—' : _rif),
                              if (_lineaName?.isNotEmpty == true) _kv('Operadora', _lineaName!),
                              const SizedBox(height: 10),
                              const Text('Plan', style: TextStyle(fontWeight: FontWeight.w700)),
                              _bul('Título', _planTitle),
                              _bul('Descripción', _planDesc),
                              _bul('Precio plan', _money(_toDouble(_planPriceStr))),
                              const SizedBox(height: 10),
                              const Text('Equipo (POS)', style: TextStyle(fontWeight: FontWeight.w700)),
                              _bul('Modelo', _modeloSeleccionado),
                              _bul('Serial equipo', _serialEquipo),
                              _bul('Serial SIM', _serialSim),
                              _bul('Precio POS', _money(_toDouble(_posPriceStr))),
                              const SizedBox(height: 10),
                              Text('TOTAL: ${_money(total)}',
                                  style: const TextStyle(fontWeight: FontWeight.w800)),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        _card(
                          title: 'Datos del cliente',
                          trailing: _loadingCliente ? const SizedBox(
                            height: 16, width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ) : null,
                          child: _loadingCliente
                              ? const SizedBox.shrink()
                              : (_clienteDoc == null
                              ? const Text('No se encontró el cliente en Cliente_completo.')
                              : _ClienteExpandable(data: _clienteDoc!.data()!, rif: _rif)),
                        ),

                        const SizedBox(height: 14),

                        _card(
                          title: 'Método de pago',
                          child: _MetodoPagoView(tipo: _tipo, args: _args),
                        ),

                        const SizedBox(height: 18),

// Botones de acción
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: OutlinedButton.icon(
                                  onPressed: _verComprobante,
                                  icon: const Icon(Icons.receipt_long),
                                  label: const Text('Ver comprobante'),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: _guardarYTerminar,
                                  icon: const Icon(Icons.save_alt),
                                  label: const Text('Guardar y terminar'),
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  void _verComprobante() {
// Reabrimos ventas_datos_finales con los mismos arguments que nos llegaron.
    Navigator.pushNamed(context, '/ventas/datos-finales', arguments: _args);
  }

  void _guardarYTerminar() {
// Aquí luego integramos la lógica que decidas (cerrar flujo, crear documento maestro, etc.)
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OK. Pendiente: lógica final de “Guardar y terminar”.')),
    );
// Si quieres volver al panel del operador, por ejemplo:
// Navigator.of(context).pushNamedAndRemoveUntil('/operator/ventas', (r) => false);
  }

// ------ helpers UI ------
  Widget _card({required String title, Widget? trailing, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.description_outlined, color: Colors.black54),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              if (trailing != null) trailing,
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(k)),
          Expanded(child: Text(v, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _bul(String k, String? v) {
    if ((v ?? '').toString().trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87),
                children: [
                  TextSpan(text: '$k: ', style: const TextStyle(fontWeight: FontWeight.w700)),
                  TextSpan(text: v),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

class _ClienteExpandable extends StatelessWidget {
  final Map<String, dynamic> data;
  final String rif;

  const _ClienteExpandable({required this.data, required this.rif});

  @override
  Widget build(BuildContext context) {
// ordenamos claves para que sea predecible
    final entries = data.entries.toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('RIF: ${rif.isEmpty ? '—' : rif}'),
      subtitle: const Text('Toca para ver todos los datos del cliente'),
      children: [
        const SizedBox(height: 6),
        ...entries.map((e) {
          final key = e.key.toString();
          final val = _pretty(e.value);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(key)),
                Expanded(child: Text(val, textAlign: TextAlign.right)),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
      ],
    );
  }

  String _pretty(dynamic v) {
    if (v == null) return '—';
    if (v is num || v is String || v is bool) return v.toString();
    if (v is List) return v.join(', ');
    if (v is Map) return v.map((k, val) => MapEntry(k.toString(), val)).toString();
    return v.toString();
  }
}

class _MetodoPagoView extends StatelessWidget {
  final String tipo;
  final Map<String, dynamic> args;

  const _MetodoPagoView({required this.tipo, required this.args});

  String _s(String k, [String d = '']) => (args[k]?.toString() ?? d);
  double _n(String k) {
    final v = args[k];
    if (v is num) return v.toDouble();
    if (v is String) {
      final t = v.replaceAll('\$', '').replaceAll('USD', '').replaceAll('Bs', '').replaceAll(',', '.').trim();
      return double.tryParse(t) ?? 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    switch (tipo) {
      case 'transferencia':
        children.addAll([
          _row('Banco', _s('banco', '—')),
          _row('Comercio', _s('comercio', '—')),
          _row('Fecha', _s('fecha', '—')),
          _row('Hora', _s('hora', '—')),
          _row('RIF', _s('rif', '—')),
          _row('Afiliado', _s('afiliado', '—')),
          if (_s('terminal').isNotEmpty) _row('Terminal', _s('terminal')),
          _row('Aprobación', _s('aprobacion', '—')),
          _row('Referencia', _s('referencia', '—')),
          _row('Monto pagado', _money(_n('monto'))),
        ]);
        break;

      case 'pdv':
        children.addAll([
          _row('Banco', _s('banco', '—')),
          _row('Recibo', 'Compra'),
          _row('Marca', _s('cardBrand', '—')),
          _row('Comercio', _s('comercio', '—')),
          _row('RIF', _s('rif', '—')),
          _row('Afiliado', _s('afiliado', '—')),
          _row('Terminal', _s('terminal', '—')),
          _row('Lote', _s('lote', '—')),
          _row('Fecha', _s('fecha', '—')),
          _row('Hora', _s('hora', '—')),
          _row('Aprobación', _s('aprobacion', '—')),
          _row('Referencia', _s('referencia', '—')),
          _row('Monto pagado', _money(_n('monto'))),
        ]);
        break;

      case 'efectivo':
        children.addAll([
          _row('Moneda', _s('moneda', '—')),
          _row('Comercio', _s('comercio', '—')),
          _row('RIF', _s('rif', '—')),
          _row('Fecha', _s('fecha', '—')),
          _row('Hora', _s('hora', '—')),
          _row('Aprobación', _s('aprobacion', '—')),
          _row('Referencia', _s('referencia', '—')),
          _row('Monto pagado', _money(_n('monto'))),
        ]);
        break;

      case 'access':
        children.addAll([
          _row('Banco', _s('banco', '—')),
          _row('Recibo', 'Compra'),
          _row('Empresa/Local', _s('empresa', '—')),
          _row('Dirección', _s('ubicacion', '—')),
          _row('RIF', _s('rif', '—')),
          _row('Afiliado', _s('afiliado', '—')),
          _row('Terminal', _s('terminal', '—')),
          _row('Lote', _s('lote', '—')),
          _row('Fecha', _s('fecha', '—')),
          _row('Hora', _s('hora', '—')),
          _row('Aprobación', _s('aprobacion', '—')),
          _row('Referencia', _s('referencia', '—')),
          _row('Trace', _s('trace', '—')),
          _row('Monto pagado', _money(_n('monto'))),
        ]);
        break;

      case 'comodato':
        children.addAll([
          _row('Fecha', _s('fecha', '—')),
          _row('Hora', _s('hora', '—')),
          _row('Referencia', _s('referencia', '—')),
          _row('Monto cargado a deuda', _money(_n('monto'))),
        ]);
        break;

      default:
        children.add(const Text('Método no identificado.'));
    }

    return Column(children: children);
  }

  Widget _row(String l, String r) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(l)),
        Expanded(child: Text(r, textAlign: TextAlign.right)),
      ],
    ),
  );

  String _money(double v) => '\$${v.toStringAsFixed(2)}';
}

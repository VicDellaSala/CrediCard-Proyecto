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
  String? _lineaId;
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

  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _args = (ModalRoute.of(context)?.settings.arguments as Map?)?.cast<String, dynamic>() ?? {};

// Datos comunes de la venta (pueden venir desde varias pantallas)
    _rif = (_args['rif'] ?? '').toString();
    _lineaId = _args['lineaId']?.toString();
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
    _cargarContextoVentaFallback(); // ⬅️ completa modelo/seriales/precios si faltan
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

// ⬇️ Si los args no traen modelo/serial/precios, intenta tomarlos del último pagos_pdv del RIF
  Future<void> _cargarContextoVentaFallback() async {
    final needsModelo = (_modeloSeleccionado == null || _modeloSeleccionado!.trim().isEmpty);
    final needsSerialEq = (_serialEquipo == null || _serialEquipo!.trim().isEmpty);
    final needsSerialSim = (_serialSim == null || _serialSim!.trim().isEmpty);
    final needsPos = (_posPriceStr == null || _posPriceStr!.toString().trim().isEmpty);
    final needsPlan = (_planPriceStr == null || _planPriceStr!.toString().trim().isEmpty) || (_planTitle == null || _planTitle!.trim().isEmpty);
    final needsLinea = (_lineaName == null || _lineaName!.trim().isEmpty);
    final needsLineaId = (_lineaId == null || _lineaId!.trim().isEmpty);

    if (!(needsModelo || needsSerialEq || needsSerialSim || needsPos || needsPlan || needsLinea || needsLineaId)) return;
    if (_rif.isEmpty) return;

    try {
      final q = await FirebaseFirestore.instance
          .collection('pagos_pdv')
          .where('rif', isEqualTo: _rif)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (q.docs.isEmpty) return;
      final d = q.docs.first.data();

      if (!mounted) return;
      setState(() {
        _modeloSeleccionado = needsModelo ? (d['modeloSeleccionado']?.toString() ?? _modeloSeleccionado) : _modeloSeleccionado;
        _serialEquipo = needsSerialEq ? (d['serialEquipo']?.toString() ?? _serialEquipo) : _serialEquipo;
        _serialSim = needsSerialSim ? (d['serialSim']?.toString() ?? _serialSim) : _serialSim;
        _posPriceStr = needsPos ? (d['posPrice']?.toString() ?? _posPriceStr) : _posPriceStr;
        _planTitle = needsPlan ? (d['planTitle']?.toString() ?? _planTitle) : _planTitle;
        _planPriceStr = needsPlan ? (d['planPrice']?.toString() ?? _planPriceStr) : _planPriceStr;
        _lineaName = needsLinea ? (d['lineaName']?.toString() ?? _lineaName) : _lineaName;
        _lineaId = needsLineaId ? (d['lineaId']?.toString() ?? _lineaId) : _lineaId;
      });
    } catch (_) {/* silencio */}
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

// Equipo POS
                              const Text('Equipo (POS)', style: TextStyle(fontWeight: FontWeight.w700)),
                              _bul('Modelo', _modeloSeleccionado),
                              _bul('Serial equipo', _serialEquipo),
                              _bul('Serial SIM', _serialSim),
                              _bul('Precio POS', _money(_toDouble(_posPriceStr))),
                              const SizedBox(height: 10),

// Tarjeta operativa
                              const Text('Tarjeta operativa', style: TextStyle(fontWeight: FontWeight.w700)),
                              _bul('Operadora', _lineaName),
                              _bul('Plan', _planTitle),
                              _bul('Precio plan', _money(_toDouble(_planPriceStr))),
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
                                  onPressed: _saving ? null : _verComprobante,
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
                                  onPressed: _saving ? null : _guardarYTerminar,
                                  icon: _saving
                                      ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                      : const Icon(Icons.save_alt),
                                  label: Text(_saving ? 'Guardando...' : 'Guardar y terminar'),
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
    Navigator.pushNamed(context, '/ventas/datos-finales', arguments: _args);
  }

// ======================= GUARDAR TODO =======================
  Future<void> _guardarYTerminar() async {
    setState(() => _saving = true);
    try {
      final db = FirebaseFirestore.instance;

// 1) Tomamos snapshot de la deuda actual del cliente para guardarla junto a la relación
      double deudaActual = 0;
      String? clienteDocId;
      if (_rif.isNotEmpty) {
        final cq = await db
            .collection('Cliente_completo')
            .where('rif_lower', isEqualTo: _rif.toLowerCase())
            .limit(1)
            .get();
        if (cq.docs.isNotEmpty) {
          final d = cq.docs.first.data();
          clienteDocId = cq.docs.first.id;
          deudaActual = _toDouble(d['deuda']);
        }
      }

// 2) Preparamos payload completo para Cliente_Terminal
      final payload = <String, dynamic>{
// vínculo cliente
        'rif': _rif,
        'rif_lower': _rif.toLowerCase(),
        'clienteRef': clienteDocId,
        'clienteSnapshot': _clienteDoc?.data() ?? {},

// contexto de venta
        'tipo': _tipo, // pdv/efectivo/transferencia/access/comodato
        'args': _args, // guardamos TODO lo que llegó, por si hace falta auditar
        'lineaId': _lineaId,
        'lineaName': _lineaName,
        'planTitle': _planTitle,
        'planDesc': _planDesc,
        'planPrice': _planPriceStr,
        'modeloSeleccionado': _modeloSeleccionado,
        'posPrice': _posPriceStr,
        'total': _totalStr,

// seriales seleccionados
        'serialEquipo': _serialEquipo,
        'serialSim': _serialSim,

// estado financiero al momento de cierre
        'deuda_actual': deudaActual,

// marcas de tiempo
        'createdAt': FieldValue.serverTimestamp(),
      };

// 3) Creamos documento en Cliente_Terminal
      final docRef = await db.collection('Cliente_Terminal').add(payload);

// 4) Eliminamos serie del equipo en almacén (si procede)
      final removed = <String, dynamic>{};
      if ((_serialEquipo ?? '').trim().isNotEmpty && (_modeloSeleccionado ?? '').trim().isNotEmpty) {
        final ok = await _findAndDeleteEquipo(
          db: db,
          modeloId: _modeloSeleccionado!.trim().toLowerCase(),
          serial: _serialEquipo!.trim(),
        );
        removed['equipo_serial_removed'] = ok ? _serialEquipo : null;
      }

// 5) Eliminamos SIM/tarjeta de su almacén (si procede)
      if ((_serialSim ?? '').trim().isNotEmpty && (_lineaId ?? '').trim().isNotEmpty) {
        final ok = await _findAndDeleteSim(
          db: db,
          lineaId: _lineaId!.trim().toLowerCase(),
          serial: _serialSim!.trim(),
        );
        removed['sim_serial_removed'] = ok ? _serialSim : null;
      }

// 6) Guardamos en el mismo doc qué seriales se removieron efectivamente
      if (removed.isNotEmpty) {
        await docRef.update({'removed': removed});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Guardado correctamente en Cliente_Terminal.')),
      );

// Aquí NO tocamos la deuda del cliente (ya fue ajustada en cada flujo de pago).
// Solo almacenamos "deuda_actual" para referencia. Si quieres forzar sync, dímelo y lo añadimos.

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Elimina 1 documento en /almacen_pdv/{modeloId}/equipos con field serial == X
  Future<bool> _findAndDeleteEquipo({
    required FirebaseFirestore db,
    required String modeloId,
    required String serial,
  }) async {
    try {
      final q = await db
          .collection('almacen_pdv')
          .doc(modeloId)
          .collection('equipos')
          .where('serial', isEqualTo: serial)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return false;
      await q.docs.first.reference.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Elimina 1 documento en /almacen_tarjetas/{lineaId}/tarjetas con field serial == X
  Future<bool> _findAndDeleteSim({
    required FirebaseFirestore db,
    required String lineaId,
    required String serial,
  }) async {
    try {
      final q = await db
          .collection('almacen_tarjetas')
          .doc(lineaId)
          .collection('tarjetas')
          .where('serial', isEqualTo: serial)
          .limit(1)
          .get();
      if (q.docs.isEmpty) return false;
      await q.docs.first.reference.delete();
      return true;
    } catch (_) {
      return false;
    }
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
// Mapa de etiquetas amigables (ocultamos *_lower, created_by, updated_at)
    final hidden = {'created_by','updated_at'};
    final entries = data.entries.where((e) {
      final k = e.key.toString();
      return !k.endsWith('_lower') && !hidden.contains(k);
    }).toList()
      ..sort((a, b) => a.key.toString().compareTo(b.key.toString()));

    String label(String k) {
      switch (k) {
        case 'address': return 'Dirección';
        case 'afiliacion_numero': return 'Número de afiliación';
        case 'afiliado': return 'Afiliado';
        case 'bank': return 'Banco';
        case 'created_at': return 'Creado el';
        case 'email': return 'Email';
        case 'first_name': return 'Nombre';
        case 'last_name': return 'Apellido';
        case 'full_name': return 'Nombre completo';
        case 'phone_1': return 'Teléfono 1';
        case 'phone_2': return 'Teléfono 2';
        case 'rif': return 'RIF';
        case 'deuda': return 'Deuda';
        default: return k;
      }
    }

    String pretty(dynamic v, String k) {
      if (k == 'created_at' && v is Timestamp) {
        final d = v.toDate();
        String two(int x) => x.toString().padLeft(2, '0');
        return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
      }
      return v?.toString() ?? '—';
    }

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text('RIF: ${rif.isEmpty ? '—' : rif}'),
      subtitle: const Text('Toca para ver todos los datos del cliente'),
      children: [
        const SizedBox(height: 6),
        ...entries.map((e) {
          final key = e.key.toString();
          final val = pretty(e.value, key);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(child: Text(label(key))),
                Expanded(child: Text(val, textAlign: TextAlign.right)),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
      ],
    );
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

  String _prettyMetodo() {
    switch (tipo) {
      case 'pdv': return 'Punto de Venta';
      case 'efectivo': return 'Efectivo';
      case 'transferencia': return 'Transferencia bancaria';
      case 'access': return 'Access Commerce';
      case 'comodato': return 'Comodato';
      default: return 'No identificado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
// ⬇️ encabezado con el tipo de pago
      _row('Pagó con', _prettyMetodo()),
    ];

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

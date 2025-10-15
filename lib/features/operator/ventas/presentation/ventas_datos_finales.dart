import 'package:flutter/material.dart';

/// Pantalla de “Factura / Datos finales”
///
/// Navega aquí con:
/// Navigator.pushNamed(
/// context,
/// '/ventas/datos-finales',
/// arguments: {
/// 'tipo': 'transferencia' | 'pdv' | 'efectivo' | 'access',
/// // ---- CAMPOS TRANSFERENCIA ----
/// // 'monto', 'comercio', 'fecha', 'hora', 'rif',
/// // 'afiliado', 'aprobacion', 'referencia',
/// // (opcional) 'terminal'
///
/// // ---- CAMPOS PDV ----
/// // 'banco', 'cardBrand' ('Mastercard'|'Visa'),
/// // 'comercio', 'rif', 'afiliado',
/// // 'terminal', 'lote', 'fecha', 'hora',
/// // 'aprobacion', 'referencia', 'monto'
///
/// // ---- CAMPOS EFECTIVO ----
/// // 'moneda' ('Bs'|'USD'), 'monto', 'comercio',
/// // 'rif', 'fecha', 'hora', 'aprobacion', 'referencia'
///
/// // ---- CAMPOS ACCESS ----
/// // 'banco', 'comercio', 'direccion',
/// // 'rif', 'afiliado', 'terminal', 'lote',
/// // 'fecha', 'hora', 'aprobacion', 'referencia',
/// // 'trace', 'monto'
/// },
/// );
class VentasDatosFinalesScreen extends StatelessWidget {
  const VentasDatosFinalesScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments ?? {}) as Map;

    String s(String k, [String d = '']) => (args[k]?.toString() ?? d);
    double n(String k) {
      final v = args[k];
      if (v is num) return v.toDouble();
      if (v is String) {
        final t = v.replaceAll('\$', '').replaceAll('USD', '').replaceAll('Bs', '').replaceAll(',', '.').trim();
        return double.tryParse(t) ?? 0;
      }
      return 0;
    }

    final tipo = s('tipo').toLowerCase();

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
                  Text(
                    _tituloPorTipo(tipo),
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 750),
                    child: _FacturaPorTipo(
                      tipo: tipo,
                      getS: s,
                      getN: n,
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

  static String _tituloPorTipo(String tipo) {
    switch (tipo) {
      case 'transferencia':
        return 'Comprobante · Transferencia';
      case 'pdv':
        return 'Comprobante · Punto de Venta';
      case 'efectivo':
        return 'Comprobante · Efectivo en tienda';
      case 'access':
        return 'Comprobante · Access Commerce';
      default:
        return 'Comprobante';
    }
  }
}

class _FacturaPorTipo extends StatelessWidget {
  final String tipo;
  final String Function(String key, [String def]) getS;
  final double Function(String key) getN;

  const _FacturaPorTipo({
    required this.tipo,
    required this.getS,
    required this.getN,
  });

  @override
  Widget build(BuildContext context) {
    switch (tipo) {
      case 'transferencia':
        return _FacturaTransferencia(getS: getS, getN: getN);
      case 'pdv':
        return _FacturaPDV(getS: getS, getN: getN);
      case 'efectivo':
        return _FacturaEfectivo(getS: getS, getN: getN);
      case 'access':
        return _FacturaAccess(getS: getS, getN: getN);
      default:
        return _Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Text('Tipo desconocido: $tipo'),
          ),
        );
    }
  }
}

/// ===================== TRANSFERENCIA =====================
class _FacturaTransferencia extends StatelessWidget {
  final String Function(String, [String]) getS;
  final double Function(String) getN;

  const _FacturaTransferencia({required this.getS, required this.getN});

  @override
  Widget build(BuildContext context) {
    final monto = getN('monto');
    final comercio = getS('comercio', '—');
    final fecha = getS('fecha', '—');
    final hora = getS('hora', '—');
    final rif = getS('rif', '—');
    final afiliado = getS('afiliado', '—');
    final terminal = getS('terminal', '—'); // puede venir vacío/ausente
    final aprob = getS('aprobacion', '—');
    final ref = getS('referencia', '—');

    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 44),
            const SizedBox(height: 10),
            Text(
              _money(monto, prefix: 'Bs. '),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF0E2F6F)),
            ),
            const SizedBox(height: 2),
            const Text('Pago completado', style: TextStyle(color: Colors.black54)),

            const SizedBox(height: 16),
            _row2('Comercio', comercio),
            _row2('Fecha', fecha),
            _row2('Hora', hora),
            _row2('RIF', rif),
            _row2('Afiliado', afiliado),
            if (terminal.trim().isNotEmpty) _row2('Terminal', terminal),
            _row2('Aprob', aprob),

            const SizedBox(height: 18),
            Text(
              'Referencia: $ref',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Color(0xFFE67E22),
                fontSize: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== PDV =====================
class _FacturaPDV extends StatelessWidget {
  final String Function(String, [String]) getS;
  final double Function(String) getN;

  const _FacturaPDV({required this.getS, required this.getN});

  @override
  Widget build(BuildContext context) {
    final banco = getS('banco', '—');
    final brand = getS('cardBrand', '—').toUpperCase(); // MASTERCARD / VISA
    final comercio = getS('comercio', '—');
    final rif = getS('rif', '—');
    final afiliado = getS('afiliado', '—');
    final terminal = getS('terminal', '—');
    final lote = getS('lote', '—');
    final fecha = getS('fecha', '—');
    final hora = getS('hora', '—');
    final aprob = getS('aprobacion', '—');
    final ref = getS('referencia', '—');
    final monto = getN('monto');

    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
// Encabezado centrado
            Text(
              banco,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text('RECIBO DE COMPRA', textAlign: TextAlign.center),
            Text(brand, textAlign: TextAlign.center),

            const SizedBox(height: 14),
// Comercio / RIF / Afiliado
            Text(comercio, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: Text('RIF: $rif')),
                Expanded(child: Text('AFILIADO: $afiliado', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('TERMINAL: $terminal')),
                Expanded(child: Text('LOTE: $lote', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('FECHA: $fecha')),
                Expanded(child: Text('HORA: $hora', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('APROB: $aprob')),
                Expanded(child: Text('REF: $ref', textAlign: TextAlign.right)),
              ],
            ),
            const SizedBox(height: 8),
            Text('MONTO ${_money(monto, prefix: 'Bs. ')}', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            const Text('APROBADO', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

/// ===================== EFECTIVO =====================
class _FacturaEfectivo extends StatelessWidget {
  final String Function(String, [String]) getS;
  final double Function(String) getN;

  const _FacturaEfectivo({required this.getS, required this.getN});

  @override
  Widget build(BuildContext context) {
    final moneda = getS('moneda', 'Bs');
    final monto = getN('monto');
    final comercio = getS('comercio', '—');
    final rif = getS('rif', '—');
    final fecha = getS('fecha', '—');
    final hora = getS('hora', '—');
    final aprob = getS('aprobacion', '—');
    final ref = getS('referencia', '—');

    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 36),
            const SizedBox(height: 8),
            Text(
              _money(monto, prefix: '$moneda '),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            _row2('Comercio', comercio),
            _row2('RIF', rif),
            _row2('Fecha', fecha),
            _row2('Hora', hora),
            _row2('Aprobación', aprob),
            const SizedBox(height: 8),
            Text(
              'Referencia: $ref',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFFE67E22)),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===================== ACCESS COMMERCE =====================
class _FacturaAccess extends StatelessWidget {
  final String Function(String, [String]) getS;
  final double Function(String) getN;

  const _FacturaAccess({required this.getS, required this.getN});

  @override
  Widget build(BuildContext context) {
    final banco = getS('banco', '—');
    final comercio = getS('comercio', '—');
    final direccion = getS('direccion', '—');
    final rif = getS('rif', '—');
    final afiliado = getS('afiliado', '—');
    final terminal = getS('terminal', '—');
    final lote = getS('lote', '—');
    final fecha = getS('fecha', '—');
    final hora = getS('hora', '—');
    final aprob = getS('aprobacion', '—');
    final ref = getS('referencia', '—');
    final trace = getS('trace', '—');
    final monto = getN('monto');

    return _Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(banco, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 4),
            const Text('RECIBO DE COMPRA', textAlign: TextAlign.center),

            const SizedBox(height: 12),
            Text(comercio, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(direccion),

            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: Text('RIF: $rif')),
                Expanded(child: Text('AFILIADO: $afiliado', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('TERMINAL: $terminal')),
                Expanded(child: Text('LOTE: $lote', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('FECHA: $fecha')),
                Expanded(child: Text('HORA: $hora', textAlign: TextAlign.right)),
              ],
            ),
            Row(
              children: [
                Expanded(child: Text('APROB: $aprob')),
                Expanded(child: Text('REF: $ref', textAlign: TextAlign.right)),
              ],
            ),
            Text('TRACE: $trace'),
            const SizedBox(height: 8),
            Text('Monto: ${_money(monto, prefix: 'Bs. ')}', style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// ---------- Widgets de apoyo ----------
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: child,
    );
  }
}

Widget _row2(String l, String r) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(l)),
        Expanded(child: Text(r, textAlign: TextAlign.right)),
      ],
    ),
  );
}

String _money(double v, {String prefix = ''}) {
  return '$prefix${v.toStringAsFixed(2)}';
}

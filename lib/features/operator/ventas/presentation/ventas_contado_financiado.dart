import 'package:flutter/material.dart';

class VentasContadoFinanciadoScreen extends StatefulWidget {
  const VentasContadoFinanciadoScreen({super.key});

  @override
  State<VentasContadoFinanciadoScreen> createState() =>
      _VentasContadoFinanciadoScreenState();
}

class _VentasContadoFinanciadoScreenState
    extends State<VentasContadoFinanciadoScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  bool _loaded = false;

// Datos que llegan por arguments desde /ventas/registro-serial
  String _rif = '';
  String _lineaId = '';
  String _lineaName = '';
  int _planIndex = 0;
  String _planTitle = '';
  String _planDesc = '';
  String _planPriceStr = '0';
  String? _modelo;
  String? _serialEquipo;
  String? _serialSim;
  String _posPriceStr = '0';

  double get _planPrice => _asDouble(_planPriceStr);
  double get _posPrice => _asDouble(_posPriceStr);
  double get _total => _planPrice + _posPrice;

// --- lee arguments en didChangeDependencies (NO en initState) ---
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;

    final args =
    ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    _rif = (args?['rif'] ?? '').toString();
    _lineaId = (args?['lineaId'] ?? '').toString();
    _lineaName = (args?['lineaName'] ?? '').toString();

    _planIndex = _tryParseInt(args?['planIndex']) ?? 0;
    _planTitle = (args?['planTitle'] ?? '').toString();
    _planDesc = (args?['planDesc'] ?? '').toString();
    _planPriceStr = (args?['planPrice'] ?? '0').toString();

    _modelo = (args?['modeloSeleccionado'])?.toString();
    _serialEquipo = (args?['serialEquipo'])?.toString();
    _serialSim = (args?['serialSim'])?.toString();
    _posPriceStr = (args?['posPrice'] ?? '0').toString();

    _loaded = true;
// no necesito setState aquí; pero si quieres que reactive el build inicial:
    setState(() {});
  }

// Helpers de parseo robusto
  static int? _tryParseInt(dynamic v) {
    if (v is int) return v;
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double _asDouble(String raw) {
// Quita $ y espacios, cambia coma por punto, luego parsea
    final cleaned = raw
        .replaceAll('\$', '')
        .replaceAll('USD', '')
        .replaceAll('Bs', '')
        .replaceAll(',', '.')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

// ===== Navegaciones (mismos argumentos en todos) =====
  Map<String, dynamic> _buildArgs() => {
    'rif': _rif,
    'lineaId': _lineaId,
    'lineaName': _lineaName,
    'planIndex': _planIndex,
    'planTitle': _planTitle,
    'planDesc': _planDesc,
    'planPrice': _planPrice.toStringAsFixed(2),
    'modeloSeleccionado': _modelo,
    'posPrice': _posPrice.toStringAsFixed(2),
    'total': _total.toStringAsFixed(2),
    'serialEquipo': _serialEquipo,
    'serialSim': _serialSim,
  };

  void _goTransferencia() {
    Navigator.pushNamed(
      context,
      '/ventas/pago/transferencia', // ⬅️ ruta que ya usas en main
      arguments: _buildArgs(),
    );
  }

  void _goPuntoDeVenta() {
    Navigator.pushNamed(
      context,
      '/ventas/pago/pdv', // ⬅️ tu ruta de pago por PDV
      arguments: _buildArgs(),
    );
  }

  void _goEfectivo() {
    Navigator.pushNamed(
      context,
      '/ventas/pago/efectivo', // ⬅️ ahora navega a efectivo
      arguments: _buildArgs(),
    );
  }

  void _goAccessComerce() {
    Navigator.pushNamed(
      context,
      '/ventas/pago/access-comerce', // ⬅️ nuevo flujo
      arguments: _buildArgs(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header celestito
            Container(
              decoration: BoxDecoration(
                color: _panelColor,
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
                    'Contado / Financiado',
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
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
// Resumen
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.receipt_long, color: Colors.black54),
                                SizedBox(width: 8),
                                Text(
                                  'Resumen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text('Cliente (RIF): ${_rif.isEmpty ? '—' : _rif}'),
                            Text('Operadora: ${_lineaName.isEmpty ? '—' : _lineaName}'),
                            const SizedBox(height: 12),
                            const Text(
                              'Plan seleccionado:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text('• Plan ${_planIndex}: $_planTitle'),
                            Text(_planDesc),
                            Text('Precio plan: \$${_planPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 12),
                            const Text(
                              'Modelo de POS:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            Text('• ${_modelo ?? '—'}'),
                            Text('Precio POS: \$${_posPrice.toStringAsFixed(2)}'),
                            const SizedBox(height: 12),
                            Text(
                              'TOTAL: \$${_total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

// Botones (se mantienen, añadimos Access/Comerce y Efectivo navega)
                      _bigActionButton(
                        icon: Icons.account_balance_outlined,
                        label: 'Transferencia Bancaria',
                        onPressed: _goTransferencia,
                      ),
                      const SizedBox(height: 12),
                      _bigActionButton(
                        icon: Icons.point_of_sale_outlined,
                        label: 'Punto de Venta',
                        onPressed: _goPuntoDeVenta,
                      ),
                      const SizedBox(height: 12),
                      _bigActionButton(
                        icon: Icons.payments_outlined,
                        label: 'Efectivo en Tienda',
                        onPressed: _goEfectivo,
                      ),
                      const SizedBox(height: 12),
                      _bigActionButton(
                        icon: Icons.link_outlined,
                        label: 'Access / Comerce',
                        onPressed: _goAccessComerce,
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

  Widget _bigActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}

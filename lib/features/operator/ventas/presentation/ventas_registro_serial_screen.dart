import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla: Registro de serial (equipo y SIM)
/// Navega a /ventas/plan cuando ambos seriales se seleccionan.
class VentasRegistroSerialScreen extends StatefulWidget {
  const VentasRegistroSerialScreen({
    super.key,
    required this.rif,
    required this.lineaId,
    required this.lineaName,
    required this.planIndex,
    required this.planTitle,
    required this.planDesc,
    required this.planPrice,
    this.modeloSeleccionado,
  });

  final String rif;

  /// Operadora seleccionada (id: 'digitel' | 'movistar' | 'publica')
  final String lineaId;
  final String lineaName;

  /// Plan elegido (índice visible 1..3, y detalles)
  final int planIndex;
  final String planTitle;
  final String planDesc;
  final String planPrice;

  /// Modelo de POS seleccionado en la pantalla anterior (p. ej. "Castlle")
  final String? modeloSeleccionado;

  @override
  State<VentasRegistroSerialScreen> createState() =>
      _VentasRegistroSerialScreenState();
}

class _VentasRegistroSerialScreenState extends State<VentasRegistroSerialScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  String? _selectedSerialEquipo;
  String? _selectedSerialSim;

  /// Precio del modelo POS (leído de almacen_pdv/{modeloId}.precio)
  double? _modeloPrecio;

  @override
  void initState() {
    super.initState();
    _preloadModeloPrecio(); // solo añade la lectura del precio
  }

  Future<void> _preloadModeloPrecio() async {
    final modeloId = (widget.modeloSeleccionado ?? '').trim().toLowerCase();
    if (modeloId.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('almacen_pdv')
          .doc(modeloId)
          .get();

      final data = doc.data();
      if (data != null) {
        final p = data['precio'];
        double? value;
        if (p is num) value = p.toDouble();
        if (p is String) value = double.tryParse(p.replaceAll(',', '.'));
        if (mounted) setState(() => _modeloPrecio = value);
      }
    } catch (_) {
// silencioso: si no hay precio, se mostrará 0 en la siguiente pantalla
    }
  }

  /// Referencias de colecciones
  CollectionReference<Map<String, dynamic>> get _equiposRef {
    final modeloId = (widget.modeloSeleccionado ?? '').trim().toLowerCase();
    return FirebaseFirestore.instance
        .collection('almacen_pdv')
        .doc(modeloId)
        .collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> get _simsRef {
    final lineaId = widget.lineaId.trim().toLowerCase();
    return FirebaseFirestore.instance
        .collection('almacen_tarjetas')
        .doc(lineaId)
        .collection('tarjetas');
  }

  void _confirmar() {
    final equipo = _selectedSerialEquipo?.trim();
    final sim = _selectedSerialSim?.trim();

    if (equipo == null || equipo.isEmpty || sim == null || sim.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes seleccionar el serial del equipo y el serial de la SIM'),
      ));
      return;
    }

// Convertimos planPrice y posPrice a String (mantengo tu convención de String)
    final posPriceStr = (_modeloPrecio ?? 0).toString();

    Navigator.pushNamed(
      context,
      '/ventas/plan',
      arguments: {
        'rif': widget.rif, // si llega vacío, la siguiente pantalla puede resolverlo
        'lineaId': widget.lineaId,
        'lineaName': widget.lineaName,
        'planIndex': widget.planIndex,
        'planTitle': widget.planTitle,
        'planDesc': widget.planDesc,
        'planPrice': widget.planPrice,
        'modeloSeleccionado': widget.modeloSeleccionado,
        'serialEquipo': equipo,
        'serialSim': sim,
        'posPrice': posPriceStr, // <<< añadido
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final modelo = widget.modeloSeleccionado ?? '—';

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header
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
                    'Registro de serial',
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: [
                      _infoCard(
                        icon: Icons.badge_outlined,
                        title: 'Cliente (RIF)',
                        child: Text(widget.rif.isNotEmpty ? widget.rif : '—'),
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.hub_outlined,
                        title: 'Operadora',
                        child: Text('${widget.lineaName} (id: ${widget.lineaId})'),
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.assignment_outlined,
                        title: 'Plan seleccionado',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Plan ${widget.planIndex}: ${widget.planTitle}',
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text(widget.planDesc),
                            const SizedBox(height: 4),
                            Text('Precio: ${widget.planPrice}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.devices_other_outlined,
                        title: 'Modelo de POS',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(modelo),
                            if (_modeloPrecio != null) ...[
                              const SizedBox(height: 4),
                              Text('Precio POS: ${_modeloPrecio!.toStringAsFixed(2)}'),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

// Selector de serial del EQUIPO
                      _selectorCard(
                        icon: Icons.qr_code_2_outlined,
                        title: 'Selecciona serial del equipo',
                        hint: 'Serial del equipo',
                        stream: _equiposRef.orderBy('serial').snapshots(),
                        currentValue: _selectedSerialEquipo,
                        onChanged: (v) => setState(() {
                          _selectedSerialEquipo = v;
                        }),
                      ),

                      const SizedBox(height: 12),

// Selector de serial de la SIM
                      _selectorCard(
                        icon: Icons.sim_card_outlined,
                        title: 'Selecciona serial de la tarjeta (SIM)',
                        hint: 'Serial de la SIM',
                        stream: _simsRef.orderBy('serial').snapshots(),
                        currentValue: _selectedSerialSim,
                        onChanged: (v) => setState(() {
                          _selectedSerialSim = v;
                        }),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _confirmar,
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Confirmar'),
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

  /// Tarjeta de información simple
  Widget _infoCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con Dropdown que se alimenta de un Stream de Firestore
  Widget _selectorCard({
    required IconData icon,
    required String title,
    required String hint,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required String? currentValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          Row(
            children: [
              Icon(icon, color: Colors.black54),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: stream,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Text('Error: ${snap.error}');
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Text('No hay seriales disponibles.');
              }
              final items = docs
                  .map((d) => (d.data()['serial'] ?? '').toString())
                  .where((s) => s.isNotEmpty)
                  .toList();

              return DropdownButtonFormField<String>(
                value: currentValue != null && items.contains(currentValue)
                    ? currentValue
                    : null,
                items: items
                    .map((s) => DropdownMenuItem(
                  value: s,
                  child: Text(s),
                ))
                    .toList(),
                onChanged: onChanged,
                decoration: const InputDecoration(
                  hintText: 'Selecciona…',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

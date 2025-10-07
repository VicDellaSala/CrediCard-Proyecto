import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VentasRegistroSerialScreen extends StatefulWidget {
// ---- Parámetros que ya estabas enviando ----
  final String rif;
  final String lineaId; // ej: 'digitel' | 'movistar' | 'publica'
  final String lineaName; // ej: 'Digitel'
  final int planIndex; // 0,1,2
  final String planTitle;
  final String planDesc;
  final String planPrice;
  final String? modeloSeleccionado; // ej: 'Castlle' | 'Unidigital'

  const VentasRegistroSerialScreen({
    Key? key,
    required this.rif,
    required this.lineaId,
    required this.lineaName,
    required this.planIndex,
    required this.planTitle,
    required this.planDesc,
    required this.planPrice,
    this.modeloSeleccionado,
  }) : super(key: key);

  @override
  State<VentasRegistroSerialScreen> createState() =>
      _VentasRegistroSerialScreenState();
}

class _VentasRegistroSerialScreenState extends State<VentasRegistroSerialScreen> {
  static const _panelColor = Color(0xFFAED6D8);

// Selecciones
  String? _serialEquipoLower; // valor interno (doc id)
  String? _serialEquipoShow; // cómo se muestra (AA999)

  String? _serialSimLower; // valor interno (doc id)
  String? _serialSimShow; // cómo se muestra (AA99)

// Refs a Firestore (se construyen on demand)
  CollectionReference<Map<String, dynamic>> _equiposRef() {
// modeloId: usamos el nombre del modelo en minúsculas y sin espacios típicos
    final modeloId = (widget.modeloSeleccionado ?? '').trim().toLowerCase();
// Si el modelo es vacío, esto devolverá algo inválido, pero el UI muestra "No especificado".
    return FirebaseFirestore.instance
        .collection('almacen_pdv')
        .doc(modeloId)
        .collection('equipos');
  }

  CollectionReference<Map<String, dynamic>> _tarjetasRef() {
    return FirebaseFirestore.instance
        .collection('almacen_tarjetas')
        .doc(widget.lineaId.trim().toLowerCase())
        .collection('tarjetas');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            _header(),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _infoCard(
                        icon: Icons.badge,
                        title: 'Cliente (RIF)',
                        value: widget.rif,
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.network_cell,
                        title: 'Operadora',
                        value: '${widget.lineaName} (id: ${widget.lineaId})',
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.list_alt,
                        title: 'Plan seleccionado',
                        value:
                        'Plan ${widget.planIndex + 1}: ${widget.planTitle}\n'
                            '${widget.planDesc}\nPrecio: ${widget.planPrice}',
                      ),
                      const SizedBox(height: 10),
                      _infoCard(
                        icon: Icons.point_of_sale,
                        title: 'Modelo de POS',
                        value: widget.modeloSeleccionado ?? 'No especificado',
                      ),
                      const SizedBox(height: 18),

// ------- Selector de SERIAL DE EQUIPO (POS) -------
                      _selectorEquipos(),

                      const SizedBox(height: 16),

// ------- Selector de SERIAL DE TARJETA (SIM) -------
                      _selectorTarjetas(),

                      const SizedBox(height: 28),

                      SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _onConfirmar,
                          icon: const Icon(Icons.check_circle),
                          label: const Text('Confirmar selección'),
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Debes seleccionar el serial del equipo y el serial de la tarjeta.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 28),
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

// ---------------------------- UI helpers ----------------------------

  Widget _header() {
    return Container(
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
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14),
                children: [
                  TextSpan(
                    text: '$title\n',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

// ----------------------- Selectores (Stream) -----------------------

  Widget _selectorEquipos() {
    final modeloOk = (widget.modeloSeleccionado ?? '').trim().isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Serial del equipo (POS)',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (!modeloOk)
            const Text(
              'Selecciona primero un modelo de POS en la pantalla anterior.',
              style: TextStyle(color: Colors.redAccent),
            )
          else
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _equiposRef().snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  ));
                }
                if (snap.hasError) {
                  return Text('Error al cargar equipos: ${snap.error}');
                }
                final docs = snap.data?.docs ?? const [];
                if (docs.isEmpty) {
                  return const Text('No hay seriales registrados para este modelo.');
                }

// Ordenamos por 'serial_lower' o por 'serial'
                final items = docs
                    .map((d) {
                  final data = d.data();
                  final show = (data['serial'] ?? d.id).toString().toUpperCase();
                  final value = (data['serial_lower'] ?? d.id).toString();
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(show),
                  );
                })
                    .toList()
                  ..sort((a, b) => (a.child as Text).data!
                      .compareTo((b.child as Text).data!));

                return DropdownButtonFormField<String>(
                  value: _serialEquipoLower,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Selecciona el serial del equipo',
                  ),
                  items: items,
                  onChanged: (v) {
                    setState(() {
                      _serialEquipoLower = v;
                      _serialEquipoShow = items
                          .firstWhere((e) => e.value == v)
                          .child is Text
                          ? ((items.firstWhere((e) => e.value == v).child) as Text).data
                          : v;
                    });
                  },
                  validator: (v) =>
                  v == null ? 'Debes seleccionar un serial de equipo' : null,
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _selectorTarjetas() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Serial de la tarjeta (${widget.lineaName})',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _tarjetasRef().snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                ));
              }
              if (snap.hasError) {
                return Text('Error al cargar tarjetas: ${snap.error}');
              }
              final docs = snap.data?.docs ?? const [];
              if (docs.isEmpty) {
                return const Text('No hay seriales de tarjeta registrados para esta línea.');
              }

              final items = docs
                  .map((d) {
                final data = d.data();
                final show = (data['serial'] ?? d.id).toString().toUpperCase();
                final value = (data['serial_lower'] ?? d.id).toString();
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(show),
                );
              })
                  .toList()
                ..sort((a, b) => (a.child as Text).data!
                    .compareTo((b.child as Text).data!));

              return DropdownButtonFormField<String>(
                value: _serialSimLower,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Selecciona el serial de la tarjeta',
                ),
                items: items,
                onChanged: (v) {
                  setState(() {
                    _serialSimLower = v;
                    _serialSimShow = items
                        .firstWhere((e) => e.value == v)
                        .child is Text
                        ? ((items.firstWhere((e) => e.value == v).child) as Text).data
                        : v;
                  });
                },
                validator: (v) =>
                v == null ? 'Debes seleccionar un serial de tarjeta' : null,
              );
            },
          ),
        ],
      ),
    );
  }

// ------------------------------ Actions ----------------------------

  void _onConfirmar() {
// Validar que ambas selecciones estén hechas
    if (_serialEquipoLower == null || _serialSimLower == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Debes seleccionar el serial del equipo y el serial de la tarjeta.'),
        ),
      );
      return;
    }

// Navegar al siguiente paso (tu nueva pantalla de plan de pago)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VentasPlanDePagoScreen(
          rif: widget.rif,
          lineaId: widget.lineaId,
          lineaName: widget.lineaName,
          planIndex: widget.planIndex,
          planTitle: widget.planTitle,
          planDesc: widget.planDesc,
          planPrice: widget.planPrice,
          modeloSeleccionado: widget.modeloSeleccionado,
// Seriales elegidos:
          serialEquipoLower: _serialEquipoLower!,
          serialEquipo: _serialEquipoShow ?? _serialEquipoLower!,
          serialSimLower: _serialSimLower!,
          serialSim: _serialSimShow ?? _serialSimLower!,
        ),
      ),
    );
  }
}

/// -------------------------------------------------------------------
/// Placeholder mínimo para que compile si aún no pegaste tu archivo.
/// Reemplázalo con tu `ventas_plan_de_pago.dart`.
class VentasPlanDePagoScreen extends StatelessWidget {
  final String rif;
  final String lineaId;
  final String lineaName;
  final int planIndex;
  final String planTitle;
  final String planDesc;
  final String planPrice;
  final String? modeloSeleccionado;

  final String serialEquipoLower;
  final String serialEquipo;
  final String serialSimLower;
  final String serialSim;

  const VentasPlanDePagoScreen({
    super.key,
    required this.rif,
    required this.lineaId,
    required this.lineaName,
    required this.planIndex,
    required this.planTitle,
    required this.planDesc,
    required this.planPrice,
    required this.modeloSeleccionado,
    required this.serialEquipoLower,
    required this.serialEquipo,
    required this.serialSimLower,
    required this.serialSim,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan de pago')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'RIF: $rif\n'
              'Operadora: $lineaName ($lineaId)\n'
              'Plan: ${planIndex + 1} - $planTitle / $planPrice\n'
              'Modelo POS: ${modeloSeleccionado ?? "-"}\n'
              'Serial Equipo: $serialEquipo ($serialEquipoLower)\n'
              'Serial SIM: $serialSim ($serialSimLower)\n',
        ),
      ),
    );
  }
}

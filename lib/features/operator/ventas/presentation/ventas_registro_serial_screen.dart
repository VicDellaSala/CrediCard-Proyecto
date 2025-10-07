import 'package:flutter/material.dart';

class VentasRegistroSerialScreen extends StatefulWidget {
// ── Parámetros que envías desde VentasOperadorasScreen / main.dart ─────────
  final String rif;
  final String lineaId;
  final String lineaName;
  final int planIndex;
  final String planTitle;
  final String planDesc;
  final String planPrice;
  final String? modeloSeleccionado; // puede venir null si aún no se eligió

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

class _VentasRegistroSerialScreenState
    extends State<VentasRegistroSerialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serialCtrl = TextEditingController();

  @override
  void dispose() {
    _serialCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const panelColor = Color(0xFFAED6D8);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header
            Container(
              decoration: BoxDecoration(
                color: panelColor,
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

// Contenido
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoCard(
                        title: 'Cliente (RIF)',
                        value: widget.rif,
                        icon: Icons.badge,
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        title: 'Operadora',
                        value: '${widget.lineaName} (id: ${widget.lineaId})',
                        icon: Icons.network_cell,
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        title: 'Plan seleccionado',
                        value:
                        'Plan ${widget.planIndex + 1}: ${widget.planTitle}\n'
                            '${widget.planDesc}\nPrecio: ${widget.planPrice}',
                        icon: Icons.list_alt,
                      ),
                      const SizedBox(height: 10),
                      _InfoCard(
                        title: 'Modelo de POS',
                        value:
                        widget.modeloSeleccionado ?? 'No especificado aún',
                        icon: Icons.point_of_sale,
                      ),
                      const SizedBox(height: 18),

// Form serial
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'Introduce el serial del POS / SIM',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _serialCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Serial',
                                  hintText: 'Ej: UG767 o BU67',
                                  border: OutlineInputBorder(),
                                ),
                                textCapitalization: TextCapitalization.characters,
                                validator: (v) {
                                  final s = (v ?? '').trim().toUpperCase();
                                  if (s.isEmpty) return 'Ingresa un serial';
// Valida AA999 o AA99 (ambos patrones)
                                  final reg = RegExp(r'^[A-Z]{2}\d{2,3}$');
                                  if (!reg.hasMatch(s)) {
                                    return 'Formato inválido (AA99 o AA999)';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: _onConfirmar,
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text('Confirmar serial'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

// Placeholder para continuar flujo (guardar o siguiente paso)
                      Center(
                        child: Text(
                          'Aquí continuarías el flujo (guardar en Firestore / siguiente pantalla).',
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.65),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
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

  void _onConfirmar() {
    if (!_formKey.currentState!.validate()) return;

    final serial = _serialCtrl.text.trim().toUpperCase();

// Aquí puedes:
// 1) Guardar un “borrador” con todo lo seleccionado hasta ahora
// 2) O navegar al siguiente paso del flujo de ventas

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Serial "$serial" capturado para ${widget.lineaName} / ${widget.planTitle}.',
        ),
      ),
    );

// Ejemplo: regresar al stack anterior
// Navigator.pop(context, serial);
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
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
}

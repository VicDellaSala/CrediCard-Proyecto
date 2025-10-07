import 'package:flutter/material.dart';

class VentasChequeoScreen extends StatelessWidget {
  const VentasChequeoScreen({
    super.key,
    required this.rif,

// Datos del cliente / POS
    this.clienteNombre,
    this.modeloPos,
    this.serialPos,
    this.serialSim,

// Datos de la línea/plan
    this.lineaId,
    this.lineaName,
    this.planIndex,
    this.planTitle,
    this.planDesc,
    this.planPrice,

// Datos de la transferencia bancaria (si aplica)
    this.transferenciaId,
    this.transferenciaNumero,
    this.transferenciaMonto,
  });

// Requerido
  final String rif;

// Opcionales
  final String? clienteNombre;
  final String? modeloPos;
  final String? serialPos;
  final String? serialSim;

  final String? lineaId;
  final String? lineaName;
  final int? planIndex;
  final String? planTitle;
  final String? planDesc;
  final String? planPrice;

  final String? transferenciaId;
  final String? transferenciaNumero;
  final num? transferenciaMonto;

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Encabezado celeste
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
                    'Registro · Chequeo final',
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

// Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Column(
                    children: [
                      _InfoCard(
                        icon: Icons.badge_outlined,
                        title: 'Cliente',
                        lines: [
                          if (clienteNombre != null && clienteNombre!.trim().isNotEmpty)
                            'Nombre: $clienteNombre',
                          'RIF: $rif',
                        ],
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.settings_input_component_outlined,
                        title: 'Equipo POS',
                        lines: [
                          if (modeloPos != null) 'Modelo: $modeloPos',
                          if (serialPos != null) 'Serial del POS: $serialPos',
                        ],
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.sim_card_outlined,
                        title: 'Tarjeta / Operadora',
                        lines: [
                          if (lineaName != null && lineaId != null)
                            'Línea: $lineaName (id: $lineaId)',
                          if (serialSim != null) 'Serial SIM: $serialSim',
                        ],
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.assignment_turned_in_outlined,
                        title: 'Plan seleccionado',
                        lines: [
                          if (planIndex != null) 'Plan ${planIndex! + 1}${planIndex == 0 ? ' (obligatorio)' : ''}',
                          if (planTitle != null) 'Título: $planTitle',
                          if (planDesc != null) 'Descripción: $planDesc',
                          if (planPrice != null) 'Precio: $planPrice',
                        ],
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'Transferencia bancaria',
                        emptyText: 'No aplica / no registrada.',
                        lines: [
                          if (transferenciaId != null) 'Doc ID: $transferenciaId',
                          if (transferenciaNumero != null) 'N° transferencia: $transferenciaNumero',
                          if (transferenciaMonto != null) 'Monto: $transferenciaMonto',
                        ],
                      ),
                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Confirmar y continuar',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          onPressed: () {
// Aquí en el futuro puedes:
// - Guardar un “borrador de venta”
// - O disparar el flujo siguiente (facturación / envío / etc.)
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Venta en revisión. (Placeholder: aún no enviamos a Firestore final)'),
                              ),
                            );
                            Navigator.pop(context); // o navega a donde quieras continuar
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
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
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    this.lines = const [],
    this.emptyText,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final String? emptyText;

  @override
  Widget build(BuildContext context) {
    final hasData = lines.any((e) => e.trim().isNotEmpty);
    return Container(
      width: double.infinity,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 6),
                if (!hasData && emptyText != null)
                  Text(emptyText!, style: const TextStyle(color: Colors.black54))
                else
                  ...lines
                      .where((e) => e.trim().isNotEmpty)
                      .map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(e),
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

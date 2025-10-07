import 'package:flutter/material.dart';

/// Pantalla para elegir el tipo de plan de pago:
/// - Contado / Financiado -> '/ventas/plan/contado-financiado' (CORREGIDO)
/// - Comodato -> '/ventas/plan/comodato'
///
/// Si llegas aquí con información previa (rif, línea, plan, modelo, etc.),
/// puedes pasarlo vía `arguments` y lo reenviamos al navegar.
class VentasPlanDePagoScreen extends StatelessWidget {
  const VentasPlanDePagoScreen({super.key, this.arguments});

  final Map<String, dynamic>? arguments;

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
// Si desde "registro de serial" envías info, la recogemos y la
// reenviamos al siguiente paso para mantener el flujo:
    final args = arguments ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {});

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
                  const Row(
                    children: [
                      Icon(Icons.payments, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Seleccionar plan de pago',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
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
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
// Tarjeta: Contado / Financiado (RUTA CORREGIDA)
                        _PlanCard(
                          title: 'Contado / Financiado',
                          desc:
                          'Elige esta opción si el cliente pagará al contado o si deseas configurar un plan de financiamiento.',
                          icon: Icons.account_balance_wallet_outlined,
                          buttonLabel: 'Seleccionar',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/ventas/plan/contado-financiado', // ← CORREGIDO
                              arguments: args, // reenvía todo lo que traías
                            );
                          },
                        ),
                        const SizedBox(height: 16),

// Tarjeta: Comodato
                        _PlanCard(
                          title: 'Comodato',
                          desc:
                          'El equipo es entregado en calidad de comodato. Configura los términos y datos requeridos.',
                          icon: Icons.assignment_turned_in_outlined,
                          buttonLabel: 'Seleccionar',
                          onPressed: () {
                            Navigator.pushNamed(
                              context,
                              '/ventas/plan/comodato',
                              arguments: args,
                            );
                          },
                        ),
                        const SizedBox(height: 16),
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
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String desc;
  final IconData icon;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _PlanCard({
    required this.title,
    required this.desc,
    required this.icon,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.black87),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              desc,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 44,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onPressed,
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

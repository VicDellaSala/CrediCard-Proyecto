import 'package:flutter/material.dart';

/// Contado / Financiado
/// - Transferencia Bancaria -> '/ventas/transferencia' ✅
/// - Punto de Venta -> (placeholder por ahora)
/// - Efectivo en Tienda -> (placeholder por ahora)
class VentasContadoFinanciadoScreen extends StatelessWidget {
  const VentasContadoFinanciadoScreen({super.key, this.arguments});

  final Map<String, dynamic>? arguments;

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
// Recojo y mantengo cualquier info que venga del flujo (rif, modelo, plan, etc.)
    final args = arguments ??
        (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {});

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header con el look&feel del proyecto
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
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Contado / Financiado',
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

// Contenido desplazable y centrado
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
// TRANSFERENCIA BANCARIA -> navega a /ventas/transferencia ✅
                        _MetodoPagoCard(
                          icon: Icons.account_balance,
                          title: 'Transferencia Bancaria',
                          subtitle:
                          'Registra la referencia y el monto transferido.',
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/ventas/transferencia', // ← ruta correcta
                              arguments: args, // reenviamos todo el contexto
                            );
                          },
                        ),
                        const SizedBox(height: 16),

// PUNTO DE VENTA (placeholder por ahora)
                        _MetodoPagoCard(
                          icon: Icons.point_of_sale,
                          title: 'Punto de Venta',
                          subtitle:
                          'Cobro mediante POS en tienda o dispositivo móvil.',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Punto de Venta (próximamente)'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

// EFECTIVO EN TIENDA (placeholder por ahora)
                        _MetodoPagoCard(
                          icon: Icons.payments_outlined,
                          title: 'Efectivo en Tienda',
                          subtitle:
                          'El cliente cancelará en efectivo en el establecimiento.',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                Text('Efectivo en Tienda (próximamente)'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
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

class _MetodoPagoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MetodoPagoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.black87),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Pantalla de inicio para el rol de Usuario
/// Muestra 5 tarjetas grandes (3 arriba + 2 centradas abajo) y un botón de cerrar sesión.
class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  static const Color _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header con "Cerrar sesión"
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _HeaderAction(
                    icon: Icons.logout,
                    label: 'Cerrar sesión',
                    onTap: () => _signOut(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Panel Usuario',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
// Espaciador para balancear el IconButton izquierdo
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// Contenido scrolleable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 20,
                    runSpacing: 20,
                    children: [
                      _HomeCard(
                        icon: Icons.shopping_cart_outlined,
                        label: 'Compra de Equipos',
                        onTap: () => _goOrToast(
                          context,
                          '/user/compras/comprobante', // <- RUTA CORRECTA
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.search,
                        label: 'Consulta',
                        onTap: () => _goOrToast(
                          context,
                          '/user/consultas', // <-- cambia si tu ruta es distinta
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.bar_chart,
                        label: 'Reportes',
                        onTap: () => _goOrToast(
                          context,
                          '/user/reportes', // <-- cambia si tu ruta es distinta
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.receipt_long,
                        label: 'Deuda',
                        onTap: () => _goOrToast(
                          context,
                          '/user/deuda', // <-- cambia si tu ruta es distinta
                        ),
                      ),
                      _HomeCard(
                        icon: Icons.account_balance,
                        label: 'Banco',
                        onTap: () => _goOrToast(
                          context,
                          '/user/banco', // <-- cambia si tu ruta es distinta
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

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
// Intenta ir al login principal de tu app.
// Cambia '/login' si tu ruta de inicio es otra (por ejemplo '/').
      try {
// ignore: use_build_context_synchronously
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
      } catch (_) {
// ignore: use_build_context_synchronously
        Navigator.of(context).pushNamedAndRemoveUntil('/', (r) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar sesión: $e')),
        );
      }
    }
  }

  void _goOrToast(BuildContext context, String routeName) {
    try {
      Navigator.of(context).pushNamed(routeName);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pantalla en construcción: $routeName')),
      );
    }
  }
}

class _HeaderAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HeaderAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _HomeCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
// Tarjeta “grande” estilo panel operador
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 320, // ancho fijo para que Wrap pueda centrar la 2ª fila
          height: 180, // alto similar a tus paneles
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6E6E6)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 54, color: Colors.black87),
              const SizedBox(height: 18),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

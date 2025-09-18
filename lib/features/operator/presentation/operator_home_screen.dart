import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OperatorHomeScreen extends StatelessWidget {
  const OperatorHomeScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Seguro que quieres salir?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Salir')),
        ],
      ),
    );
    if (ok == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
      }
    }
  }

  Widget _buildMenuButton(
      {required IconData icon,
        required String label,
        required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28),
        label: Text(label, style: const TextStyle(fontSize: 18)),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
// HEADER azulito
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    child: Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _logout(context),
                          icon: const Icon(Icons.logout, color: Colors.black87),
                          label: const Text('Cerrar sesión',
                              style: TextStyle(color: Colors.black87, fontSize: 16)),
                        ),
                        const Spacer(),
                        const Text(
                          'Panel Operador',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                  blurRadius: 2,
                                  color: Colors.black26,
                                  offset: Offset(0, 1)),
                            ],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

// Banda blanca
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// CONTENIDO con botones
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildMenuButton(
                                icon: Icons.shopping_cart,
                                label: 'Ventas',
                                onPressed: () {}),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                                icon: Icons.search,
                                label: 'Consultas',
                                onPressed: () {}),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                                icon: Icons.bar_chart,
                                label: 'Reportes',
                                onPressed: () {}),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                                icon: Icons.account_balance,
                                label: 'Banco',
                                onPressed: () {}),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                                icon: Icons.inventory,
                                label: 'Almacén',
                                onPressed: () {}),
                            const SizedBox(height: 16),
                            _buildMenuButton(
                                icon: Icons.attach_money,
                                label: 'Finanzas',
                                onPressed: () {}),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

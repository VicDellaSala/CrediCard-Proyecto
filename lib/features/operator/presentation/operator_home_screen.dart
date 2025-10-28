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
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width < 700 ? 2 : 3;

    final items = <_OpItem>[
      _OpItem('Ventas', Icons.shopping_cart, '/operator/ventas'),
      _OpItem('Consultas', Icons.search, '/operator/consultas'),
      _OpItem('Reportes', Icons.bar_chart, '/operator/reportes'),
      _OpItem('Almacén', Icons.inventory, '/operator/almacen'),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
// Header azulito
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
                            shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

// Banda blanca fina
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// Panel con grilla de menús
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.builder(
                          itemCount: items.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 1.2,
                          ),
                          itemBuilder: (_, i) => _OpCard(item: items[i]),
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

class _OpItem {
  final String title;
  final IconData icon;
  final String route;
  const _OpItem(this.title, this.icon, this.route);
}

class _OpCard extends StatelessWidget {
  final _OpItem item;
  const _OpCard({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item.icon, size: 48, color: Colors.black87),
            const SizedBox(height: 12),
            Text(item.title, textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

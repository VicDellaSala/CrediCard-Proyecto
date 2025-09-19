import 'package:flutter/material.dart';

class VentasScreen extends StatelessWidget {
  const VentasScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

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
// Header azulito con flecha a la izquierda y título con ícono
                  Container(
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                    child: Row(
                      children: [
// Flecha: regresa al panel de Operador
                        TextButton.icon(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/operator'),
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          label: const Text(
                            'Volver',
                            style: TextStyle(color: Colors.black87, fontSize: 16),
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: const [
                            Icon(Icons.shopping_cart, color: Colors.white, size: 28),
                            SizedBox(width: 8),
                            Text(
                              'Ventas',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                                shadows: [Shadow(blurRadius: 2, color: Colors.black26, offset: Offset(0, 1))],
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),

// Banda blanca fina para coherencia visual
                  Container(
                    width: double.infinity,
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: const SizedBox.shrink(),
                  ),

// Panel principal (vacío por ahora)
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _panelColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(top: 8),
                      child: const Center(
                        child: Text(
                          'Pantalla de Ventas (vacía por ahora)',
                          style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
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

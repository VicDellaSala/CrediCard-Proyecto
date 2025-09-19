import 'package:flutter/material.dart';

class TrasladoAlmacenScreen extends StatelessWidget {
  const TrasladoAlmacenScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pushReplacementNamed(
                        context, '/operator/almacen/gestion'),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    label: const Text(
                      'Volver',
                      style: TextStyle(color: Colors.black87, fontSize: 16),
                    ),
                  ),
                  const Spacer(),
                  const Row(
                    children: [
                      Icon(Icons.compare_arrows,
                          color: Colors.white, size: 28),
                      SizedBox(width: 8),
                      Text(
                        'Traslado de almacén',
                        style: TextStyle(
                          fontSize: 24,
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
            Container(height: 8, color: Colors.white),

// Contenido vacío
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: _panelColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('Pantalla Traslado de almacén (vacía por ahora)'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

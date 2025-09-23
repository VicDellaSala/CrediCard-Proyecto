import 'package:flutter/material.dart';

class VentasEquiposScreen extends StatelessWidget {
  const VentasEquiposScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
                  child: Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.black87),
                        label: const Text('Volver', style: TextStyle(color: Colors.black87, fontSize: 16)),
                      ),
                      const Spacer(),
                      const Row(
                        children: [
                          Icon(Icons.inventory_2, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Modelos de equipos disponibles a la venta',
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
                Container(height: 8, color: Colors.white),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _panelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text(
                        'Aquí listaremos los equipos y características.\n(placeholder)',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


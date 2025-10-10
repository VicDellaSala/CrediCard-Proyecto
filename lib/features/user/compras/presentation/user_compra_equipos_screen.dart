import 'package:flutter/material.dart';

/// Pantalla temporal de "Compra de Equipos"
/// Recibe el RIF y muestra confirmación de que se pasó correctamente.
/// Luego podremos reemplazarla por la versión completa con listado de equipos.
class UserCompraEquiposScreen extends StatelessWidget {
  const UserCompraEquiposScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
// Recibimos argumentos de la pantalla anterior
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final String rif = args['rif']?.toString() ?? '';
    final String? clienteNombre = args['clienteNombre']?.toString();
    final String? clienteEmail = args['clienteEmail']?.toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// 🔹 Header superior
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              decoration: BoxDecoration(
                color: _panelColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    tooltip: 'Volver',
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.shopping_cart_checkout, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Compra de Equipos',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

// 🔹 Contenido principal
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.devices_other, size: 80, color: Colors.black54),
                      const SizedBox(height: 20),
                      Text(
                        'Pantalla temporal de compra de equipos',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        rif.isNotEmpty
                            ? 'RIF del cliente: $rif'
                            : 'No se recibió ningún RIF.',
                        style: const TextStyle(fontSize: 16),
                      ),
                      if (clienteNombre != null && clienteNombre.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Cliente: $clienteNombre'),
                      ],
                      if (clienteEmail != null && clienteEmail.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('Correo: $clienteEmail'),
                      ],
                      const SizedBox(height: 40),
                      ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Aquí irá la selección de modelos de equipos',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.shopping_bag),
                        label: const Text('Continuar (placeholder)'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 28),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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
}

import 'package:flutter/material.dart';

class VentasDatosFinalesScreen extends StatelessWidget {
  const VentasDatosFinalesScreen({super.key});

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    final args = (ModalRoute.of(context)?.settings.arguments as Map?) ?? const {};
    final rif = (args['rif'] ?? '').toString();
    final metodo = (args['metodo'] ?? '').toString();
    final total = (args['total'] ?? '').toString();
    final pagado = (args['montoPagado'] ?? '').toString();
    final ref = (args['referencia'] ?? '').toString();
    final banco = (args['banco'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: const Center(
                child: Text('Datos finales', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),
            Expanded(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white, borderRadius: BorderRadius.circular(12),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0,3))],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('RIF: ${rif.isEmpty ? '—' : rif}'),
                      Text('Método: ${metodo.isEmpty ? '—' : metodo}'),
                      Text('Banco: ${banco.isEmpty ? '—' : banco}'),
                      Text('Referencia: ${ref.isEmpty ? '—' : ref}'),
                      const SizedBox(height: 10),
                      Text('Total: $total', style: const TextStyle(fontWeight: FontWeight.w700)),
                      Text('Pagado: $pagado', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/operator/ventas', (r) => false),
                          icon: const Icon(Icons.home_outlined),
                          label: const Text('Volver al menú de Ventas'),
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

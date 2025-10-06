import 'package:flutter/material.dart';

class VentasRegistroSerialScreen extends StatelessWidget {
  const VentasRegistroSerialScreen({
    super.key,
    required this.rif,
    required this.lineaId,
    required this.lineaName,
    required this.planIndex,
    required this.planTitle,
    required this.planDesc,
    required this.planPrice,
    this.modeloSeleccionado,
  });

  final String rif;
  final String lineaId;
  final String lineaName;
  final int planIndex;
  final String planTitle;
  final String planDesc;
  final String planPrice;
  final String? modeloSeleccionado;

  static const _panelColor = Color(0xFFAED6D8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: _panelColor, borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  ),
                  const Spacer(),
                  const Text('Registro de serial', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white)),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 780),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _infoRow('RIF cliente', rif),
                      _infoRow('Línea', '$lineaName ($lineaId)'),
                      _infoRow('Plan', 'Plan $planIndex — ${planTitle.isEmpty ? 'Sin título' : planTitle}'),
                      if (planDesc.trim().isNotEmpty) _infoRow('Descripción plan', planDesc),
                      if (planPrice.trim().isNotEmpty) _infoRow('Precio plan', planPrice),
                      if (modeloSeleccionado != null) _infoRow('Modelo POS', modeloSeleccionado!),

                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

// Aquí luego agregamos el formulario real del serial/validación
                      const Text(
                        'Aquí agregaremos el formulario de registro de serial y la lógica de guardado.\n'
                            '(placeholder)',
                        style: TextStyle(color: Colors.black54),
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

  Widget _infoRow(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w700)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

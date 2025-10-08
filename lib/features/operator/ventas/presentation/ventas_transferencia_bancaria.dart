import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VentasTransferenciaBancariaScreen extends StatefulWidget {
  const VentasTransferenciaBancariaScreen({super.key});

  @override
  State<VentasTransferenciaBancariaScreen> createState() => _VentasTransferenciaBancariaScreenState();
}

class _VentasTransferenciaBancariaScreenState extends State<VentasTransferenciaBancariaScreen> {
  static const _panelColor = Color(0xFFAED6D8);
  static const _bg = Color(0xFFF2F2F2);

  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  late final String rif;
  late final String lineaId;
  late final String lineaName;
  late final int planIndex;
  late final String planTitle;
  late final String planDesc;
  late final String planPrice; // "4.50"
  late final String modeloSeleccionado;
  late final String posPrice; // "120.00"
  late final String total; // "124.50"

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)!.settings.arguments;
// Si entraste por ruta con arguments (desde Contado/Financiado):
    if (args is Map) {
      rif = (args['rif'] ?? '').toString();
      lineaId = (args['lineaId'] ?? '').toString();
      lineaName = (args['lineaName'] ?? '').toString();
      planIndex = int.tryParse('${args['planIndex']}') ?? 0;
      planTitle = (args['planTitle'] ?? '').toString();
      planDesc = (args['planDesc'] ?? '').toString();
      planPrice = (args['planPrice'] ?? '0').toString();
      modeloSeleccionado = (args['modeloSeleccionado'] ?? '').toString();
      posPrice = (args['posPrice'] ?? '0').toString();
      total = (args['total'] ?? '0').toString();
      if (_montoCtrl.text.isEmpty) {
        _montoCtrl.text = total; // precarga monto con el TOTAL calculado
      }
    } else {
// Si llegaste sin args, evita crashear y deja todo vacío
      rif = '';
      lineaId = '';
      lineaName = '';
      planIndex = 0;
      planTitle = '';
      planDesc = '';
      planPrice = '0';
      modeloSeleccionado = '';
      posPrice = '0';
      total = '0';
    }
  }

  @override
  void dispose() {
    _refCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
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
                  const SizedBox(width: 8),
                  const Icon(Icons.receipt_long, color: Colors.white),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Transferencia bancaria',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _infoCard(
                      title: 'Resumen de la venta',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cliente (RIF): $rif'),
                          Text('Operadora: $lineaName (id: $lineaId)'),
                          const SizedBox(height: 6),
                          const Text('Plan seleccionado:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('• $planTitle'),
                          Text(planDesc),
                          Text('Precio plan: \$${planPrice}'),
                          const SizedBox(height: 6),
                          const Text('Modelo de POS:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text('• $modeloSeleccionado'),
                          Text('Precio POS: \$$posPrice'),
                          const Divider(height: 18),
                          Text('TOTAL a transferir: \$${total}',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    _infoCard(
                      title: 'Datos de la transferencia',
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _refCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Número de referencia',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                if ((v ?? '').trim().isEmpty) return 'Ingresa la referencia';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _montoCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monto transferido (USD)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (v) {
                                final d = double.tryParse((v ?? '').replaceAll(',', '.').trim());
                                if (d == null || d <= 0) return 'Ingresa un monto válido';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _panelColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 1,
                        ),
                        onPressed: _onSubmit,
                        icon: const Icon(Icons.save),
                        label: const Text('Confirmar y guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.info_outline, color: Colors.black54),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión.')),
      );
      return;
    }

    final ref = _refCtrl.text.trim();
    final monto = double.parse(_montoCtrl.text.trim().replaceAll(',', '.'));

    try {
      await FirebaseFirestore.instance.collection('transferencias_bancarias').add({
        'rif': rif,
        'nombre': null, // si luego tienes el nombre del cliente, envíalo aquí
        'lineaId': lineaId,
        'lineaName': lineaName,
        'planIndex': planIndex,
        'planTitle': planTitle,
        'planDesc': planDesc,
        'planPrice': double.tryParse(planPrice) ?? 0.0,
        'posModelo': modeloSeleccionado,
        'posPrice': double.tryParse(posPrice) ?? 0.0,
        'total': double.tryParse(total) ?? monto,
        'referencia': ref,
        'monto': monto,
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transferencia registrada.')),
      );

// Te lleva al chequeo (placeholder)
      Navigator.pushNamed(context, '/ventas/chequeo', arguments: {
        'rif': rif,
        'lineaName': lineaName,
        'planTitle': planTitle,
        'modelo': modeloSeleccionado,
        'monto': monto,
      });
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.message ?? e.code}')),
      );
    }
  }
}

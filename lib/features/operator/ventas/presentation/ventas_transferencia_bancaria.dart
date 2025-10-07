import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VentasTransferenciaBancariaScreen extends StatefulWidget {
  const VentasTransferenciaBancariaScreen({super.key, this.arguments});

  /// Se recomienda pasar por arguments:
  /// {
  /// 'rif': String,
  /// 'clienteNombre': String?, // opcional
  /// 'lineaId': String?, // opcional, por si lo llevas en el flujo
  /// 'lineaName': String?, // opcional
  /// 'planIndex': int?, // opcional
  /// 'planTitle': String?, // opcional
  /// 'planDesc': String?, // opcional
  /// 'planPrice': String?, // opcional
  /// 'modeloSeleccionado': String?, // opcional
  /// }
  final Map<String, dynamic>? arguments;

  @override
  State<VentasTransferenciaBancariaScreen> createState() =>
      _VentasTransferenciaBancariaScreenState();
}

class _VentasTransferenciaBancariaScreenState
    extends State<VentasTransferenciaBancariaScreen> {
  static const _panelColor = Color(0xFFAED6D8);

  final _formKey = GlobalKey<FormState>();
  final _nroCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nroCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args =
        widget.arguments ?? (ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {});
    final rif = (args['rif'] ?? '').toString();
    final clienteNombre = (args['clienteNombre'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header celeste con el mismo look del proyecto
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
                  const Spacer(),
                  const Row(
                    children: [
                      Icon(Icons.account_balance, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Transferencia bancaria',
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
            Container(width: double.infinity, height: 8, color: Colors.white),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
// Resumen mínimo (opcional)
                        if (rif.isNotEmpty || clienteNombre.isNotEmpty)
                          _resumenCliente(rif: rif, nombre: clienteNombre),
                        const SizedBox(height: 12),

// Formulario
                        Material(
                          color: Colors.white,
                          elevation: 2,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Text(
                                    'Datos de la transferencia',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _nroCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Número de transferencia',
                                      hintText: 'Ej: 0123456789 / ABC123',
                                      border: OutlineInputBorder(),
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: (v) {
                                      final val = (v ?? '').trim();
                                      if (val.isEmpty) {
                                        return 'Ingresa el número de transferencia';
                                      }
// Si quieres, valida solo alfanumérico y guiones:
                                      final ok = RegExp(r'^[A-Za-z0-9\-_]{3,40}$')
                                          .hasMatch(val);
                                      if (!ok) {
                                        return 'Formato inválido (usa letras/números, 3-40)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _montoCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Monto transferido',
                                      hintText: 'Ej: 45.50',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    validator: (v) {
                                      final val = (v ?? '').trim().replaceAll(',', '.');
                                      final num? n = num.tryParse(val);
                                      if (n == null || n <= 0) {
                                        return 'Ingresa un monto válido (> 0)';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 48,
                                    child: ElevatedButton.icon(
                                      onPressed: _saving ? null : () async {
                                        await _onSubmit(context, args);
                                      },
                                      icon: _saving
                                          ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Icon(Icons.save),
                                      label: const Text('Guardar y continuar'),
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
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _resumenCliente({required String rif, required String nombre}) {
    return Material(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.person, color: Colors.black87),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (nombre.isNotEmpty)
                    Text('Cliente: $nombre',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w600)),
                  if (rif.isNotEmpty)
                    Text('RIF: $rif',
                        style: const TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSubmit(
      BuildContext context, Map<String, dynamic> args) async {
    if (!_formKey.currentState!.validate()) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesión inválida. Inicia sesión.')),
      );
      return;
    }

    final rif = (args['rif'] ?? '').toString();
    final clienteNombre = (args['clienteNombre'] ?? '').toString();

    final numero = _nroCtrl.text.trim();
    final monto = num.parse(_montoCtrl.text.trim().replaceAll(',', '.'));

    setState(() => _saving = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('transferencias_bancarias');

      final doc = await ref.add({
        'rif': rif,
        'cliente_nombre': clienteNombre,
        'numero_transferencia': numero,
        'monto': monto, // guardado como num (double)
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': uid,

// Si quieres rastrear qué se estaba comprando:
        'lineaId': args['lineaId'],
        'lineaName': args['lineaName'],
        'planIndex': args['planIndex'],
        'planTitle': args['planTitle'],
        'planDesc': args['planDesc'],
        'planPrice': args['planPrice'],
        'modeloSeleccionado': args['modeloSeleccionado'],
      });

// Navegar a ventas_chequeo con todo el contexto + id de la transferencia
      final nextArgs = Map<String, dynamic>.from(args);
      nextArgs['transferenciaId'] = doc.id;
      nextArgs['transferenciaNumero'] = numero;
      nextArgs['transferenciaMonto'] = monto;

      if (!mounted) return;
      Navigator.pushNamed(context, '/ventas/chequeo', arguments: nextArgs);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error guardando transferencia: ${e.message ?? e.code}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

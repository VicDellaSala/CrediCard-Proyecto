import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankInboxAfiliadosScreen extends StatefulWidget {
  const BankInboxAfiliadosScreen({super.key});

  @override
  State<BankInboxAfiliadosScreen> createState() => _BankInboxAfiliadosScreenState();
}

class _BankInboxAfiliadosScreenState extends State<BankInboxAfiliadosScreen> {
  static const _panel = Color(0xFFAED6D8);

  String? _userBank;
  bool _loadingBank = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserBank();
  }

  Future<void> _loadUserBank() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        setState(() {
          _error = 'Sesión inválida';
          _loadingBank = false;
        });
        return;
      }
      final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      _userBank = snap.data()?['bank'] as String?;
      if (_userBank == null || _userBank!.trim().isEmpty) {
        _error = 'Tu usuario no tiene banco asignado.';
      }
    } catch (e) {
      _error = 'Error leyendo tu banco: $e';
    } finally {
      if (mounted) setState(() => _loadingBank = false);
    }
  }

  /// Stream de solicitudes pendientes para el banco del usuario
  Stream<QuerySnapshot<Map<String, dynamic>>> _pendingRequestsStream() {
// sin orderBy para no requerir índice compuesto
    return FirebaseFirestore.instance
        .collection('bank_requests')
        .where('bank', isEqualTo: _userBank)
        .where('status', isEqualTo: 'pendiente')
        .snapshots();

  }

  Future<void> _reject(String reqId) async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('bank_requests').doc(reqId).update({
        'status': 'rechazado',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': uid,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Solicitud rechazada')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al rechazar: ${e.message ?? e.code}')),
      );
    }
  }

  Future<void> _approve({
    required String reqId,
    required String rifLower,
    required String fullName,
    required String email,
  }) async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Número de afiliación'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ingrese el número de afiliación',
          ),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Aceptar')),
        ],
      ),
    );

    if (ok != true) return;
    final affiliationNumber = controller.text.trim();
    if (affiliationNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes indicar un número de afiliación')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final write = FirebaseFirestore.instance;

    try {
// 1) Marcar bank_requests como aprobado
      await write.collection('bank_requests').doc(reqId).update({
        'status': 'aprobado',
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': uid,
        'affiliationNumber': affiliationNumber,
      });

// 2) (Opcional) Actualizar Cliente_completo con afiliación
// Para que esto funcione sin errores de permisos:
// - agrega la regla de actualización parcial indicada más abajo.
      final q = await write
          .collection('Cliente_completo')
          .where('rif_lower', isEqualTo: rifLower)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final docId = q.docs.first.id;
        await write.collection('Cliente_completo').doc(docId).update({
          'afiliado': true,
          'bank': _userBank,
          'affiliation_number': affiliationNumber,
// solo campos puntuales; no sobreescribimos demás datos
        });
      } else {
// Si no existe, puedes crear una ficha mínima (opcional).
// O dejar que el operador complete los datos en Ventas.
        await write.collection('Cliente_completo').add({
          'full_name': fullName,
          'email': email,
          'email_lower': email.toLowerCase(),
          'rif': rifLower, // si no tienes el rif original, usa rifLower
          'rif_lower': rifLower,
          'afiliado': true,
          'bank': _userBank,
          'affiliation_number': affiliationNumber,
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Afiliación aprobada y registrada')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al aprobar: ${e.message ?? e.code}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F2),
      body: SafeArea(
        child: Column(
          children: [
// Header
            Container(
              decoration: BoxDecoration(color: _panel, borderRadius: BorderRadius.circular(16)),
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
                  const Text(
                    'Buzón · Afiliados',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            if (_loadingBank)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text(_error!)))
            else if (_userBank == null)
                const Expanded(child: Center(child: Text('No hay banco asignado a este usuario')))
              else
                Expanded(
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _pendingRequestsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error cargando solicitudes: ${snapshot.error}'),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

// Ordena por fecha localmente (si requestedAt existe)
                      final docs = snapshot.data!.docs.toList()
                        ..sort((a, b) {
                          final ta = a.data()['requestedAt'];
                          final tb = b.data()['requestedAt'];
                          if (ta is Timestamp && tb is Timestamp) {
                            return tb.compareTo(ta);
                          }
                          return 0;
                        });

                      if (docs.isEmpty) {
                        return const Center(child: Text('No hay solicitudes pendientes'));
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemBuilder: (_, i) {
                          final d = docs[i];
                          final data = d.data();
                          final fullName = (data['fullName'] ?? '') as String;
                          final email = (data['email'] ?? '') as String;
                          final rif = (data['rif'] ?? '') as String;
                          final rifLower = (data['rif_lower'] ?? '') as String;
                          final createdAt = data['requestedAt'];
                          final createdStr = (createdAt is Timestamp)
                              ? createdAt.toDate().toString()
                              : '';

                          return Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ExpansionTile(
                              title: Row(
                                children: [
                                  const Icon(Icons.person, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      fullName.isEmpty ? '(Sin nombre)' : fullName,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [const Icon(Icons.badge, size: 16), const SizedBox(width: 6), Text('RIF: $rif')]),
                                    const SizedBox(height: 4),
                                    Row(children: [const Icon(Icons.email, size: 16), const SizedBox(width: 6), Text(email)]),
                                    if (createdStr.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(children: [const Icon(Icons.schedule, size: 16), const SizedBox(width: 6), Text('Solicitado: $createdStr')]),
                                    ],
                                  ],
                                ),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _reject(d.id),
                                          icon: const Icon(Icons.close),
                                          label: const Text('Rechazar'),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () => _approve(
                                            reqId: d.id,
                                            rifLower: (rifLower.isEmpty ? rif : rifLower).toString().toLowerCase(),
                                            fullName: fullName,
                                            email: email,
                                          ),
                                          icon: const Icon(Icons.check),
                                          label: const Text('Aprobar'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: docs.length,
                      );
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
